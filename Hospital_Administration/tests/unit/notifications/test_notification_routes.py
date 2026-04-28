
import importlib

def _load_notifications(fake_db):
    module = importlib.import_module("routes.notification_routes")
    module.db = fake_db
    return module

def test_get_token_reads_user_fcm_token(fake_db):
    fake_db.collection("users").document("patient-1").set({
        "uid": "patient-1",
        "fcmToken": "token-123",
    })
    notifications = _load_notifications(fake_db)

    assert notifications._get_token("patient-1") == "token-123"
    assert notifications._get_token("missing") is None

def test_run_water_reminders_sends_only_to_patients_with_tokens(fake_db, monkeypatch):
    fake_db.collection("users").document("patient-1").set({
        "uid": "patient-1",
        "role": "patient",
        "fcmToken": "token-1",
    })
    fake_db.collection("users").document("patient-2").set({
        "uid": "patient-2",
        "role": "patient",
    })
    fake_db.collection("users").document("doctor-1").set({
        "uid": "doctor-1",
        "role": "doctor",
        "fcmToken": "token-doctor",
    })
    notifications = _load_notifications(fake_db)
    sent = []
    monkeypatch.setattr(
        notifications,
        "_send_fcm",
        lambda token, title, body, notif_type: sent.append((token, title, notif_type)) or "msg-id",
    )

    sent_count, error_count = notifications.run_water_reminders()

    assert sent_count == 1
    assert error_count == 0
    assert sent[0][0] == "token-1"
    assert "Stay Hydrated" in sent[0][1]
    assert sent[0][2] == "general"
    inbox = fake_db.collection("notifications").added
    assert len(inbox) == 1
    assert inbox[0]["uid"] == "patient-1"

def test_run_medication_reminders_sends_patient_and_guardian(fake_db, monkeypatch):
    fake_db.collection("users").document("patient-1").set({
        "uid": "patient-1",
        "fcmToken": "patient-token",
    })
    fake_db.collection("users").document("guardian-1").set({
        "uid": "guardian-1",
        "fcmToken": "guardian-token",
    })
    fake_db.collection("patients").document("patient-1").set({
        "uid": "patient-1",
        "guardianUid": "guardian-1",
    })
    fake_db.collection("prescriptions").document("rx-1").set({
        "patientUid": "patient-1",
        "patientName": "Asha",
        "isActive": True,
        "medicines": [
            {
                "name": "Sertraline",
                "dose": "50mg",
                "beforeMeal": False,
                "morning": True,
            }
        ],
    })
    notifications = _load_notifications(fake_db)
    monkeypatch.setattr(notifications, "_current_slot", lambda: "morning")
    sent = []
    monkeypatch.setattr(
        notifications,
        "_send_fcm",
        lambda token, title, body, notif_type: sent.append((token, title, body, notif_type)) or "msg-id",
    )

    sent_count = notifications.run_medication_reminders()

    assert sent_count == 2
    assert [item[0] for item in sent] == ["patient-token", "guardian-token"]
    assert "Sertraline" in sent[0][2]
    assert fake_db.collection("notifications").added[0]["uid"] == "patient-1"
