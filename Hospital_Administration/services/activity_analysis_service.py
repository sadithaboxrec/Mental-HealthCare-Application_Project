from services.xai_scoring_service import get_default_scorer
from services.xai_utils import collection_docs, is_in_window, latest_activity_at, now_utc, parse_datetime


def fetch_app_activity_logs(patient_uid, start, end):
    logs = collection_docs("app_activity_logs", patient_uid)
    logs = [log for log in logs if is_in_window(log.get("timestamp"), start, end)]
    logs.sort(key=lambda item: item.get("timestamp", ""))
    return logs


def analyze_activity_signals(diary_entries, daily_logs, chat_messages, guardian_logs, app_activity_logs=None, patient_created_at=None):
    scorer = get_default_scorer()
    signals = []
    app_activity_logs = app_activity_logs or []
    late_events = []
    for collection in (diary_entries, chat_messages, daily_logs, app_activity_logs):
        for item in collection:
            for field in ("createdAt", "updatedAt", "timestamp", "moodUpdatedAt"):
                parsed = parse_datetime(item.get(field))
                if parsed and 1 <= parsed.hour <= 5:
                    late_events.append(parsed)
                    break
    if len(late_events) >= 3:
        signals.append(scorer.signal_item(
            "circadian_disruption",
            "Late-night activity pattern",
            2,
            "circadian",
            timestamp=max(late_events).isoformat(),
            snippet="Repeated late-night activity was detected across app interactions.",
            why_it_matters="Sustained late-night activity can indicate sleep disruption or elevated distress.",
        ))

    latest_activity = latest_activity_at(diary_entries, daily_logs, chat_messages, guardian_logs, app_activity_logs)
    created_at = parse_datetime(patient_created_at)
    if latest_activity:
        inactive_days = (now_utc() - latest_activity).days
        if inactive_days >= 7:
            signals.append(scorer.signal_item(
                "inactivity",
                "Digital inactivity",
                3,
                "inactivity",
                timestamp=latest_activity.isoformat(),
                snippet=f"No recent patient activity was detected for {inactive_days} day(s).",
                why_it_matters="A sudden absence of activity can indicate withdrawal or loss of engagement.",
            ))
    elif created_at and (now_utc() - created_at).days >= 7:
        signals.append(scorer.signal_item(
            "inactivity",
            "Digital inactivity",
            3,
            "inactivity",
            timestamp=created_at.isoformat(),
            snippet="No recent patient activity was detected after onboarding.",
            why_it_matters="A lack of activity after onboarding can indicate disengagement or setup issues.",
        ))

    return signals
