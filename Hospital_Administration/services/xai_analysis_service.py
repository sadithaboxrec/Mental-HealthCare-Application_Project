from collections import Counter, defaultdict
from datetime import timedelta

from config import db
from services.activity_analysis_service import analyze_activity_signals, fetch_app_activity_logs
from services.appointment_analysis_service import (
    analyze_appointment_signals,
    fetch_appointments,
    fetch_reschedule_requests,
)
from services.chat_analysis_service import analyze_chat_messages, fetch_patient_chat_messages
from services.daily_log_analysis_service import analyze_daily_log_signals, fetch_daily_logs
from services.diary_analysis_service import analyze_diary_entries, fetch_diary_entries
from services.guardian_analysis_service import (
    analyze_guardian_observations,
    analyze_guardian_signals,
    fetch_guardian_logs,
)
from services.medication_adherence_service import (
    analyze_medication_adherence_events,
    fetch_medication_adherence_events,
)
from services.mobility_analysis_service import analyze_mobility_signals, fetch_geolocations
from services.xai_scoring_service import (
    ENGINE_VERSION,
    SCREENING_NOTE,
    get_default_scorer,
)
from services.xai_utils import (
    now_utc,
    overall_action_for,
    parse_datetime,
    patient_doc,
    severity_for_score,
    severity_rank,
)


ANALYSIS_WINDOW_DAYS = 30


def _merge_theme_counts(items):
    counter = Counter()
    for item in items:
        counter.update(item.get("themeCounts", {}))
    return dict(counter)


def _source_breakdown(items):
    breakdown = defaultdict(lambda: {"score": 0, "evidenceCount": 0, "driverCount": 0})
    for item in items:
        source = item.get("source", "unknown")
        breakdown[source]["score"] += item.get("score", 0)
        breakdown[source]["evidenceCount"] += len(item.get("evidence", []))
        breakdown[source]["driverCount"] += len(item.get("primaryDrivers", []))
    return dict(breakdown)


def _compute_confidence(diaries, chats, daily_logs, guardian_logs, appointments, geolocations, app_activity_logs, medication_events):
    confidence = 0.50
    if diaries:
        confidence += 0.10
    if chats:
        confidence += 0.10
    if daily_logs:
        confidence += 0.10
    if guardian_logs:
        confidence += 0.10
    if appointments:
        confidence += 0.05
    if geolocations:
        confidence += 0.05
    if app_activity_logs:
        confidence += 0.05
    if medication_events:
        confidence += 0.05
    return min(0.95, round(confidence, 2))


def _build_summary(patient_uid, analyzed_entries, chat_results, guardian_observation_results, behavioral_signals, source_docs, start=None, end=None):
    all_items = analyzed_entries + chat_results + guardian_observation_results + behavioral_signals
    generated_at = now_utc().isoformat()
    scorer = get_default_scorer()
    if not all_items:
        return {
            "patientUid": patient_uid,
            "type": "xai_analysis",
            "analysisType": "xai_analysis_v1",
            "startDate": start.date().isoformat() if start else None,
            "endDate": end.date().isoformat() if end else None,
            "generatedAt": generated_at,
            "entryCount": 0,
            "chatMessageCount": 0,
            "guardianObservationCount": 0,
            "appActivityCount": len(source_docs.get("app_activity_logs", [])),
            "medicationEventCount": len(source_docs.get("medication_events", [])),
            "behavioralSignalCount": 0,
            "lastEntryAt": None,
            "severity": "stable",
            "band": 0,
            "score": 0,
            "textConcernScore": 0,
            "confidence": _compute_confidence(**source_docs),
            "action": overall_action_for("stable"),
            "screeningNote": SCREENING_NOTE,
            "themeCounts": {},
            "primaryDrivers": [],
            "sourceBreakdown": {},
            "evidence": [],
            "entries": [],
            "engineVersion": ENGINE_VERSION,
            "lexiconVersion": scorer.lexicon_version,
        }

    text_items = analyzed_entries + chat_results + guardian_observation_results
    # Sum all text-source scores (mirrors behavioral_score logic) and cap to prevent
    # runaway inflation from many low-weight diary entries. Cap of 14 allows full
    # representation of two critical-band (score 8) entries without unbounded accumulation.
    text_score = min(sum(item.get("score", 0) for item in text_items), 14)
    behavioral_score = sum(item.get("score", 0) for item in behavioral_signals)

    recent_warning_count = 0
    seven_days_ago = now_utc() - timedelta(days=7)
    for item in all_items:
        parsed = parse_datetime(item.get("timestamp") or item.get("createdAt"))
        if parsed and parsed >= seven_days_ago and severity_rank(item.get("severity")) >= 2:
            recent_warning_count += 1

    score = max(0, text_score + behavioral_score)
    if recent_warning_count >= 2:
        score = max(score, 5)

    severity, band = severity_for_score(score)
    if any(item.get("explicitSelfHarm") for item in all_items) and severity_rank(severity) < 2:
        severity, band = "warning", 2
        score = max(score, 5)
    if any(item.get("explicitPlanOrPreparation") for item in all_items):
        severity, band = "critical", 3
        score = max(score, 8)

    primary_drivers = []
    evidence = []
    for item in all_items:
        primary_drivers.extend(item.get("primaryDrivers", []))
        evidence.extend(item.get("evidence", []))
    primary_drivers.sort(
        key=lambda item: (item.get("scoreContribution", 0), item.get("weight", 0), item.get("matchCount", 0)),
        reverse=True,
    )

    evidence = evidence[: scorer.privacy.get("maxEvidenceItems", 20)]
    last_entry_at = analyzed_entries[0]["createdAt"] if analyzed_entries else None

    return {
        "patientUid": patient_uid,
        "type": "xai_analysis",
        "analysisType": "xai_analysis_v1",
        "startDate": start.date().isoformat() if start else None,
        "endDate": end.date().isoformat() if end else None,
        "generatedAt": generated_at,
        "entryCount": len(analyzed_entries),
        "chatMessageCount": len(chat_results),
        "guardianObservationCount": len(guardian_observation_results),
        "appActivityCount": len(source_docs.get("app_activity_logs", [])),
        "medicationEventCount": len(source_docs.get("medication_events", [])),
        "behavioralSignalCount": len(behavioral_signals),
        "lastEntryAt": last_entry_at,
        "severity": severity,
        "band": band,
        "score": score,
        "textConcernScore": text_score,
        "confidence": _compute_confidence(**source_docs),
        "action": overall_action_for(severity),
        "screeningNote": SCREENING_NOTE,
        "themeCounts": _merge_theme_counts(all_items),
        "primaryDrivers": primary_drivers[:10],
        "sourceBreakdown": _source_breakdown(all_items),
        "evidence": evidence,
        "entries": analyzed_entries,
        "engineVersion": ENGINE_VERSION,
        "lexiconVersion": scorer.lexicon_version,
    }


def _recent_alert_exists(patient_uid, severity):
    window_start = (now_utc() - timedelta(hours=12)).isoformat()
    snap = (
        db.collection("clinical_alerts")
        .where("patientUid", "==", patient_uid)
        .where("sourceType", "==", "xai_analysis")
        .where("severity", "==", severity)
        .where("status", "==", "open")
        .where("createdAt", ">=", window_start)
        .limit(1)
        .stream()
    )
    return any(True for _ in snap)


def _create_clinical_alert(summary):
    severity = summary["severity"]
    patient_uid = summary["patientUid"]
    if severity not in {"warning", "critical"}:
        return None
    if _recent_alert_exists(patient_uid, severity):
        return None

    alert = {
        "patientUid": patient_uid,
        "sourceType": "xai_analysis",
        "severity": severity,
        "band": summary["band"],
        "score": summary["score"],
        "confidence": summary["confidence"],
        "status": "open",
        "createdAt": now_utc().isoformat(),
        "generatedAt": summary["generatedAt"],
        "action": summary["action"],
        "topThemes": list(summary["themeCounts"].keys())[:5],
        "primaryDrivers": summary["primaryDrivers"][:5],
        "sourceBreakdown": summary["sourceBreakdown"],
        "lastEntryAt": summary["lastEntryAt"],
        "requiresAcknowledgement": True,
        "evidence": summary["evidence"][:5],
        "engineVersion": summary["engineVersion"],
        "lexiconVersion": summary["lexiconVersion"],
    }
    ref = db.collection("clinical_alerts").add(alert)
    return ref[1].id


def _persist_snapshot(summary):
    db.collection("analytics_snapshots").document(summary["patientUid"]).set({
        "patientUid": summary["patientUid"],
        "type": "xai_analysis",
        "analysisType": "xai_analysis_v1",
        "startDate": summary.get("startDate"),
        "endDate": summary.get("endDate"),
        "generatedAt": summary["generatedAt"],
        "severity": summary["severity"],
        "band": summary["band"],
        "score": summary["score"],
        "textConcernScore": summary.get("textConcernScore", summary["score"]),
        "confidence": summary["confidence"],
        "action": summary["action"],
        "entryCount": summary["entryCount"],
        "chatMessageCount": summary.get("chatMessageCount", 0),
        "guardianObservationCount": summary.get("guardianObservationCount", 0),
        "appActivityCount": summary.get("appActivityCount", 0),
        "medicationEventCount": summary.get("medicationEventCount", 0),
        "behavioralSignalCount": summary.get("behavioralSignalCount", 0),
        "lastEntryAt": summary["lastEntryAt"],
        "themeCounts": summary["themeCounts"],
        "primaryDrivers": summary["primaryDrivers"],
        "sourceBreakdown": summary["sourceBreakdown"],
        "screeningNote": summary["screeningNote"],
        "entries": summary["entries"],
        "evidence": summary["evidence"],
        "engineVersion": summary["engineVersion"],
        "lexiconVersion": summary["lexiconVersion"],
    })


def analyze_patient_xai(patient_uid, persist=True, notify=False, start=None, end=None):
    end = end or now_utc()
    start = start or (end - timedelta(days=ANALYSIS_WINDOW_DAYS))
    patient_snapshot = patient_doc(patient_uid)
    patient = patient_snapshot.to_dict() if patient_snapshot.exists else {}

    diary_entries = fetch_diary_entries(patient_uid, start=start, end=end)
    daily_logs = fetch_daily_logs(patient_uid, start, end)
    guardian_logs = fetch_guardian_logs(patient_uid, start, end)
    appointments = fetch_appointments(patient_uid, start, end)
    reschedules = fetch_reschedule_requests(patient_uid, start, end)
    geolocations = fetch_geolocations(patient_uid, start, end)
    app_activity_logs = fetch_app_activity_logs(patient_uid, start, end)
    medication_events = fetch_medication_adherence_events(patient_uid, start, end)
    chat_messages = fetch_patient_chat_messages(patient_uid, start, end)

    analyzed_entries = analyze_diary_entries(diary_entries)
    chat_results = analyze_chat_messages(chat_messages)
    guardian_observations = analyze_guardian_observations(guardian_logs)
    behavioral_signals = (
        analyze_daily_log_signals(daily_logs)
        + analyze_medication_adherence_events(medication_events)
        + analyze_guardian_signals(daily_logs, guardian_logs)
        + analyze_appointment_signals(appointments, reschedules)
        + analyze_activity_signals(diary_entries, daily_logs, chat_messages, guardian_logs, app_activity_logs, patient.get("createdAt"))
        + analyze_mobility_signals(geolocations)
    )

    source_docs = {
        "diaries": diary_entries,
        "chats": chat_messages,
        "daily_logs": daily_logs,
        "guardian_logs": guardian_logs,
        "appointments": appointments,
        "geolocations": geolocations,
        "app_activity_logs": app_activity_logs,
        "medication_events": medication_events,
    }
    summary = _build_summary(
        patient_uid,
        analyzed_entries,
        chat_results,
        guardian_observations,
        behavioral_signals,
        source_docs,
        start=start,
        end=end,
    )

    alert_id = None
    if persist:
        _persist_snapshot(summary)
        alert_id = _create_clinical_alert(summary)
    summary["clinicalAlertId"] = alert_id
    summary["doctorNotificationId"] = None
    return summary


def analyze_all_patient_xai(persist=False, notify=False, start=None, end=None):
    patient_docs = db.collection("patients").stream()
    summaries = []

    for doc in patient_docs:
        patient = doc.to_dict()
        patient_uid = patient.get("uid", doc.id)
        if not patient_uid:
            continue

        summary = analyze_patient_xai(
            patient_uid,
            persist=persist,
            notify=notify,
            start=start,
            end=end,
        )
        summary["patientName"] = patient.get("name", "Unknown Patient")
        summary["assignedDoctor"] = patient.get("assignedDoctor")
        summaries.append(summary)

    summaries.sort(
        key=lambda item: (
            severity_rank(item.get("severity", "stable")),
            item.get("score", 0),
            item.get("lastEntryAt") or "",
        ),
        reverse=True,
    )
    return summaries
