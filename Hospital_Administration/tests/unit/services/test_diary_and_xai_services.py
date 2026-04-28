
from datetime import datetime, timezone
import importlib
import json

from tests.unit.services.test_analysis_services import FakeScorer

class RichFakeScorer(FakeScorer):
    lexicon_version = "test-v1"
    privacy = {"maxEvidenceItems": 2}

    def analyze_text(self, text, source, source_id="", timestamp=""):
        score = 8 if "plan" in text else 3 if text else 0
        severity = "critical" if score >= 8 else "watch" if score else "stable"
        return {
            "source": source,
            "sourceId": source_id,
            "timestamp": timestamp,
            "score": score,
            "band": 3 if score >= 8 else 1 if score else 0,
            "severity": severity,
            "explicit": score >= 8,
            "explicitSelfHarm": False,
            "explicitPlanOrPreparation": score >= 8,
            "themes": ["risk"] if score else [],
            "themeCounts": {"risk": 1} if score else {},
            "evidence": [{
                "source": source,
                "excerpt": "Privacy-gated signal.",
                "theme": "risk",
            }] if score else [],
            "primaryDrivers": [{
                "theme": "risk",
                "scoreContribution": score,
                "weight": score,
                "matchCount": 1,
            }] if score else [],
        }

def test_diary_entry_and_summary_paths(fake_db, monkeypatch):
    service = importlib.import_module("services.diary_analysis_service")
    service.db = fake_db
    xai_utils = importlib.import_module("services.xai_utils")
    xai_utils.db = fake_db
    monkeypatch.setattr(service, "get_default_scorer", lambda: RichFakeScorer())
    monkeypatch.setattr(service, "now_utc", lambda: datetime(2026, 4, 27, tzinfo=timezone.utc))
    fake_db.collection("diary_entries").document("e1").set({
        "patientUid": "p1",
        "content": "I have a plan",
        "createdAt": "2026-04-26T10:00:00Z",
        "updatedAt": "2026-04-26T11:00:00Z",
    })

    entries = service.fetch_diary_entries("p1", limit=None)
    analyzed = service.analyze_diary_entries(entries)
    summary = service.analyze_patient_diary("p1", persist=True)

    assert entries[0]["id"] == "e1"
    assert analyzed[0]["severity"] == "critical"
    assert summary["severity"] == "critical"
    assert summary["score"] == 8
    assert summary["clinicalAlertId"] is None
    assert fake_db.collection("diary_analysis_snapshots").document("p1").get().exists

def test_all_patient_diaries_are_sorted_by_severity(fake_db, monkeypatch):
    service = importlib.import_module("services.diary_analysis_service")
    service.db = fake_db
    fake_db.collection("patients").document("p1").set({"uid": "p1", "name": "One"})
    fake_db.collection("patients").document("p2").set({"uid": "p2", "name": "Two"})

    def fake_analyze(uid, **kwargs):
        return {
            "patientUid": uid,
            "severity": "critical" if uid == "p2" else "stable",
            "score": 8 if uid == "p2" else 0,
            "lastEntryAt": "2026-04-27" if uid == "p2" else None,
        }

    monkeypatch.setattr(service, "analyze_patient_diary", fake_analyze)

    summaries = service.analyze_all_patient_diaries()

    assert [summary["patientUid"] for summary in summaries] == ["p2", "p1"]
    assert summaries[0]["patientName"] == "Two"

def test_xai_summary_persist_and_alert_creation(fake_db, monkeypatch):
    service = importlib.import_module("services.xai_analysis_service")
    service.db = fake_db
    monkeypatch.setattr(service, "get_default_scorer", lambda: RichFakeScorer())
    monkeypatch.setattr(service, "now_utc", lambda: datetime(2026, 4, 27, tzinfo=timezone.utc))
    fake_db.collection("patients").document("p1").set({
        "uid": "p1",
        "createdAt": "2026-04-01T00:00:00Z",
    })
    monkeypatch.setattr(service, "fetch_diary_entries", lambda *args, **kwargs: [{"id": "e1", "createdAt": "2026-04-26"}])
    monkeypatch.setattr(service, "fetch_daily_logs", lambda *args, **kwargs: [{"date": "2026-04-26"}])
    monkeypatch.setattr(service, "fetch_guardian_logs", lambda *args, **kwargs: [])
    monkeypatch.setattr(service, "fetch_appointments", lambda *args, **kwargs: [])
    monkeypatch.setattr(service, "fetch_reschedule_requests", lambda *args, **kwargs: [])
    monkeypatch.setattr(service, "fetch_geolocations", lambda *args, **kwargs: [])
    monkeypatch.setattr(service, "fetch_app_activity_logs", lambda *args, **kwargs: [])
    monkeypatch.setattr(service, "fetch_medication_adherence_events", lambda *args, **kwargs: [])
    monkeypatch.setattr(service, "fetch_patient_chat_messages", lambda *args, **kwargs: [])
    monkeypatch.setattr(service, "analyze_diary_entries", lambda entries: [{
        "source": "diary",
        "createdAt": "2026-04-26",
        "timestamp": "2026-04-26",
        "score": 8,
        "severity": "critical",
        "themeCounts": {"risk": 1},
        "evidence": [{"theme": "risk"}],
        "primaryDrivers": [{"theme": "risk", "scoreContribution": 8}],
        "explicitPlanOrPreparation": True,
    }])
    monkeypatch.setattr(service, "analyze_chat_messages", lambda messages: [])
    monkeypatch.setattr(service, "analyze_guardian_observations", lambda logs: [])
    monkeypatch.setattr(service, "analyze_daily_log_signals", lambda logs: [])
    monkeypatch.setattr(service, "analyze_medication_adherence_events", lambda events: [])
    monkeypatch.setattr(service, "analyze_guardian_signals", lambda daily, guardian: [])
    monkeypatch.setattr(service, "analyze_appointment_signals", lambda appointments, reschedules: [])
    monkeypatch.setattr(service, "analyze_activity_signals", lambda *args, **kwargs: [])
    monkeypatch.setattr(service, "analyze_mobility_signals", lambda geolocations: [])

    summary = service.analyze_patient_xai("p1", persist=True)

    assert summary["severity"] == "critical"
    assert summary["clinicalAlertId"] == "auto_1"
    assert fake_db.collection("analytics_snapshots").document("p1").get().exists
    assert fake_db.collection("clinical_alerts").added[0]["requiresAcknowledgement"] is True

def test_xai_all_patient_sorting(fake_db, monkeypatch):
    service = importlib.import_module("services.xai_analysis_service")
    service.db = fake_db
    fake_db.collection("patients").document("p1").set({"uid": "p1", "name": "Stable"})
    fake_db.collection("patients").document("p2").set({"uid": "p2", "name": "Critical"})
    monkeypatch.setattr(service, "analyze_patient_xai", lambda uid, **kwargs: {
        "patientUid": uid,
        "severity": "critical" if uid == "p2" else "stable",
        "score": 8 if uid == "p2" else 0,
        "lastEntryAt": "2026-04-27" if uid == "p2" else None,
    })

    summaries = service.analyze_all_patient_xai()

    assert [summary["patientUid"] for summary in summaries] == ["p2", "p1"]

def test_xai_lexicon_scorer_with_custom_lexicon(tmp_path):
    scorer_module = importlib.import_module("services.xai_scoring_service")
    lexicon_path = tmp_path / "lexicon.json"
    lexicon_path.write_text(json.dumps({
        "schemaVersion": "test",
        "scoring": {
            "privacy": {"maxEvidenceItems": 5},
            "criticalOverrideCategories": ["plan"],
            "warningOverrideCategories": ["harm"],
        },
        "severityBands": [
            {"key": "stable", "band": 0, "minScore": 0, "maxScore": 1},
            {"key": "watch", "band": 1, "minScore": 2, "maxScore": 4},
            {"key": "warning", "band": 2, "minScore": 5, "maxScore": 7},
            {"key": "critical", "band": 3, "minScore": 8},
        ],
        "nonLexiconSignals": [{"key": "low_mood", "weight": 4}],
        "categories": [{
            "key": "plan",
            "displayName": "Plan",
            "weight": 2,
            "terms": ["plan"],
            "explicit": True,
            "whyItMatters": "Risk.",
            "privacySnippetTemplate": "Risk term detected.",
        }],
    }), encoding="utf-8")

    scorer = scorer_module.XaiLexiconScorer(lexicon_path)
    result = scorer.analyze_text("plan plan", source="diary", source_id="e1")

    assert scorer.get_behavioral_weight("low_mood") == 4
    assert result["severity"] == "critical"
    assert result["score"] == 4
    assert result["themeCounts"] == {"plan": 2}
    assert result["primaryDrivers"][0]["scoreContribution"] == 4
