
import sys
import types
from pathlib import Path

import pytest

BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

class FakeDocumentSnapshot:
    def __init__(self, doc_id, data=None):
        self.id = doc_id
        self._data = data
        self.exists = data is not None

    def to_dict(self):
        return dict(self._data or {})


class FakeDocumentReference:
    def __init__(self, collection, doc_id):
        self._collection = collection
        self.id = doc_id

    def get(self):
        return FakeDocumentSnapshot(self.id, self._collection._docs.get(self.id))

    def set(self, data):
        self._collection._docs[self.id] = dict(data)

    def update(self, data):
        existing = self._collection._docs.setdefault(self.id, {})
        existing.update(data)

    def delete(self):
        self._collection._docs.pop(self.id, None)

    def collection(self, name):
        key = f"{self._collection.name}/{self.id}/{name}"
        return self._collection._db.collection(key)


class FakeQuery:
    def __init__(self, collection, filters=None):
        self._collection = collection
        self._filters = filters or []

    def where(self, field, operator, value):
        return FakeQuery(self._collection, [*self._filters, (field, operator, value)])

    def limit(self, count):
        query = FakeQuery(self._collection, self._filters)
        query._limit = count
        return query

    def stream(self):
        docs = []
        for doc_id, data in self._collection._docs.items():
            if all(self._matches(data, f, op, value) for f, op, value in self._filters):
                docs.append(FakeDocumentSnapshot(doc_id, data))
        limit = getattr(self, "_limit", None)
        return docs[:limit] if limit is not None else docs

    @staticmethod
    def _matches(data, field, operator, value):
        current = data.get(field)
        if operator == "==":
            return current == value
        if operator == "in":
            return current in value
        if operator == ">=":
            return current >= value
        raise NotImplementedError(f"Unsupported fake query operator: {operator}")

class FakeCollection:
    def __init__(self, name, docs=None, db=None):
        self.name = name
        self._db = db
        self._docs = dict(docs or {})
        self.added = []

    def document(self, doc_id):
        return FakeDocumentReference(self, doc_id)

    def where(self, field, operator, value):
        return FakeQuery(self).where(field, operator, value)

    def stream(self):
        return [FakeDocumentSnapshot(doc_id, data) for doc_id, data in self._docs.items()]

    def add(self, data):
        doc_id = f"auto_{len(self.added) + 1}"
        self._docs[doc_id] = dict(data)
        self.added.append(dict(data))
        return None, FakeDocumentReference(self, doc_id)

class FakeDb:
    def __init__(self, seed=None):
        self._collections = {}
        for name, docs in (seed or {}).items():
            self._collections[name] = FakeCollection(name, docs, db=self)

    def collection(self, name):
        if name not in self._collections:
            self._collections[name] = FakeCollection(name, db=self)
        return self._collections[name]

DEFAULT_DB = FakeDb()
config_module = types.ModuleType("config")
config_module.db = DEFAULT_DB
sys.modules["config"] = config_module

@pytest.fixture
def fake_db(monkeypatch):
    db = FakeDb()
    sys.modules["config"].db = db
    return db

@pytest.fixture(autouse=True)
def fake_firebase_modules(monkeypatch, fake_db):
    firebase_admin = types.ModuleType("firebase_admin")
    messaging = types.ModuleType("firebase_admin.messaging")
    auth = types.ModuleType("firebase_admin.auth")

    class Message:
        def __init__(self, **kwargs):
            self.kwargs = kwargs

    class Notification:
        def __init__(self, **kwargs):
            self.kwargs = kwargs

    class AndroidConfig:
        def __init__(self, **kwargs):
            self.kwargs = kwargs

    class AndroidNotification:
        def __init__(self, **kwargs):
            self.kwargs = kwargs

    messaging.Message = Message
    messaging.Notification = Notification
    messaging.AndroidConfig = AndroidConfig
    messaging.AndroidNotification = AndroidNotification
    messaging.send = lambda message: "fake-message-id"

    auth.set_custom_user_claims = lambda *args, **kwargs: None
    auth.get_user = lambda uid: types.SimpleNamespace(custom_claims={})
    auth.update_user = lambda *args, **kwargs: None
    auth.delete_user = lambda *args, **kwargs: None

    firebase_admin.messaging = messaging
    firebase_admin.auth = auth

    monkeypatch.setitem(sys.modules, "firebase_admin", firebase_admin)
    monkeypatch.setitem(sys.modules, "firebase_admin.messaging", messaging)
    monkeypatch.setitem(sys.modules, "firebase_admin.auth", auth)
    yield fake_db
