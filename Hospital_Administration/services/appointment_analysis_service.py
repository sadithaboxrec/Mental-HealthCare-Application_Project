from services.xai_scoring_service import get_default_scorer
from services.xai_utils import collection_docs, is_in_window, now_utc


def fetch_appointments(patient_uid, start, end):
    appointments = collection_docs("appointments", patient_uid)
    appointments = [
        item for item in appointments
        if is_in_window(item.get("date") or item.get("createdAt"), start, end)
    ]
    appointments.sort(key=lambda item: f"{item.get('date', '')} {item.get('time', '')}")
    return appointments


def fetch_reschedule_requests(patient_uid, start, end):
    requests = collection_docs("reschedule_requests", patient_uid)
    requests = [item for item in requests if is_in_window(item.get("createdAt"), start, end)]
    requests.sort(key=lambda item: item.get("createdAt", ""))
    return requests


def analyze_appointment_signals(appointments, reschedules):
    scorer = get_default_scorer()
    signals = []
    absent = [item for item in appointments if item.get("status") == "absent"]
    rescheduled = [item for item in appointments if item.get("status") == "rescheduled"]
    today_key = now_utc().date().isoformat()
    stale_scheduled = [
        item for item in appointments
        if item.get("status") == "scheduled" and item.get("date", "") < today_key
    ]

    if absent or stale_scheduled:
        source = (absent or stale_scheduled)[-1]
        signals.append(scorer.signal_item(
            "appointment_no_show",
            "Appointment no-show or overdue scheduled visit",
            3,
            "appointments",
            timestamp=source.get("date", ""),
            snippet="Appointment attendance risk was detected.",
            why_it_matters="Missed appointments can indicate avoidance, deterioration, or loss of engagement.",
        ))
    if len(rescheduled) >= 2 or len(reschedules) >= 2:
        source = (reschedules or rescheduled)[-1]
        signals.append(scorer.signal_item(
            "appointment_avoidance",
            "Repeated appointment rescheduling",
            2,
            "appointments",
            timestamp=source.get("createdAt") or source.get("date", ""),
            snippet="Repeated appointment rescheduling was detected.",
            why_it_matters="Repeated rescheduling can indicate avoidance or barriers to treatment engagement.",
        ))
    return signals
