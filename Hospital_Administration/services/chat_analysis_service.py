from config import db
from services.xai_scoring_service import get_default_scorer
from services.xai_utils import is_in_window


def fetch_patient_chat_messages(patient_uid, start, end):
    messages = []
    try:
        sessions = db.collection("chat_sessions").where("patientUid", "==", patient_uid).stream()
        for session in sessions:
            session_data = session.to_dict()
            session_id = session.id
            msg_snap = (
                db.collection("chat_sessions")
                .document(session_id)
                .collection("messages")
                .stream()
            )
            for msg in msg_snap:
                data = msg.to_dict()
                timestamp = data.get("timestamp")
                if not is_in_window(timestamp, start, end):
                    continue
                sender_role = str(data.get("senderRole", "")).lower()
                sender_uid = data.get("senderUid")
                if sender_role != "patient" and sender_uid != patient_uid:
                    continue
                data["id"] = msg.id
                data["sessionId"] = session_id
                data["sessionStatus"] = session_data.get("status")
                messages.append(data)
    except Exception:
        return []
    messages.sort(key=lambda item: item.get("timestamp", ""))
    return messages


def analyze_chat_messages(messages):
    scorer = get_default_scorer()
    analyzed = []
    for message in messages:
        analyzed.append(scorer.analyze_text(
            message.get("text", "") or "",
            source="chat",
            source_id=f"{message.get('sessionId', '')}/{message.get('id', '')}",
            timestamp=message.get("timestamp", ""),
        ))
    return analyzed


def analyze_patient_chat(patient_uid, start, end):
    messages = fetch_patient_chat_messages(patient_uid, start, end)
    return messages, analyze_chat_messages(messages)
