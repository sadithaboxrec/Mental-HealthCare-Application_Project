
import importlib

def test_create_and_list_users_by_role(fake_db):
    user_model = importlib.import_module("models.user_model")
    user_model.db = fake_db

    user_model.create_user("u1", "Zara", "zara@example.com", "111", "doctor")
    user_model.create_user("u2", "Amal", "amal@example.com", "222", "patient")

    doctors = user_model.get_users_by_role("doctor")

    assert len(doctors) == 1
    assert doctors[0]["uid"] == "u1"
    assert doctors[0]["role"] == "doctor"
    assert "createdAt" in doctors[0]

def test_create_patient_persists_expected_fields(fake_db):
    patient_model = importlib.import_module("models.patient_model")
    patient_model.db = fake_db

    patient_model.create_patient({
        "uid": "p1",
        "name": "Patient One",
        "email": "p1@example.com",
        "phone": "123",
        "gender": "female",
        "dob": "2000-01-01",
        "employeeStatus": "student",
        "assignedDoctor": "d1",
        "guardianUid": "g1",
        "hasGuardian": True,
    })

    saved = fake_db.collection("patients").document("p1").get().to_dict()
    assert saved["assignedDoctor"] == "d1"
    assert saved["guardianUid"] == "g1"
    assert saved["hasGuardian"] is True

def test_doctor_and_counselor_lists_merge_user_fallbacks_and_sort(fake_db):
    doctor_model = importlib.import_module("models.doctor_model")
    counselor_model = importlib.import_module("models.counselor_model")
    doctor_model.db = fake_db
    counselor_model.db = fake_db

    fake_db.collection("doctors").document("d1").set({
        "uid": "d1",
        "name": "Dr B",
        "specializationIds": ["psych"],
    })
    fake_db.collection("users").document("d1").set({
        "uid": "d1",
        "name": "Dr B User",
        "email": "doctor@example.com",
        "role": "doctor",
    })
    fake_db.collection("users").document("d2").set({
        "uid": "d2",
        "name": "Dr A",
        "role": "doctor",
    })
    fake_db.collection("counselors").document("c1").set({
        "uid": "c1",
        "name": "Counselor B",
    })
    fake_db.collection("users").document("c2").set({
        "uid": "c2",
        "name": "Counselor A",
        "role": "counselor",
    })

    doctors = doctor_model.get_all_doctors()
    counselors = counselor_model.get_all_counselors()

    assert [doctor["uid"] for doctor in doctors] == ["d2", "d1"]
    assert doctors[1]["email"] == "doctor@example.com"
    assert doctors[1]["specializationIds"] == ["psych"]
    assert [counselor["uid"] for counselor in counselors] == ["c2", "c1"]

def test_guardian_lookup_returns_first_match(fake_db):
    guardian_model = importlib.import_module("models.guardian_model")
    guardian_model.db = fake_db

    guardian_model.create_guardian("g1", "p1", "Guardian", "g@example.com", ["123"])

    guardian = guardian_model.get_guardian_by_patient("p1")

    assert guardian["uid"] == "g1"
    assert guardian["patientUid"] == "p1"
    assert guardian_model.get_guardian_by_patient("missing") is None
