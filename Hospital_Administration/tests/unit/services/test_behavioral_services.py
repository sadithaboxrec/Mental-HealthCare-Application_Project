
from datetime import datetime, timezone
import importlib

from tests.unit.services.test_analysis_services import FakeScorer, _patch_scorer

def test_activity_signals_detect_late_activity_inactivity_and_typing(monkeypatch):
    service = importlib.import_module("services.activity_analysis_service")
    _patch_scorer(monkeypatch, service)
    monkeypatch.setattr(service, "now_utc", lambda: datetime(2026, 4, 27, tzinfo=timezone.utc))
    late_items = [
        {"createdAt": "2026-04-24T02:00:00Z"},
        {"timestamp": "2026-04-25T03:00:00Z"},
        {"updatedAt": "2026-04-26T04:00:00Z"},
    ]
    typing_logs = [
        {"eventType": "typing_cadence", "timestamp": "2026-04-26T10:00:00Z", "metrics": {"averageIkiMs": 150, "varianceIki": 1300}},
        {"eventType": "typing_cadence", "timestamp": "2026-04-26T11:00:00Z", "metrics": {"averageIkiMs": 160, "varianceIki": 1400}},
    ]

    signals = service.analyze_activity_signals(late_items, [], [], [], typing_logs)

    themes = {signal["themes"][0] for signal in signals}
    assert {"circadian_disruption", "psychomotor_agitation"} <= themes

    inactive = service.analyze_activity_signals([], [], [], [], [], patient_created_at="2026-04-01T00:00:00Z")
    assert inactive[0]["themes"] == ["inactivity"]

def test_medication_adherence_signals_cover_missed_and_late(monkeypatch):
    service = importlib.import_module("services.medication_adherence_service")
    _patch_scorer(monkeypatch, service)

    missed = service.analyze_medication_adherence_events([
        {"status": "missed", "reportedAt": "2026-04-25"},
        {"status": "not_taken", "reportedAt": "2026-04-26"},
    ])
    late = service.analyze_medication_adherence_events([
        {"status": "late", "reportedAt": "2026-04-24"},
        {"status": "late", "reportedAt": "2026-04-25"},
        {"status": "late", "reportedAt": "2026-04-26"},
    ])

    assert missed[0]["themes"] == ["dose_adherence_missed"]
    assert late[0]["themes"] == ["dose_adherence_late"]

def test_mobility_signals_detect_drop_and_home_stay(monkeypatch):
    service = importlib.import_module("services.mobility_analysis_service")
    _patch_scorer(monkeypatch, service)

    signals = service.analyze_mobility_signals([
        {"timestamp": "2026-04-24", "mobilityRadius": 10, "latitude": 1, "longitude": 2},
        {"timestamp": "2026-04-25", "mobilityRadius": 10},
        {"timestamp": "2026-04-26", "mobilityRadius": 3, "homeStayRatio": 0.95},
    ])

    assert [signal["themes"][0] for signal in signals] == ["mobility_drop", "high_home_stay"]

def test_fetch_behavioral_collections_use_shared_firestore(fake_db):
    activity = importlib.import_module("services.activity_analysis_service")
    medication = importlib.import_module("services.medication_adherence_service")
    mobility = importlib.import_module("services.mobility_analysis_service")
    xai_utils = importlib.import_module("services.xai_utils")
    xai_utils.db = fake_db

    fake_db.collection("app_activity_logs").document("act").set({
        "patientUid": "p1",
        "timestamp": "2026-04-26T10:00:00Z",
    })
    fake_db.collection("medication_adherence_events").document("med").set({
        "patientUid": "p1",
        "reportedAt": "2026-04-26T10:00:00Z",
    })
    fake_db.collection("geolocations").document("geo").set({
        "patientUid": "p1",
        "timestamp": "2026-04-26T10:00:00Z",
    })
    start = datetime(2026, 4, 25, tzinfo=timezone.utc)
    end = datetime(2026, 4, 27, tzinfo=timezone.utc)

    assert activity.fetch_app_activity_logs("p1", start, end)[0]["id"] == "act"
    assert medication.fetch_medication_adherence_events("p1", start, end)[0]["id"] == "med"
    assert mobility.fetch_geolocations("p1", start, end)[0]["id"] == "geo"

def test_chat_fetch_and_analysis(fake_db, monkeypatch):
    service = importlib.import_module("services.chat_analysis_service")
    service.db = fake_db
    monkeypatch.setattr(service, "get_default_scorer", lambda: FakeScorer())
    fake_db.collection("chat_sessions").document("s1").set({
        "patientUid": "p1",
        "status": "open",
    })
    fake_db.collection("chat_sessions/s1/messages").document("m1").set({
        "senderRole": "patient",
        "senderUid": "p1",
        "text": "I feel low",
        "timestamp": "2026-04-26T10:00:00Z",
    })
    fake_db.collection("chat_sessions/s1/messages").document("m2").set({
        "senderRole": "doctor",
        "text": "How are you?",
        "timestamp": "2026-04-26T11:00:00Z",
    })
    start = datetime(2026, 4, 25, tzinfo=timezone.utc)
    end = datetime(2026, 4, 27, tzinfo=timezone.utc)

    messages, analyzed = service.analyze_patient_chat("p1", start, end)

    assert len(messages) == 1
    assert messages[0]["id"] == "m1"
    assert analyzed[0]["source"] == "chat"
    assert analyzed[0]["sourceId"] == "s1/m1"
