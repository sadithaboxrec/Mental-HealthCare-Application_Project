from flask import Blueprint, jsonify, request
from firebase_admin import messaging
from config import db
from datetime import datetime, timedelta

notification_routes = Blueprint('notification_routes', __name__)


#  Helpers for notfications

def _send_fcm(token, title, body, notif_type='general'):
    try:
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
                    notification_priority=
                        messaging.AndroidNotificationPriority.PRIORITY_MAX,
                ),
            ),
            data={'type': notif_type},
            token=token,
        )
        response = messaging.send(message)
        print(f'FCM sent: {response}')
        return response
    except Exception as e:
        print(f'FCM error: {e}')
        return None


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


# Medication Reminders

def run_medication_reminders():

#    Checks  prescriptions and sends medication reminders to patients and their guardians based on time

    slot  = _current_slot()
    sent  = 0
    skip  = 0

    print(f'\n=== Medication reminders — slot: {slot} ===')

    prescriptions = db.collection('prescriptions') \
        .where('isActive', '==', True).stream()

    for pres in prescriptions:
        data         = pres.to_dict()
        patient_uid  = data.get('patientUid', '')
        patient_name = data.get('patientName', 'Patient')
        medicines    = data.get('medicines', [])

        # Filter medicines for current slot
        slot_meds = [m for m in medicines if m.get(slot, False)]

        if not slot_meds:
            skip += 1
            continue

        # Send to patient
        p_token = _get_token(patient_uid)
        if p_token:
            for med in slot_meds:
                meal = 'before meal' if med.get('beforeMeal') \
                    else 'after meal'
                result = _send_fcm(
                    token=p_token,
                    title='💊 Time for your medicine',
                    body=f'Take {med["name"]} ({med.get("dose", "")}) '
                         f'{meal}.',
                    notif_type='medication',
                )
                if result: sent += 1

        # Send to guardian
        patient_doc = db.collection('patients') \
            .document(patient_uid).get()
        if patient_doc.exists:
            guardian_uid = patient_doc.to_dict().get('guardianUid')
            if guardian_uid:
                g_token = _get_token(guardian_uid)
                if g_token:
                    for med in slot_meds:
                        meal = 'before meal' if med.get('beforeMeal') \
                            else 'after meal'
                        result = _send_fcm(
                            token=g_token,
                            title=f'💊 Medication — {patient_name}',
                            body=f'{patient_name} needs to take '
                                 f'{med["name"]} '
                                 f'({med.get("dose", "")}) {meal}.',
                            notif_type='medication',
                        )
                        if result: sent += 1

    print(f'Medication reminders done — sent: {sent}, skipped: {skip}')
    return sent


#  Appointment Reminders

def run_appointment_reminders():

  #  Checks appointments for tomorrow and sends reminders to patients and their guardians.

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

        # Send to patient
        p_token = _get_token(patient_uid)
        if p_token:
            result = _send_fcm(
                token=p_token,
                title='📅 Clinic Visit Tomorrow',
                body=f'You have an appointment tomorrow '
                     f'at {time} on {tomorrow}. Please prepare.',
                notif_type='appointment',
            )
            if result: sent += 1

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


# Testing end points

@notification_routes.route('/trigger/medications', methods=['POST'])
def trigger_medications():
    sent = run_medication_reminders()
    return jsonify({
        'status':  'done',
        'slot':    _current_slot(),
        'sent':    sent,
    }), 200


@notification_routes.route('/trigger/appointments', methods=['POST'])
def trigger_appointments():
    sent = run_appointment_reminders()
    return jsonify({
        'status':   'done',
        'tomorrow': _tomorrow_str(),
        'sent':     sent,
    }), 200


#  Single device test endpoint

@notification_routes.route('/trigger/test', methods=['POST'])
def trigger_test():
    """
    POST body: { "uid": "user_uid_here", "type": "medication" }
    Sends a test notification to a specific user.
    """
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

    result = _send_fcm(
        token=token,
        title=titles.get(ntype, '🔔 Test'),
        body=f'This is a test {ntype} notification from Flask.',
        notif_type=ntype,
    )

    if result:
        return jsonify({'status': 'sent', 'messageId': result}), 200
    return jsonify({'error': 'Failed to send'}), 500