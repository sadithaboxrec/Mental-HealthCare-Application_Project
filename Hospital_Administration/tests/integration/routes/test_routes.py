
import importlib

from flask import Flask

def create_test_app(fake_db):
    analytics_routes = importlib.import_module("routes.analytics_routes")
    notification_routes = importlib.import_module("routes.notification_routes")
    notification_routes.db = fake_db

    app = Flask(__name__)
    app.config.update(TESTING=True)
    app.register_blueprint(analytics_routes.analytics_routes)
    app.register_blueprint(notification_routes.notification_routes)
    return app, analytics_routes, notification_routes

def test_analytics_routes_return_expected_payloads(fake_db, monkeypatch):
    app, analytics, _notifications = create_test_app(fake_db)
    monkeypatch.setattr(analytics, "analyze_all_patient_diaries", lambda **kwargs: [{"patientUid": "p1"}])
    monkeypatch.setattr(analytics, "analyze_patient_diary", lambda uid, **kwargs: {"patientUid": uid})
    monkeypatch.setattr(analytics, "analyze_all_patient_xai", lambda **kwargs: [{"severity": "stable"}])
    monkeypatch.setattr(analytics, "analyze_patient_xai", lambda uid, **kwargs: {"patientUid": uid, "score": 3})

    client = app.test_client()

    assert client.get("/analytics/diary").get_json() == [{"patientUid": "p1"}]
    assert client.get("/analytics/diary/p2").get_json() == {"patientUid": "p2"}
    assert client.post("/analytics/diary/p2/recompute", json={"notify": True}).get_json() == {"patientUid": "p2"}
    assert client.get("/analytics/xai").get_json() == [{"severity": "stable"}]
    assert client.get("/analytics/xai/p3").get_json() == {"patientUid": "p3", "score": 3}
    assert client.post("/analytics/xai/p3/recompute", json={"notify": True}).get_json() == {
        "patientUid": "p3",
        "score": 3,
    }

    recompute_all = client.post("/analytics/recompute-all", json={"notify": False}).get_json()
    assert recompute_all["status"] == "done"
    assert recompute_all["xaiCount"] == 1
    assert recompute_all["diaryCount"] == 1

def test_clinical_report_api_routes(fake_db, monkeypatch):
    app, _analytics, _notifications = create_test_app(fake_db)
    report_service = importlib.import_module("services.clinical_report_service")
    report = {
        "id": "report-1",
        "patientUid": "p1",
        "patientName": "Patient One",
        "startDate": "2026-04-01",
    }
    monkeypatch.setattr(report_service, "generate_clinical_report", lambda uid, **kwargs: {**report, "patientUid": uid})
    monkeypatch.setattr(report_service, "list_patient_reports", lambda uid, limit=20: [{**report, "patientUid": uid}])
    monkeypatch.setattr(report_service, "get_report", lambda report_id: report if report_id == "report-1" else None)
    monkeypatch.setattr(report_service, "record_report_export", lambda *args, **kwargs: {"id": "export-1"})
    monkeypatch.setattr(report_service, "report_to_pdf_bytes", lambda value: b"%PDF-1.4 test")

    client = app.test_client()

    created = client.post("/api/patients/p1/clinical-report", json={"type": "weekly"}).get_json()
    assert created["patientUid"] == "p1"

    reports = client.get("/api/patients/p1/clinical-reports?limit=5").get_json()
    assert reports == [report]

    pdf_response = client.get("/api/clinical-reports/report-1/pdf")
    assert pdf_response.status_code == 200
    assert pdf_response.headers["Content-Type"] == "application/pdf"
    assert pdf_response.data.startswith(b"%PDF")

    missing = client.get("/api/clinical-reports/missing/pdf")
    assert missing.status_code == 404
    assert missing.get_json() == {"error": "Report not found"}

def test_notification_trigger_routes(fake_db, monkeypatch):
    app, _analytics, notifications = create_test_app(fake_db)
    monkeypatch.setattr(notifications, "run_medication_reminders", lambda: 2)
    monkeypatch.setattr(notifications, "run_appointment_reminders", lambda: 1)
    monkeypatch.setattr(notifications, "run_water_reminders", lambda: (3, 0))
    monkeypatch.setattr(notifications, "run_diary_reminders", lambda: (4, 1))
    monkeypatch.setattr(notifications, "_current_slot", lambda: "morning")
    monkeypatch.setattr(notifications, "_tomorrow_str", lambda: "2026-04-28")

    client = app.test_client()

    assert client.post("/trigger/medications").get_json() == {
        "status": "done",
        "slot": "morning",
        "sent": 2,
    }
    assert client.post("/trigger/appointments").get_json() == {
        "status": "done",
        "tomorrow": "2026-04-28",
        "sent": 1,
    }
    assert client.post("/trigger/water").get_json() == {"status": "done", "sent": 3, "errors": 0}
    assert client.post("/trigger/diary").get_json() == {"status": "done", "sent": 4, "errors": 1}

def test_trigger_test_notification_success_and_missing_token(fake_db, monkeypatch):
    app, _analytics, notifications = create_test_app(fake_db)
    fake_db.collection("users").document("with-token").set({
        "uid": "with-token",
        "fcmToken": "token-1",
    })
    monkeypatch.setattr(notifications, "_send_fcm", lambda *args, **kwargs: "message-1")

    client = app.test_client()

    success = client.post("/trigger/test", json={"uid": "with-token", "type": "appointment"})
    assert success.status_code == 200
    assert success.get_json() == {"status": "sent", "messageId": "message-1"}

    missing = client.post("/trigger/test", json={"uid": "missing", "type": "general"})
    assert missing.status_code == 404
    assert missing.get_json() == {"error": "No FCM token for this user"}
