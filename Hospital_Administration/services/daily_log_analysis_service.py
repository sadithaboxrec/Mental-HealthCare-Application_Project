from services.xai_scoring_service import get_default_scorer
from services.xai_utils import collection_docs, is_in_window, safe_float, safe_int


def fetch_daily_logs(patient_uid, start, end):
    logs = collection_docs("daily_logs", patient_uid)
    logs = [log for log in logs if is_in_window(log.get("date") or log.get("updatedAt"), start, end)]
    logs.sort(key=lambda item: item.get("date", ""))
    return logs


def analyze_mood_signals(daily_logs):
    scorer = get_default_scorer()
    signals = []
    recent_logs = daily_logs[-7:]
    mood_values = [safe_int(log.get("mood")) for log in daily_logs if safe_int(log.get("mood")) > 0]
    if not mood_values:
        return signals

    latest_mood = mood_values[-1]
    avg_mood = sum(mood_values) / len(mood_values)
    timestamp = recent_logs[-1].get("updatedAt") or recent_logs[-1].get("date", "") if recent_logs else ""
    if latest_mood <= 2:
        signals.append(scorer.signal_item(
            "low_mood",
            "Low mood rating",
            scorer.get_behavioral_weight("low_mood"),
            "mood",
            timestamp=timestamp,
            snippet="Recent mood rating was in the low range.",
            why_it_matters="Low mood ratings can indicate worsening affective state when sustained or paired with other signals.",
        ))
    if len(mood_values) >= 3 and avg_mood - latest_mood >= 2:
        signals.append(scorer.signal_item(
            "mood_drop",
            "Mood drop from baseline",
            scorer.get_behavioral_weight("mood_drop"),
            "mood",
            timestamp=timestamp,
            snippet="Mood rating dropped significantly compared with the recent baseline.",
            why_it_matters="A sharp mood drop can indicate deterioration compared with the patient's recent baseline.",
        ))
    return signals


def analyze_sleep_signals(daily_logs):
    scorer = get_default_scorer()
    signals = []
    recent_logs = daily_logs[-7:]
    sleep_values = [safe_float(log.get("sleepHours")) for log in daily_logs]
    sleep_values = [value for value in sleep_values if value is not None]
    if sleep_values and (sleep_values[-1] <= 4 or (sum(sleep_values[-7:]) / max(len(sleep_values[-7:]), 1)) <= 4):
        signals.append(scorer.signal_item(
            "sleep_disruption_metric",
            "Sleep disruption metric",
            scorer.get_behavioral_weight("sleep_disruption_metric"),
            "sleep",
            timestamp=recent_logs[-1].get("updatedAt") or recent_logs[-1].get("date", "") if recent_logs else "",
            snippet="Sleep duration was repeatedly low in recent logs.",
            why_it_matters="Low sleep duration can worsen mood instability, anxiety, and functioning.",
        ))
    return signals


def analyze_medication_signals(daily_logs):
    scorer = get_default_scorer()
    recent_logs = daily_logs[-7:]
    recent_med_logs = [log for log in recent_logs if "medicationTaken" in log]
    missed = [log for log in recent_med_logs if log.get("medicationTaken") is False]
    if len(missed) < 2:
        return []
    return [scorer.signal_item(
        "medication_missed",
        "Medication missed",
        scorer.get_behavioral_weight("medication_missed"),
        "medication",
        timestamp=missed[-1].get("updatedAt") or missed[-1].get("date", ""),
        snippet=f"Medication was not marked as taken on {len(missed)} recent day(s).",
        why_it_matters="Missed medication can reduce treatment stability and should be reviewed in context.",
    )]


def analyze_daily_log_signals(daily_logs):
    return (
        analyze_mood_signals(daily_logs)
        + analyze_sleep_signals(daily_logs)
        + analyze_medication_signals(daily_logs)
    )
