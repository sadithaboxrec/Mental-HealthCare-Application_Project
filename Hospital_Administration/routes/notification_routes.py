from flask import Blueprint, jsonify, request
from firebase_admin import messaging
from config import db
from datetime import datetime, timedelta

notification_routes = Blueprint('notification_routes', __name__)


# ── Helpers ───────────────────────────────────────────────

def _send_fcm(token, title, body, notif_type='general'):
    try:
        print(f'\n--- FCM Notification ---')
        print(f'Type:  {notif_type}')
        print(f'Title: {title}')
        print(f'Body:  {body}')
        print(f'Token: {token[:30]}...')
        print(f'------------------------')

        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
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
        print(f'FCM sent successfully: {response}')
        return response
    except Exception as e:
        print(f'FCM error: {e}')
        return None


def _save_to_inbox(uid, title, body, notif_type):
    """Save notification to Firestore inbox"""
    try:
        db.collection('notifications').add({
            'uid':       uid,
            'title':     title,
            'body':      body,
            'type':      notif_type,
            'isRead':    False,
            'createdAt': datetime.now().isoformat(),
        })
    except Exception as e:
        print(f'Inbox save error: {e}')


def _format_dose(med):
    """Returns dose string only if it exists and is not empty"""
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


# ── Medication Reminders ──────────────────────────────────

def run_medication_reminders():
    slot = _current_slot()
    sent = 0
    skip = 0

    print(f'\n=== Medication reminders — slot: {slot} ===')

    prescriptions = db.collection('prescriptions') \
        .where('isActive', '==', True).stream()

    for pres in prescriptions:
        data         = pres.to_dict()
        patient_uid  = data.get('patientUid', '')
        patient_name = data.get('patientName', 'Patient')
        medicines    = data.get('medicines', [])

        slot_meds = [m for m in medicines if m.get(slot, False)]

        if not slot_meds:
            skip += 1
            continue

        p_token = _get_token(patient_uid)

        for med in slot_meds:
            meal  = 'before meal' if med.get('beforeMeal') else 'after meal'
            dose  = _format_dose(med)
            title = '💊 Time for your medicine'
            body  = f'Take {med["name"]}{dose} {meal}.'

            # Send to patient
            if p_token:
                result = _send_fcm(
                    token=p_token,
                    title=title,
                    body=body,
                    notif_type='medication',
                )
                if result:
                    sent += 1
                    _save_to_inbox(patient_uid, title, body, 'medication')

            # Send to guardian
            patient_doc = db.collection('patients') \
                .document(patient_uid).get()
            if patient_doc.exists:
                guardian_uid = patient_doc.to_dict().get('guardianUid')
                if guardian_uid:
                    g_token = _get_token(guardian_uid)
                    if g_token:
                        g_title = f'💊 Medication — {patient_name}'
                        g_body  = f'{patient_name} needs to take ' \
                                  f'{med["name"]}{dose} {meal}.'
                        result = _send_fcm(
                            token=g_token,
                            title=g_title,
                            body=g_body,
                            notif_type='medication',
                        )
                        if result: sent += 1

    print(f'Medication reminders done — sent: {sent}, skipped: {skip}')
    return sent


# ── Appointment Reminders ─────────────────────────────────

def run_appointment_reminders():
    tomorrow = _tomorrow_str()
    sent     = 0

    print(f'\n=== Appointment reminders — tomorrow: {tomorrow} ===')

    appointments = db.collection('appointments') \
        .where('date', '==', tomorrow) \
        .where('status', 'in', ['scheduled', 'rescheduled']) \
        .stream()

    for apt in appointments:
        data         = apt.to_dict()
        patient_uid  = data.get('patientUid', '')
        patient_name = data.get('patientName', 'Patient')
        time         = data.get('time', '')

        p_token = _get_token(patient_uid)

        # Send to patient
        if p_token:
            title = '📅 Clinic Visit Tomorrow'
            body  = f'You have an appointment tomorrow ' \
                    f'at {time} on {tomorrow}. Please prepare.'
            result = _send_fcm(
                token=p_token,
                title=title,
                body=body,
                notif_type='appointment',
            )
            if result:
                sent += 1
                _save_to_inbox(patient_uid, title, body, 'appointment')

        # Send to guardian
        patient_doc = db.collection('patients') \
            .document(patient_uid).get()
        if patient_doc.exists:
            guardian_uid = patient_doc.to_dict().get('guardianUid')
            if guardian_uid:
                g_token = _get_token(guardian_uid)
                if g_token:
                    result = _send_fcm(
                        token=g_token,
                        title=f'📅 Appointment Tomorrow — {patient_name}',
                        body=f'{patient_name} has a clinic visit '
                             f'tomorrow at {time} on {tomorrow}.',
                        notif_type='appointment',
                    )
                    if result: sent += 1

    print(f'Appointment reminders done — sent: {sent}')
    return sent


# ── Water Reminders ───────────────────────────────────────

def run_water_reminders():
    sent   = 0
    errors = 0
    title  = '💧 Stay Hydrated'
    body   = 'Don\'t forget to drink water and log your intake today.'

    patients = db.collection('users') \
        .where('role', '==', 'patient').stream()

    for p in patients:
        data  = p.to_dict()
        token = data.get('fcmToken')
        uid   = data.get('uid', '')

        if not token:
            continue

        result = _send_fcm(
            token=token,
            title=title,
            body=body,
            notif_type='general',
        )
        if result:
            sent += 1
            _save_to_inbox(uid, title, body, 'general')
        else:
            errors += 1

    return sent, errors


# ── Diary Reminders ───────────────────────────────────────

def run_diary_reminders():
    sent   = 0
    errors = 0
    title  = '📓 Write in your diary'
    body   = 'Take a moment to record your thoughts and feelings today.'

    patients = db.collection('users') \
        .where('role', '==', 'patient').stream()

    for p in patients:
        data  = p.to_dict()
        token = data.get('fcmToken')
        uid   = data.get('uid', '')

        if not token:
            continue

        result = _send_fcm(
            token=token,
            title=title,
            body=body,
            notif_type='general',
        )
        if result:
            sent += 1
            _save_to_inbox(uid, title, body, 'general')
        else:
            errors += 1

    return sent, errors


# ── Endpoints ─────────────────────────────────────────────

@notification_routes.route('/trigger/medications', methods=['POST'])
def trigger_medications():
    sent = run_medication_reminders()
    return jsonify({
        'status': 'done',
        'slot':   _current_slot(),
        'sent':   sent,
    }), 200


@notification_routes.route('/trigger/appointments', methods=['POST'])
def trigger_appointments():
    sent = run_appointment_reminders()
    return jsonify({
        'status':   'done',
        'tomorrow': _tomorrow_str(),
        'sent':     sent,
    }), 200


@notification_routes.route('/trigger/water', methods=['POST'])
def trigger_water():
    sent, errors = run_water_reminders()
    return jsonify({
        'status': 'done',
        'sent':   sent,
        'errors': errors,
    }), 200


@notification_routes.route('/trigger/diary', methods=['POST'])
def trigger_diary():
    sent, errors = run_diary_reminders()
    return jsonify({
        'status': 'done',
        'sent':   sent,
        'errors': errors,
    }), 200


@notification_routes.route('/trigger/test', methods=['POST'])
def trigger_test():
    data  = request.json
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
    title = titles.get(ntype, '🔔 Test')
    body  = f'This is a test {ntype} notification from Flask.'

    result = _send_fcm(
        token=token,
        title=title,
        body=body,
        notif_type=ntype,
    )

    if result:
        _save_to_inbox(uid, title, body, ntype)
        return jsonify({'status': 'sent', 'messageId': result}), 200
    return jsonify({'error': 'Failed to send'}), 500