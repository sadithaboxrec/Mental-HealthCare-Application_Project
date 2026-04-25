from datetime import datetime, timezone

from config import db


SEVERITY_ORDER = {
    "stable": 0,
    "watch": 1,
    "warning": 2,
    "critical": 3,
}


def now_utc():
    return datetime.now(timezone.utc)


def parse_datetime(raw):
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


def date_key(raw):
    parsed = parse_datetime(raw)
    if parsed:
        return parsed.date().isoformat()
    value = str(raw or "")
    return value[:10] if len(value) >= 10 else value


def is_in_window(raw, start, end):
    parsed = parse_datetime(raw)
    if not parsed:
        key = date_key(raw)
        return not key or start.date().isoformat() <= key <= end.date().isoformat()
    return start <= parsed <= end


def severity_rank(severity):
    return SEVERITY_ORDER.get(severity, 0)


def severity_for_score(score):
    if score >= 8:
        return "critical", 3
    if score >= 5:
        return "warning", 2
    if score >= 2:
        return "watch", 1
    return "stable", 0


def overall_action_for(severity):
    actions = {
        "stable": "Routine monitoring only.",
        "watch": "Show in dashboard and include in clinician digest.",
        "warning": "Same-day clinician review and acknowledgement required.",
        "critical": "Immediate human review and urgent clinician alert required.",
    }
    return actions[severity]


def collection_docs(collection, patient_uid, patient_field="patientUid"):
    docs = []
    try:
        snap = db.collection(collection).where(patient_field, "==", patient_uid).stream()
        for doc in snap:
            data = doc.to_dict()
            data["id"] = doc.id
            docs.append(data)
    except Exception:
        return []
    return docs


def patient_doc(patient_uid):
    return db.collection("patients").document(patient_uid).get()


def safe_int(value, default=0):
    try:
        return int(value)
    except Exception:
        return default


def safe_float(value):
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return float(value)
    text = str(value).lower().strip()
    if not text:
        return None
    digits = "".join(ch if ch.isdigit() or ch == "." else " " for ch in text).split()
    if not digits:
        return None
    try:
        return float(digits[0])
    except Exception:
        return None


def latest_activity_at(*collections):
    latest = None
    for collection in collections:
        for item in collection:
            for field in ("updatedAt", "createdAt", "timestamp", "moodUpdatedAt", "date"):
                parsed = parse_datetime(item.get(field))
                if parsed and (latest is None or parsed > latest):
                    latest = parsed
    return latest
