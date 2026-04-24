from collections import Counter
from datetime import datetime, timedelta, timezone

from config import db


THEME_PHRASES = {
    "hopelessness": [
        "hopeless",
        "no hope",
        "nothing will get better",
        "it will never get better",
        "no point",
        "what is the point",
    ],
    "burden": [
        "burden",
        "better off without me",
        "people would be better without me",
        "i am worthless",
        "worthless",
        "useless",
    ],
    "withdrawal": [
        "alone",
        "isolated",
        "nobody understands",
        "no one cares",
        "want to disappear",
        "stay away from everyone",
    ],
    "distress": [
        "overwhelmed",
        "can't cope",
        "falling apart",
        "anxious",
        "panic",
        "scared",
        "tired of this",
    ],
    "worsening": [
        "getting worse",
        "worse every day",
        "again and again",
        "still the same",
        "nothing changed",
        "worse than before",
    ],
    "self_harm": [
        "hurt myself",
        "self harm",
        "cut myself",
        "want to die",
        "kill myself",
        "end my life",
        "suicide",
    ],
    "plan_preparation": [
        "i have a plan",
        "planned it",
        "prepared for it",
        "goodbye",
        "farewell",
        "final note",
        "last message",
    ],
}

ENTRY_LIMIT = 30


def _now():
    return datetime.now(timezone.utc)


def _parse_datetime(raw):
    if raw is None:
        return None
    if isinstance(raw, datetime):
        if raw.tzinfo is None:
            return raw.replace(tzinfo=timezone.utc)
        return raw.astimezone(timezone.utc)
    try:
        parsed = datetime.fromisoformat(str(raw).replace("Z", "+00:00"))
        if parsed.tzinfo is None:
            return parsed.replace(tzinfo=timezone.utc)
        return parsed.astimezone(timezone.utc)
    except Exception:
        return None


def _fetch_diary_entries(patient_uid, limit=ENTRY_LIMIT):
    snap = db.collection("diary_entries").where("patientUid", "==", patient_uid).stream()

    entries = []
    for doc in snap:
        data = doc.to_dict()
        data["id"] = doc.id
        created = _parse_datetime(data.get("createdAt"))
        if created:
            data["createdAt"] = created.isoformat()
        updated = _parse_datetime(data.get("updatedAt"))
        if updated:
            data["updatedAt"] = updated.isoformat()
        entries.append(data)
    entries.sort(key=lambda item: item.get("updatedAt") or item.get("createdAt", ""), reverse=True)
    return entries[:limit]


def _count_occurrences(text, phrase):
    return text.count(phrase)


def _excerpt(text, length=180):
    clean = " ".join(text.split())
    if len(clean) <= length:
        return clean
    return f"{clean[:length].rstrip()}..."


def analyze_diary_entry(entry):
    raw_text = entry.get("content", "") or ""
    text = raw_text.lower()

    themes = []
    counts = {}
    score = 0

    for theme, phrases in THEME_PHRASES.items():
        matches = []
        for phrase in phrases:
            if phrase in text:
                match_count = _count_occurrences(text, phrase)
                matches.extend([phrase] * match_count)
        if matches:
            counts[theme] = len(matches)
            themes.append(theme)

    score += counts.get("distress", 0)
    score += counts.get("worsening", 0)
    score += counts.get("withdrawal", 0)
    score += counts.get("hopelessness", 0) * 2
    score += counts.get("burden", 0) * 2
    score += counts.get("self_harm", 0) * 5
    score += counts.get("plan_preparation", 0) * 6

    explicit_self_harm = counts.get("self_harm", 0) > 0
    explicit_plan = counts.get("plan_preparation", 0) > 0
    explicit = explicit_self_harm or explicit_plan

    if explicit_plan or score >= 8:
        severity = "critical"
    elif explicit_self_harm or score >= 5:
        severity = "warning"
    elif score >= 2:
        severity = "watch"
    else:
        severity = "stable"

    evidence = []
    for theme in themes:
        evidence.append({
            "theme": theme,
            "matchCount": counts[theme],
            "explicit": theme in {"self_harm", "plan_preparation"},
            "whyItMatters": _theme_rationale(theme),
        })

    return {
        "entryId": entry.get("id", ""),
        "createdAt": entry.get("createdAt", ""),
        "excerpt": _excerpt(raw_text),
        "textConcernScore": score,
        "severity": severity,
        "explicit": explicit,
        "explicitSelfHarm": explicit_self_harm,
        "explicitPlanOrPreparation": explicit_plan,
        "themes": themes,
        "evidence": evidence,
    }


def _theme_rationale(theme):
    rationales = {
        "hopelessness": "Hopeless language can indicate worsening depressive risk and needs follow-up.",
        "burden": "Burden or worthlessness language can increase concern and requires review.",
        "withdrawal": "Withdrawal and isolation language can indicate deteriorating engagement and support needs.",
        "distress": "High distress language suggests current emotional strain and should be tracked.",
        "worsening": "Repeated worsening language suggests decline over time rather than a one-off bad day.",
        "self_harm": "Direct self-harm or suicide language requires immediate clinical review.",
        "plan_preparation": "Planning or preparation language requires immediate escalation and human review.",
    }
    return rationales.get(theme, "Relevant text concern detected.")


def _overall_action_for(severity):
    actions = {
        "stable": "Routine monitoring only.",
        "watch": "Show in dashboard and include in doctor digest.",
        "warning": "Same-day clinician review and acknowledgement required.",
        "critical": "Immediate human review and urgent clinician alert required.",
    }
    return actions[severity]


def _build_summary(patient_uid, analyzed_entries):
    if not analyzed_entries:
        return {
            "patientUid": patient_uid,
            "generatedAt": _now().isoformat(),
            "entryCount": 0,
            "lastEntryAt": None,
            "severity": "stable",
            "action": _overall_action_for("stable"),
            "screeningNote": (
                "Diary analysis is supportive evidence only and does not replace "
                "validated screening such as PHQ-9, PHQ-A, GAD-7, ASQ, or C-SSRS workflows."
            ),
            "themeCounts": {},
            "evidence": [],
            "entries": [],
        }

    severities = [entry["severity"] for entry in analyzed_entries]
    severity_rank = {"stable": 0, "watch": 1, "warning": 2, "critical": 3}

    theme_counter = Counter()
    evidence = []
    recent_warning_count = 0

    seven_days_ago = _now() - timedelta(days=7)

    for entry in analyzed_entries:
        theme_counter.update(entry["themes"])
        evidence.extend([
            {
                "source": "diary",
                "entryId": entry["entryId"],
                "timestamp": entry["createdAt"],
                "theme": item["theme"],
                "explicit": item["explicit"],
                "whyItMatters": item["whyItMatters"],
                "excerpt": entry["excerpt"],
            }
            for item in entry["evidence"]
        ])

        created = _parse_datetime(entry["createdAt"])
        if created and created >= seven_days_ago and severity_rank[entry["severity"]] >= 2:
            recent_warning_count += 1

    overall = max(severities, key=lambda value: severity_rank[value])

    if overall != "critical" and recent_warning_count >= 2:
        overall = "warning"

    if overall == "stable" and sum(theme_counter.values()) >= 2:
        overall = "watch"

    last_entry_at = analyzed_entries[0]["createdAt"]

    return {
        "patientUid": patient_uid,
        "generatedAt": _now().isoformat(),
        "entryCount": len(analyzed_entries),
        "lastEntryAt": last_entry_at,
        "severity": overall,
        "action": _overall_action_for(overall),
        "screeningNote": (
            "Diary analysis is supportive evidence only and does not replace "
            "validated screening such as PHQ-9, PHQ-A, GAD-7, ASQ, or C-SSRS workflows."
        ),
        "themeCounts": dict(theme_counter),
        "evidence": evidence[:20],
        "entries": analyzed_entries,
    }


def _patient_doc(patient_uid):
    return db.collection("patients").document(patient_uid).get()


def _doctor_uid_for(patient_uid):
    doc = _patient_doc(patient_uid)
    if not doc.exists:
        return None
    return doc.to_dict().get("assignedDoctor")


def _recent_alert_exists(patient_uid, severity):
    window_start = (_now() - timedelta(hours=12)).isoformat()
    snap = (
        db.collection("clinical_alerts")
        .where("patientUid", "==", patient_uid)
        .where("sourceType", "==", "diary_analysis")
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
        "sourceType": "diary_analysis",
        "severity": severity,
        "status": "open",
        "createdAt": _now().isoformat(),
        "generatedAt": summary["generatedAt"],
        "action": summary["action"],
        "topThemes": list(summary["themeCounts"].keys())[:5],
        "lastEntryAt": summary["lastEntryAt"],
        "requiresAcknowledgement": True,
        "evidence": summary["evidence"][:5],
    }
    ref = db.collection("clinical_alerts").add(alert)
    return ref[1].id


def _persist_snapshot(summary):
    db.collection("analytics_snapshots").document(summary["patientUid"]).set({
        "patientUid": summary["patientUid"],
        "type": "diary_analysis",
        "generatedAt": summary["generatedAt"],
        "severity": summary["severity"],
        "action": summary["action"],
        "entryCount": summary["entryCount"],
        "lastEntryAt": summary["lastEntryAt"],
        "themeCounts": summary["themeCounts"],
        "screeningNote": summary["screeningNote"],
        "entries": summary["entries"],
        "evidence": summary["evidence"],
    })


def _notify_doctor(summary):
    # Notifications are intentionally out of scope for the diary-only phase.
    # Keep the hook so the route/service contract does not need to change yet.
    return None


def analyze_patient_diary(patient_uid, persist=True, notify=False):
    entries = _fetch_diary_entries(patient_uid)
    analyzed_entries = [analyze_diary_entry(entry) for entry in entries]
    summary = _build_summary(patient_uid, analyzed_entries)

    if persist:
        _persist_snapshot(summary)

    alert_id = _create_clinical_alert(summary)
    notification_id = _notify_doctor(summary) if notify else None

    summary["clinicalAlertId"] = alert_id
    summary["doctorNotificationId"] = notification_id
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

    severity_rank = {"critical": 3, "warning": 2, "watch": 1, "stable": 0}
    summaries.sort(
        key=lambda item: (
            severity_rank.get(item.get("severity", "stable"), 0),
            item.get("lastEntryAt") or "",
        ),
        reverse=True,
    )
    return summaries
