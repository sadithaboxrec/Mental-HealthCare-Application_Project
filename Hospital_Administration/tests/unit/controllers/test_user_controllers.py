
import importlib

from flask import Flask

def _app():
    app = Flask(__name__)
    app.config.update(TESTING=True)
    return app

def test_create_doctor_controller_validates_required_fields(fake_db):
    controller = importlib.import_module("controllers.doctor_controller")

    with _app().test_request_context(json={"name": "Only Name"}):
        response, status = controller.create_doctor_controller()

    assert status == 400
    assert response.get_json() == {"error": "All fields are required"}

def test_create_doctor_controller_creates_auth_user_and_profile(fake_db, monkeypatch):
    controller = importlib.import_module("controllers.doctor_controller")
    calls = []
    monkeypatch.setattr(controller, "create_firebase_user", lambda email, password, name: "doctor-uid")
    monkeypatch.setattr(controller.auth, "set_custom_user_claims", lambda uid, claims: calls.append((uid, claims)))
    monkeypatch.setattr(controller, "create_user", lambda *args: calls.append(("user", args)))
    monkeypatch.setattr(controller, "create_doctor", lambda data: calls.append(("doctor", data)))

    payload = {
        "name": "Doctor One",
        "email": "doctor@example.com",
        "password": "secret",
        "phone": "123",
        "employeeId": "EMP-1",
        "specializationIds": "psychiatry",
    }
    with _app().test_request_context(json=payload):
        response, status = controller.create_doctor_controller()

    assert status == 201
    assert response.get_json() == {"success": True, "uid": "doctor-uid"}
    assert ("doctor-uid", {"role": "doctor"}) in calls
    assert calls[-1][1]["specializationIds"] == ["psychiatry"]

def test_create_counselor_controller_validates_specialization(fake_db):
    controller = importlib.import_module("controllers.counselor_controller")

    with _app().test_request_context(json={
        "name": "Counselor",
        "email": "c@example.com",
        "password": "secret",
        "phone": "123",
        "employeeId": "EMP-2",
    }):
        response, status = controller.create_counselor_controller()

    assert status == 400
    assert response.get_json() == {"error": "All fields are required"}

def test_create_patient_controller_requires_guardian_fields_when_enabled(fake_db, monkeypatch):
    controller = importlib.import_module("controllers.patient_controller")
    monkeypatch.setattr(controller, "create_firebase_user", lambda email, password, name: "patient-uid")
    monkeypatch.setattr(controller.auth, "set_custom_user_claims", lambda *args, **kwargs: None)
    monkeypatch.setattr(controller, "create_user", lambda *args, **kwargs: None)

    payload = {
        "name": "Patient",
        "email": "p@example.com",
        "password": "secret",
        "phone": "123",
        "gender": "female",
        "dob": "2000-01-01",
        "employeeStatus": "student",
        "assignedDoctor": "d1",
        "hasGuardian": True,
    }
    with _app().test_request_context(json=payload):
        response, status = controller.create_patient_controller()

    assert status == 400
    assert response.get_json() == {"error": "All guardian fields are required"}

def test_create_patient_controller_creates_patient_and_guardian(fake_db, monkeypatch):
    controller = importlib.import_module("controllers.patient_controller")
    created_users = iter(["patient-uid", "guardian-uid"])
    calls = []
    monkeypatch.setattr(controller, "create_firebase_user", lambda email, password, name: next(created_users))
    monkeypatch.setattr(controller.auth, "set_custom_user_claims", lambda uid, claims: calls.append((uid, claims)))
    monkeypatch.setattr(controller, "create_user", lambda *args: calls.append(("user", args)))
    monkeypatch.setattr(controller, "create_guardian", lambda *args: calls.append(("guardian", args)))
    monkeypatch.setattr(controller, "create_patient", lambda data: calls.append(("patient", data)))

    payload = {
        "name": "Patient",
        "email": "p@example.com",
        "password": "secret",
        "phone": "123",
        "gender": "female",
        "dob": "2000-01-01",
        "employeeStatus": "student",
        "assignedDoctor": "d1",
        "hasGuardian": True,
        "guardianName": "Guardian",
        "guardianEmail": "g@example.com",
        "guardianPassword": "secret",
        "guardianPhone": "456",
    }
    with _app().test_request_context(json=payload):
        response, status = controller.create_patient_controller()

    assert status == 201
    assert response.get_json() == {
        "success": True,
        "patientUid": "patient-uid",
        "guardianUid": "guardian-uid",
    }
    assert ("guardian-uid", {"role": "guardian"}) in calls
    assert calls[-1][1]["guardianUid"] == "guardian-uid"

def test_assign_doctor_controller_updates_patient(fake_db):
    controller = importlib.import_module("controllers.patient_controller")
    fake_db.collection("patients").document("p1").set({"uid": "p1"})

    with _app().test_request_context(json={"patientUid": "p1", "doctorUid": "d1"}):
        response, status = controller.assign_doctor_controller()

    assert status == 200
    assert response.get_json() == {"success": True}
    assert fake_db.collection("patients").document("p1").get().to_dict()["assignedDoctor"] == "d1"
