
from datetime import datetime, timezone
import importlib

class FakeScorer:
    def get_behavioral_weight(self, key, default=2):
        return {
            "low_mood": 3,
            "mood_drop": 2,
            "sleep_disruption_metric": 2,
            "medication_missed": 2,
            "appointment_no_show": 3,
            "appointment_avoidance": 2,
            "guardian_inconsistency": 2,
            "guardian_low_mood_observation": 2,
        }.get(key, default)

    def signal_item(self, key, display_name, weight, source, **kwargs):
        return {
            "themes": [key],
            "score": weight,
            "source": source,
            "displayName": display_name,
            "timestamp": kwargs.get("timestamp", ""),
        }

    def analyze_text(self, text, source, source_id="", timestamp=""):
        return {
            "source": source,
            "sourceId": source_id,
            "timestamp": timestamp,
            "themes": ["matched_text"] if text else [],
            "score": 1 if text else 0,
        }

def _patch_scorer(monkeypatch, module):
    monkeypatch.setattr(module, "get_default_scorer", lambda: FakeScorer())

def test_daily_log_signal_detectors_cover_mood_sleep_and_medication(monkeypatch):
    service = importlib.import_module("services.daily_log_analysis_service")
    _patch_scorer(monkeypatch, service)
    logs = [
        {"date": "2026-04-21", "mood": 6, "sleepHours": 3, "medicationTaken": False},
        {"date": "2026-04-22", "mood": 6, "sleepHours": 4, "medicationTaken": True},
        {"date": "2026-04-23", "mood": 2, "sleepHours": 3, "medicationTaken": False},
    ]

    signals = service.analyze_daily_log_signals(logs)

    themes = {signal["themes"][0] for signal in signals}
    assert {"low_mood", "mood_drop", "sleep_disruption_metric", "medication_missed"} <= themes

def test_appointment_signal_detector_flags_no_show_and_repeated_reschedules(monkeypatch):
    service = importlib.import_module("services.appointment_analysis_service")
    _patch_scorer(monkeypatch, service)
    monkeypatch.setattr(service, "now_utc", lambda: datetime(2026, 4, 27, tzinfo=timezone.utc))
    appointments = [
        {"date": "2026-04-20", "status": "scheduled"},
        {"date": "2026-04-21", "status": "rescheduled"},
        {"date": "2026-04-22", "status": "rescheduled"},
    ]

    signals = service.analyze_appointment_signals(appointments, [])

    assert [signal["themes"][0] for signal in signals] == [
        "appointment_no_show",
        "appointment_avoidance",
    ]

def test_guardian_signal_detector_flags_mismatch_and_low_mood(monkeypatch):
    service = importlib.import_module("services.guardian_analysis_service")
    _patch_scorer(monkeypatch, service)
    patient_logs = [{"date": "2026-04-27", "medicationTaken": True}]
    guardian_logs = [{
        "date": "2026-04-27",
        "medicationTaken": False,
        "mood": 2,
    }]

    signals = service.analyze_guardian_signals(patient_logs, guardian_logs)

    assert [signal["themes"][0] for signal in signals] == [
        "guardian_inconsistency",
        "guardian_low_mood_observation",
    ]

def test_fetch_functions_filter_and_sort_firestore_docs(fake_db):
    daily = importlib.import_module("services.daily_log_analysis_service")
    appointments = importlib.import_module("services.appointment_analysis_service")
    guardian = importlib.import_module("services.guardian_analysis_service")
    xai_utils = importlib.import_module("services.xai_utils")

    for module in (daily, appointments, guardian):
        module.db = fake_db
    xai_utils.db = fake_db

    fake_db.collection("daily_logs").document("late").set({
        "patientUid": "p1",
        "date": "2026-04-26",
    })
    fake_db.collection("daily_logs").document("early").set({
        "patientUid": "p1",
        "date": "2026-04-25",
    })
    fake_db.collection("appointments").document("a1").set({
        "patientUid": "p1",
        "date": "2026-04-25",
        "time": "11:00",
    })
    fake_db.collection("reschedule_requests").document("r1").set({
        "patientUid": "p1",
        "createdAt": "2026-04-25T09:00:00Z",
    })
    fake_db.collection("guardian_logs").document("g1").set({
        "patientUid": "p1",
        "date": "2026-04-25",
    })
    start = datetime(2026, 4, 24, tzinfo=timezone.utc)
    end = datetime(2026, 4, 26, 23, 59, tzinfo=timezone.utc)

    assert [log["date"] for log in daily.fetch_daily_logs("p1", start, end)] == [
        "2026-04-25",
        "2026-04-26",
    ]
    assert appointments.fetch_appointments("p1", start, end)[0]["id"] == "a1"
    assert appointments.fetch_reschedule_requests("p1", start, end)[0]["id"] == "r1"
    assert guardian.fetch_guardian_logs("p1", start, end)[0]["id"] == "g1"

def test_guardian_observations_analyze_non_empty_text(monkeypatch):
    service = importlib.import_module("services.guardian_analysis_service")
    _patch_scorer(monkeypatch, service)
    logs = [
        {"id": "empty", "observations": ""},
        {"id": "obs1", "observations": "Patient seemed withdrawn.", "date": "2026-04-27"},
    ]

    analyzed = service.analyze_guardian_observations(logs)

    assert analyzed == [{
        "source": "guardian_observation",
        "sourceId": "obs1",
        "timestamp": "2026-04-27",
        "themes": ["matched_text"],
        "score": 1,
    }]
