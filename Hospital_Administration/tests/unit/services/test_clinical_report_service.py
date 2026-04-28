
from datetime import datetime, timezone
import importlib

def test_resolve_report_range_clamps_future_end_and_first_patient_day(monkeypatch):
    service = importlib.import_module("services.clinical_report_service")
    monkeypatch.setattr(service, "now_utc", lambda: datetime(2026, 4, 27, 12, tzinfo=timezone.utc))
    monkeypatch.setattr(
        service,
        "_patient_first_day",
        lambda patient_uid, patient=None: datetime(2026, 4, 20, tzinfo=timezone.utc),
    )

    report_type, start, end = service.resolve_report_range(
        "custom",
        start_date="2026-04-01",
        end_date="2026-05-01",
        patient_uid="p1",
    )

    assert report_type == "custom"
    assert start.date().isoformat() == "2026-04-20"
    assert end.date().isoformat() == "2026-04-27"

def test_generate_clinical_report_builds_summary_and_persists(fake_db, monkeypatch):
    service = importlib.import_module("services.clinical_report_service")
    service.db = fake_db
    fake_db.collection("patients").document("p1").set({
        "uid": "p1",
        "name": "Patient One",
        "assignedDoctor": "d1",
        "createdAt": "2026-04-01T00:00:00Z",
    })
    monkeypatch.setattr(service, "now_utc", lambda: datetime(2026, 4, 27, 12, tzinfo=timezone.utc))
    monkeypatch.setattr(
        service,
        "analyze_patient_xai",
        lambda *args, **kwargs: {
            "severity": "warning",
            "band": 2,
            "score": 6,
            "confidence": 0.8,
            "action": "Review",
            "screeningNote": "Clinical screening required.",
            "entryCount": 3,
            "primaryDrivers": [{"theme": "low_mood"}],
            "themeCounts": {"low_mood": 2},
            "sourceBreakdown": {"mood": 1},
            "evidence": [{"theme": "low_mood"}],
            "engineVersion": "test-engine",
            "lexiconVersion": "test-lexicon",
        },
    )
    monkeypatch.setattr(service, "fetch_daily_logs", lambda *args, **kwargs: [
        {"date": "2026-04-26", "mood": 2, "sleepHours": 4, "medicationTaken": True},
        {"date": "2026-04-27", "mood": 3, "sleepHours": 5, "medicationTaken": False},
    ])
    monkeypatch.setattr(service, "fetch_guardian_logs", lambda *args, **kwargs: [{"date": "2026-04-27"}])
    monkeypatch.setattr(service, "fetch_appointments", lambda *args, **kwargs: [{"status": "scheduled"}])
    monkeypatch.setattr(service, "fetch_reschedule_requests", lambda *args, **kwargs: [{"id": "r1"}])

    report = service.generate_clinical_report("p1", report_type="daily", persist=True)

    assert report["id"] == "auto_1"
    assert report["patientName"] == "Patient One"
    assert report["aggregatedSeverity"] == "warning"
    assert report["adherenceSummary"]["trackedDays"] == 2
    assert report["adherenceSummary"]["adherencePercent"] == 50.0
    assert fake_db.collection("clinical_reports").document("auto_1").get().exists

def test_list_get_export_and_pdf_helpers(fake_db):
    service = importlib.import_module("services.clinical_report_service")
    service.db = fake_db
    fake_db.collection("clinical_reports").document("old").set({
        "patientUid": "p1",
        "generatedAt": "2026-04-20T00:00:00Z",
        "patientName": "Patient One",
    })
    fake_db.collection("clinical_reports").document("new").set({
        "patientUid": "p1",
        "generatedAt": "2026-04-27T00:00:00Z",
        "patientName": "Patient One",
    })

    reports = service.list_patient_reports("p1", limit=1)
    export = service.record_report_export("new", "p1")
    pdf = service.report_to_pdf_bytes(service.get_report("new"))

    assert reports[0]["id"] == "new"
    assert service.get_report("missing") is None
    assert export["id"] == "auto_1"
    assert pdf.startswith(b"%PDF-1.4")
