from services.xai_scoring_service import get_default_scorer
from services.xai_utils import collection_docs, is_in_window


def fetch_medication_adherence_events(patient_uid, start, end):
    events = collection_docs("medication_adherence_events", patient_uid)
    events = [event for event in events if is_in_window(event.get("reportedAt") or event.get("scheduledAt"), start, end)]
    events.sort(key=lambda item: item.get("reportedAt") or item.get("scheduledAt", ""))
    return events


def analyze_medication_adherence_events(events):
    scorer = get_default_scorer()
    recent = events[-14:]
    missed = [
        event for event in recent
        if str(event.get("status", "")).lower() in {"missed", "skipped", "not_taken"}
    ]
    late = [
        event for event in recent
        if str(event.get("status", "")).lower() == "late"
    ]
    signals = []
    if len(missed) >= 2:
        signals.append(scorer.signal_item(
            "dose_adherence_missed",
            "Dose-level medication misses",
            scorer.get_behavioral_weight("dose_adherence_missed"),
            "medication_adherence",
            timestamp=missed[-1].get("reportedAt") or missed[-1].get("scheduledAt", ""),
            snippet=f"Dose-level adherence logs show {len(missed)} missed dose event(s).",
            why_it_matters="Repeated missed dose events can reduce treatment stability and should be reviewed.",
        ))
    elif len(late) >= 3:
        signals.append(scorer.signal_item(
            "dose_adherence_late",
            "Dose-level late medication pattern",
            scorer.get_behavioral_weight("dose_adherence_late"),
            "medication_adherence",
            timestamp=late[-1].get("reportedAt") or late[-1].get("scheduledAt", ""),
            snippet=f"Dose-level adherence logs show {len(late)} late dose event(s).",
            why_it_matters="Repeated late doses can indicate adherence difficulty or routine disruption.",
        ))
    return signals
