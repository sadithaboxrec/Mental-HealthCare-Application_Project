from collections import Counter, defaultdict

from config import db
from services.xai_scoring_service import (
    ENGINE_VERSION,
    SCREENING_NOTE,
    get_default_scorer,
)
from services.xai_utils import (
    collection_docs,
    is_in_window,
    now_utc,
    overall_action_for,
    parse_datetime,
    severity_for_score,
    severity_rank,
)


ENTRY_LIMIT = 30


def fetch_diary_entries(patient_uid, start=None, end=None, limit=ENTRY_LIMIT):
    entries = collection_docs("diary_entries", patient_uid)
    normalized = []
    for data in entries:
        created = parse_datetime(data.get("createdAt"))
        if created:
            data["createdAt"] = created.isoformat()
        updated = parse_datetime(data.get("updatedAt"))
        if updated:
            data["updatedAt"] = updated.isoformat()
        if start and end and not is_in_window(data.get("createdAt") or data.get("updatedAt"), start, end):
            continue
        normalized.append(data)
    normalized.sort(key=lambda item: item.get("updatedAt") or item.get("createdAt", ""), reverse=True)
    return normalized[:limit] if limit else normalized


def analyze_diary_entry(entry):
    scorer = get_default_scorer()
    result = scorer.analyze_text(
        entry.get("content", "") or "",
        source="diary",
        source_id=entry.get("id", ""),
        timestamp=entry.get("createdAt", ""),
    )
    return {
        "source": "diary",
        "sourceId": entry.get("id", ""),
        "timestamp": entry.get("createdAt", ""),
        "entryId": entry.get("id", ""),
        "createdAt": entry.get("createdAt", ""),
        "textConcernScore": result["score"],
        "score": result["score"],
        "band": result["band"],
        "severity": result["severity"],
        "explicit": result["explicit"],
        "explicitSelfHarm": result["explicitSelfHarm"],
        "explicitPlanOrPreparation": result["explicitPlanOrPreparation"],
        "themes": result["themes"],
        "themeCounts": result["themeCounts"],
        "evidence": result["evidence"],
        "primaryDrivers": result["primaryDrivers"],
        "excerpt": result["evidence"][0]["excerpt"] if result["evidence"] else "",
    }


def analyze_diary_entries(entries):
    return [analyze_diary_entry(entry) for entry in entries]


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


def _build_diary_summary(patient_uid, analyzed_entries):
    generated_at = now_utc().isoformat()
    scorer = get_default_scorer()
    if not analyzed_entries:
        return {
            "patientUid": patient_uid,
            "generatedAt": generated_at,
            "entryCount": 0,
            "lastEntryAt": None,
            "severity": "stable",
            "band": 0,
            "score": 0,
            "textConcernScore": 0,
            "confidence": 0.50,
            "action": overall_action_for("stable"),
            "screeningNote": SCREENING_NOTE,
            "themeCounts": {},
            "primaryDrivers": [],
            "sourceBreakdown": {},
            "evidence": [],
            "entries": [],
            "engineVersion": ENGINE_VERSION,
            "lexiconVersion": scorer.lexicon_version,
            "analysisType": "diary_analysis_v1",
        }

    score = max(item.get("score", 0) for item in analyzed_entries)
    severity, band = severity_for_score(score)
    if any(item.get("explicitSelfHarm") for item in analyzed_entries) and severity_rank(severity) < 2:
        severity, band = "warning", 2
        score = max(score, 5)
    if any(item.get("explicitPlanOrPreparation") for item in analyzed_entries):
        severity, band = "critical", 3
        score = max(score, 8)

    primary_drivers = []
    evidence = []
    for item in analyzed_entries:
        primary_drivers.extend(item.get("primaryDrivers", []))
        evidence.extend(item.get("evidence", []))
    primary_drivers.sort(
        key=lambda item: (item.get("scoreContribution", 0), item.get("weight", 0), item.get("matchCount", 0)),
        reverse=True,
    )

    evidence = evidence[: scorer.privacy.get("maxEvidenceItems", 20)]
    last_entry_at = analyzed_entries[0]["createdAt"] if analyzed_entries else None
    confidence = min(0.90, round(0.50 + min(len(analyzed_entries), 5) * 0.08, 2))

    return {
        "patientUid": patient_uid,
        "generatedAt": generated_at,
        "entryCount": len(analyzed_entries),
        "lastEntryAt": last_entry_at,
        "severity": severity,
        "band": band,
        "score": score,
        "textConcernScore": score,
        "confidence": confidence,
        "action": overall_action_for(severity),
        "screeningNote": SCREENING_NOTE,
        "themeCounts": _merge_theme_counts(analyzed_entries),
        "primaryDrivers": primary_drivers[:10],
        "sourceBreakdown": _source_breakdown(analyzed_entries),
        "evidence": evidence,
        "entries": analyzed_entries,
        "engineVersion": ENGINE_VERSION,
        "lexiconVersion": scorer.lexicon_version,
        "analysisType": "diary_analysis_v1",
    }


def _persist_diary_snapshot(summary):
    db.collection("diary_analysis_snapshots").document(summary["patientUid"]).set(summary)


def analyze_patient_diary(patient_uid, persist=False, notify=False):
    entries = fetch_diary_entries(patient_uid)
    analyzed_entries = analyze_diary_entries(entries)
    summary = _build_diary_summary(patient_uid, analyzed_entries)
    summary["clinicalAlertId"] = None
    summary["doctorNotificationId"] = None
    if persist:
        _persist_diary_snapshot(summary)
    return summary


def analyze_all_patient_diaries(persist=False, notify=False):
    patient_docs = db.collection("patients").stream()
    summaries = []

    for doc in patient_docs:
        patient = doc.to_dict()
        patient_uid = patient.get("uid", doc.id)
        if not patient_uid:
            continue

        summary = analyze_patient_diary(
            patient_uid,
            persist=persist,
            notify=notify,
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
