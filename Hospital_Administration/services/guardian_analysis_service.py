from services.xai_scoring_service import get_default_scorer
from services.xai_utils import collection_docs, is_in_window, safe_int


def fetch_guardian_logs(patient_uid, start, end):
    logs = collection_docs("guardian_logs", patient_uid)
    logs = [log for log in logs if is_in_window(log.get("date") or log.get("updatedAt"), start, end)]
    logs.sort(key=lambda item: item.get("date", ""))
    return logs


def analyze_guardian_observations(logs):
    scorer = get_default_scorer()
    analyzed = []
    for log in logs:
        observations = (log.get("observations") or "").strip()
        if not observations:
            continue
        analyzed.append(scorer.analyze_text(
            observations,
            source="guardian_observation",
            source_id=log.get("id", ""),
            timestamp=log.get("updatedAt") or log.get("date", ""),
        ))
    return analyzed


def analyze_guardian_signals(daily_logs, guardian_logs):
    scorer = get_default_scorer()
    signals = []
    patient_med_by_date = {
        log.get("date"): log.get("medicationTaken")
        for log in daily_logs
        if log.get("date") and "medicationTaken" in log
    }
    mismatches = []
    for log in guardian_logs:
        date = log.get("date")
        if date in patient_med_by_date and "medicationTaken" in log:
            if patient_med_by_date[date] != log.get("medicationTaken"):
                mismatches.append(log)

    if mismatches:
        signals.append(scorer.signal_item(
            "guardian_inconsistency",
            "Guardian verification inconsistency",
            scorer.get_behavioral_weight("guardian_inconsistency"),
            "guardian_verification",
            timestamp=mismatches[-1].get("updatedAt") or mismatches[-1].get("date", ""),
            snippet="Guardian medication verification conflicts with patient self-report.",
            why_it_matters="Contradictory adherence reports reduce confidence in self-reporting and can be clinically relevant.",
        ))

    low_guardian_mood = [log for log in guardian_logs if safe_int(log.get("mood")) in (1, 2)]
    if low_guardian_mood:
        signals.append(scorer.signal_item(
            "guardian_low_mood_observation",
            "Guardian low mood observation",
            scorer.get_behavioral_weight("guardian_low_mood_observation"),
            "guardian_verification",
            timestamp=low_guardian_mood[-1].get("updatedAt") or low_guardian_mood[-1].get("date", ""),
            snippet="Guardian reported low observed mood.",
            why_it_matters="Guardian observations can add external context to patient self-reports.",
        ))

    return signals
