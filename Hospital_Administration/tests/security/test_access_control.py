import importlib
from datetime import datetime
from pathlib import Path

from flask import Flask


BACKEND_DIR = Path(__file__).resolve().parents[2]


def _create_protected_app(fake_db):
    auth_routes = importlib.import_module("routes.auth_routes")
    admin_routes = importlib.import_module("routes.admin_routes")
    doctor_portal_routes = importlib.import_module("routes.doctor_portal_routes")

    auth_routes.db = fake_db
    admin_routes.db = fake_db
    doctor_portal_routes.db = fake_db

    app = Flask(__name__, template_folder=str(BACKEND_DIR / "templates"))
    app.config.update(TESTING=True, SECRET_KEY="test-secret")

    @app.context_processor
    def inject_now():
        return {"now": datetime.now}

    auth_routes.login_manager.init_app(app)
    app.register_blueprint(auth_routes.auth_routes)
    app.register_blueprint(admin_routes.admin_routes)
    app.register_blueprint(doctor_portal_routes.doctor_portal_routes)
    return app, doctor_portal_routes


def _login_as(client, uid):
    with client.session_transaction() as session:
        session["_user_id"] = uid
        session["_fresh"] = True


def test_admin_pages_redirect_anonymous_users_to_login(fake_db):
    app, _doctor_portal = _create_protected_app(fake_db)

    response = app.test_client().get("/admin/")

    assert response.status_code == 302
    assert "/login" in response.headers["Location"]


def test_admin_only_pages_reject_doctor_sessions(fake_db):
    app, _doctor_portal = _create_protected_app(fake_db)
    fake_db.collection("users").document("doctor-1").set({
        "uid": "doctor-1",
        "name": "Dr Silva",
        "email": "doctor@example.com",
        "role": "doctor",
    })
    client = app.test_client()
    _login_as(client, "doctor-1")

    response = client.get("/admin/")

    assert response.status_code == 403


def test_doctor_patient_detail_is_scoped_to_assigned_patients(fake_db, monkeypatch):
    app, doctor_portal = _create_protected_app(fake_db)
    fake_db.collection("users").document("doctor-1").set({
        "uid": "doctor-1",
        "name": "Dr Silva",
        "email": "doctor@example.com",
        "role": "doctor",
    })
    fake_db.collection("patients").document("assigned").set({
        "uid": "assigned",
        "name": "Assigned Patient",
        "assignedDoctor": "doctor-1",
    })
    fake_db.collection("patients").document("other").set({
        "uid": "other",
        "name": "Other Patient",
        "assignedDoctor": "doctor-2",
    })
    monkeypatch.setattr(
        doctor_portal,
        "_patient_snapshot",
        lambda patient_uid: {"patientName": "Assigned Patient", "severity": "stable"},
    )
    monkeypatch.setattr(doctor_portal, "list_patient_reports", lambda patient_uid, limit=10: [])

    client = app.test_client()
    _login_as(client, "doctor-1")

    assert client.get("/portal/patients/missing").status_code == 404
    assert client.get("/portal/patients/other").status_code == 403
    assert client.get("/portal/patients/assigned").status_code == 200


def test_doctor_report_pdf_requires_existing_report(fake_db, monkeypatch):
    app, doctor_portal = _create_protected_app(fake_db)
    fake_db.collection("users").document("doctor-1").set({
        "uid": "doctor-1",
        "name": "Dr Silva",
        "email": "doctor@example.com",
        "role": "doctor",
    })
    monkeypatch.setattr(doctor_portal, "get_report", lambda report_id: None)

    client = app.test_client()
    _login_as(client, "doctor-1")

    response = client.get("/portal/reports/missing/pdf")

    assert response.status_code == 404
    assert response.get_json() == {"error": "Report not found"}
