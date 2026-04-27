from services.xai_scoring_service import get_default_scorer
from services.xai_utils import collection_docs, is_in_window, safe_float


def fetch_geolocations(patient_uid, start, end):
    locations = collection_docs("geolocations", patient_uid)
    locations = [item for item in locations if is_in_window(item.get("timestamp"), start, end)]
    locations.sort(key=lambda item: item.get("timestamp", ""))
    return locations


def analyze_mobility_signals(geolocations):
    scorer = get_default_scorer()
    signals = []
    mobility_values = [
        safe_float(item.get("mobilityRadius"))
        for item in geolocations
        if safe_float(item.get("mobilityRadius")) is not None
    ]
    if len(mobility_values) >= 3:
        latest = mobility_values[-1]
        avg = sum(mobility_values) / len(mobility_values)
        if avg > 0 and latest <= avg * 0.5:
            signals.append(scorer.signal_item(
                "mobility_drop",
                "Coarse mobility drop",
                2,
                "mobility",
                timestamp=geolocations[-1].get("timestamp", ""),
                snippet="Coarse mobility radius dropped compared with recent baseline.",
                why_it_matters="Reduced mobility can correlate with isolation or functional decline.",
            ))

    high_home_stay = [
        item for item in geolocations
        if (safe_float(item.get("homeStayRatio")) or 0) >= 0.9
    ]
    if high_home_stay:
        signals.append(scorer.signal_item(
            "high_home_stay",
            "High home-stay ratio",
            2,
            "mobility",
            timestamp=high_home_stay[-1].get("timestamp", ""),
            snippet="Coarse mobility data suggests unusually high home-stay time.",
            why_it_matters="A high home-stay ratio can support isolation concerns when combined with other signals.",
        ))
    return signals
