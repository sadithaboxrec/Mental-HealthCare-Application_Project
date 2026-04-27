from services.xai_scoring_service import get_default_scorer
from services.xai_utils import collection_docs, is_in_window, latest_activity_at, now_utc, parse_datetime, safe_float


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
            scorer.get_behavioral_weight("circadian_disruption"),
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
                scorer.get_behavioral_weight("inactivity"),
                "inactivity",
                timestamp=latest_activity.isoformat(),
                snippet=f"No recent patient activity was detected for {inactive_days} day(s).",
                why_it_matters="A sudden absence of activity can indicate withdrawal or loss of engagement.",
            ))
    elif created_at and (now_utc() - created_at).days >= 7:
        signals.append(scorer.signal_item(
            "inactivity",
            "Digital inactivity",
            scorer.get_behavioral_weight("inactivity"),
            "inactivity",
            timestamp=created_at.isoformat(),
            snippet="No recent patient activity was detected after onboarding.",
            why_it_matters="A lack of activity after onboarding can indicate disengagement or setup issues.",
        ))

    typing_logs = [log for log in app_activity_logs if log.get("eventType") == "typing_cadence"]
    if len(typing_logs) >= 2:
        typing_logs.sort(key=lambda x: x.get("timestamp", ""))
        # Aggregate metrics across all sessions in the window for trend analysis
        all_ikis = [safe_float(l.get("metrics", {}).get("averageIkiMs")) for l in typing_logs]
        all_variances = [safe_float(l.get("metrics", {}).get("varianceIki")) for l in typing_logs]
        all_backspaces = [safe_float(l.get("metrics", {}).get("backspaceRatio")) for l in typing_logs]
        valid_ikis = [v for v in all_ikis if v is not None]
        valid_variances = [v for v in all_variances if v is not None]
        valid_backspaces = [v for v in all_backspaces if v is not None]

        avg_iki = sum(valid_ikis) / len(valid_ikis) if valid_ikis else 0
        avg_variance = sum(valid_variances) / len(valid_variances) if valid_variances else 0
        avg_backspace = sum(valid_backspaces) / len(valid_backspaces) if valid_backspaces else 0
        latest_ts = typing_logs[-1].get("timestamp", "")

        if avg_variance > 1000 and avg_iki < 200:
            signals.append(scorer.signal_item(
                "psychomotor_agitation",
                "Erratic rapid typing cadence",
                scorer.get_behavioral_weight("psychomotor_agitation"),
                "psychomotor",
                timestamp=latest_ts,
                snippet=f"Sustained erratic typing trend: avg variance {int(avg_variance)}ms, avg speed {int(avg_iki)}ms across {len(typing_logs)} session(s).",
                why_it_matters="A sustained pattern of erratic, rapid typing can indicate psychomotor agitation or a manic episode."
            ))
        elif avg_iki > 400 and avg_backspace > 0.15:
            signals.append(scorer.signal_item(
                "psychomotor_retardation",
                "Slow hesitant typing cadence",
                scorer.get_behavioral_weight("psychomotor_retardation"),
                "psychomotor",
                timestamp=latest_ts,
                snippet=f"Sustained slow typing trend: avg {int(avg_iki)}ms IKI, {int(avg_backspace*100)}% deletion rate across {len(typing_logs)} session(s).",
                why_it_matters="A sustained pattern of slow, highly corrected typing suggests psychomotor retardation or cognitive fog."
            ))

    return signals
