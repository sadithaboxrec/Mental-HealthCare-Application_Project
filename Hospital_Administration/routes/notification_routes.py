from flask import Blueprint, jsonify, request
from firebase_admin import messaging
from config import db
from datetime import datetime, timedelta

notification_routes = Blueprint('notification_routes', __name__)


# ── Helpers ───────────────────────────────────────────────

def _send_fcm(token, title, body, notif_type='general'):
    try:
        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(
                    sound='alarm_sound',
                    channel_id='health_alerts',
                ),
            ),
            data={'type': notif_type},
            token=token,
        )
        response = messaging.send(message)
        return response
    except Exception as e:
        print(f'FCM error: {e}')
        return None


def _save_to_inbox(uid, title, body, notif_type):
    try:
        db.collection('notifications').add({
            'uid': uid, 'title': title, 'body': body,
            'type': notif_type, 'isRead': False,
            'createdAt': datetime.now().isoformat(),
        })
    except Exception as e:
        print(f'Inbox save error: {e}')


def _format_dose(med):
    dose = med.get('dose', '').strip()
    return f' — {dose}' if dose else ''


def _current_slot():
    hour = datetime.now().hour
    if 5  <= hour < 12: return 'morning'
    if 12 <= hour < 17: return 'afternoon'
    return 'night'


def _tomorrow_str():
    return (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d')


def _get_token(uid):
    doc = db.collection('users').document(uid).get()
    if doc.exists:
        return doc.to_dict().get('fcmToken')
    return None


# ── Core runner functions ─────────────────────────────────

def run_medication_reminders():
    slot = _current_slot()
    sent = skip = 0
    for pres in db.collection('prescriptions').where('isActive', '==', True).stream():
        data        = pres.to_dict()
        patient_uid = data.get('patientUid', '')
        patient_name= data.get('patientName', 'Patient')
        slot_meds   = [m for m in data.get('medicines', []) if m.get(slot, False)]
        if not slot_meds:
            skip += 1
            continue
        p_token = _get_token(patient_uid)
        for med in slot_meds:
            meal  = 'before meal' if med.get('beforeMeal') else 'after meal'
            dose  = _format_dose(med)
            title = '💊 Time for your medicine'
            body  = f'Take {med["name"]}{dose} {meal}.'
            if p_token and _send_fcm(p_token, title, body, 'medication'):
                sent += 1
                _save_to_inbox(patient_uid, title, body, 'medication')
            patient_doc = db.collection('patients').document(patient_uid).get()
            if patient_doc.exists:
                guardian_uid = patient_doc.to_dict().get('guardianUid')
                if guardian_uid:
                    g_token = _get_token(guardian_uid)
                    if g_token and _send_fcm(g_token, f'💊 Medication — {patient_name}',
                                             f'{patient_name} needs to take {med["name"]}{dose} {meal}.', 'medication'):
                        sent += 1
    return sent


def run_appointment_reminders():
    tomorrow = _tomorrow_str()
    sent = 0
    for apt in (db.collection('appointments')
                .where('date', '==', tomorrow)
                .where('status', 'in', ['scheduled', 'rescheduled'])
                .stream()):
        data        = apt.to_dict()
        patient_uid = data.get('patientUid', '')
        patient_name= data.get('patientName', 'Patient')
        time        = data.get('time', '')
        p_token = _get_token(patient_uid)
        if p_token:
            title = '📅 Clinic Visit Tomorrow'
            body  = f'You have an appointment tomorrow at {time} on {tomorrow}. Please prepare.'
            if _send_fcm(p_token, title, body, 'appointment'):
                sent += 1
                _save_to_inbox(patient_uid, title, body, 'appointment')
        patient_doc = db.collection('patients').document(patient_uid).get()
        if patient_doc.exists:
            guardian_uid = patient_doc.to_dict().get('guardianUid')
            if guardian_uid:
                g_token = _get_token(guardian_uid)
                if g_token and _send_fcm(g_token, f'📅 Appointment Tomorrow — {patient_name}',
                                          f'{patient_name} has a clinic visit tomorrow at {time} on {tomorrow}.', 'appointment'):
                    sent += 1
    return sent


def run_water_reminders():
    sent = errors = 0
    title = '💧 Stay Hydrated'
    body  = "Don't forget to drink water and log your intake today."
    for p in db.collection('users').where('role', '==', 'patient').stream():
        data  = p.to_dict()
        token = data.get('fcmToken')
        uid   = data.get('uid', '')
        if not token:
            continue
        if _send_fcm(token, title, body, 'general'):
            sent += 1
            _save_to_inbox(uid, title, body, 'general')
        else:
            errors += 1
    return sent, errors


def run_diary_reminders():
    sent = errors = 0
    title = '📓 Write in your diary'
    body  = 'Take a moment to record your thoughts and feelings today.'
    for p in db.collection('users').where('role', '==', 'patient').stream():
        data  = p.to_dict()
        token = data.get('fcmToken')
        uid   = data.get('uid', '')
        if not token:
            continue
        if _send_fcm(token, title, body, 'general'):
            sent += 1
            _save_to_inbox(uid, title, body, 'general')
        else:
            errors += 1
    return sent, errors


# ── Endpoints ─────────────────────────────────────────────

@notification_routes.route('/trigger/medications', methods=['POST'])
def trigger_medications():
    """
    Manually trigger medication reminders for the current time slot.
    ---
    tags: [Notifications]
    responses:
      200:
        description: Result with slot and sent count
        schema:
          type: object
          properties:
            status:
              type: string
            slot:
              type: string
            sent:
              type: integer
    """
    sent = run_medication_reminders()
    return jsonify({'status': 'done', 'slot': _current_slot(), 'sent': sent}), 200


@notification_routes.route('/trigger/appointments', methods=['POST'])
def trigger_appointments():
    """
    Manually trigger appointment reminders for tomorrow.
    ---
    tags: [Notifications]
    responses:
      200:
        description: Result with tomorrow date and sent count
        schema:
          type: object
          properties:
            status:
              type: string
            tomorrow:
              type: string
            sent:
              type: integer
    """
    sent = run_appointment_reminders()
    return jsonify({'status': 'done', 'tomorrow': _tomorrow_str(), 'sent': sent}), 200


@notification_routes.route('/trigger/water', methods=['POST'])
def trigger_water():
    """
    Manually trigger water intake reminders for all patients.
    ---
    tags: [Notifications]
    responses:
      200:
        description: Result with sent and error counts
    """
    sent, errors = run_water_reminders()
    return jsonify({'status': 'done', 'sent': sent, 'errors': errors}), 200


@notification_routes.route('/trigger/diary', methods=['POST'])
def trigger_diary():
    """
    Manually trigger diary reminders for all patients.
    ---
    tags: [Notifications]
    responses:
      200:
        description: Result with sent and error counts
    """
    sent, errors = run_diary_reminders()
    return jsonify({'status': 'done', 'sent': sent, 'errors': errors}), 200


@notification_routes.route('/trigger/test', methods=['POST'])
def trigger_test():
    """
    Send a test notification to a specific user by UID.
    ---
    tags: [Notifications]
    requestBody:
      content:
        application/json:
          schema:
            type: object
            required: [uid]
            properties:
              uid:
                type: string
                description: Firebase UID of the target user
              type:
                type: string
                enum: [medication, appointment, general]
                default: general
    responses:
      200:
        description: Notification sent successfully
      404:
        description: No FCM token found for this user
      500:
        description: Failed to send
    """
    data  = request.json or {}
    uid   = data.get('uid', '')
    ntype = data.get('type', 'general')
    token = _get_token(uid)
    if not token:
        return jsonify({'error': 'No FCM token for this user'}), 404
    titles = {
        'medication':  '💊 Test Medication Reminder',
        'appointment': '📅 Test Appointment Reminder',
        'general':     '🔔 Test General Notification',
    }
    title  = titles.get(ntype, '🔔 Test')
    body   = f'This is a test {ntype} notification from Flask.'
    result = _send_fcm(token, title, body, ntype)
    if result:
        _save_to_inbox(uid, title, body, ntype)
        return jsonify({'status': 'sent', 'messageId': result}), 200
    return jsonify({'error': 'Failed to send'}), 500