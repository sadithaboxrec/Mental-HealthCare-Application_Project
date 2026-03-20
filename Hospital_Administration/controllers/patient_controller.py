from flask import request, jsonify
from services.firebase_service import create_firebase_user
from models.user_model import create_user
from models.patient_model import create_patient
from models.guardian_model import create_guardian

def create_patient_controller():
    data = request.json

    name            = data.get("name",           "").strip()
    email           = data.get("email",          "").strip()
    password        = data.get("password",       "").strip()
    phone           = data.get("phone",          "").strip()
    gender          = data.get("gender",         "").strip()
    dob             = data.get("dob",            "").strip()
    employee_status = data.get("employeeStatus", "").strip()
    assigned_doctor = data.get("assignedDoctor", "").strip()
    has_guardian    = data.get("hasGuardian",    False)

    if not all([name, email, password, phone,
                gender, dob, employee_status, assigned_doctor]):
        return jsonify({"error": "All patient fields are required"}), 400

    try:
        patient_uid  = create_firebase_user(email, password, name)
        guardian_uid = None

        create_user(patient_uid, name, email, phone, "patient")

        if has_guardian:
            g_name     = data.get("guardianName",     "").strip()
            g_email    = data.get("guardianEmail",    "").strip()
            g_password = data.get("guardianPassword", "").strip()
            g_phone    = data.get("guardianPhone",    "").strip()

            if not all([g_name, g_email, g_password, g_phone]):
                return jsonify({"error": "All guardian fields are required"}), 400

            guardian_uid = create_firebase_user(g_email, g_password, g_name)
            create_user(guardian_uid, g_name, g_email, g_phone, "guardian")
            create_guardian(guardian_uid, patient_uid,
                            g_name, g_email, g_phone)

        create_patient({
            "uid":            patient_uid,
            "name":           name,
            "email":          email,
            "phone":          phone,
            "gender":         gender,
            "dob":            dob,
            "employeeStatus": employee_status,
            "assignedDoctor": assigned_doctor,
            "guardianUid":    guardian_uid,
            "hasGuardian":    has_guardian
        })

        return jsonify({
            "success":     True,
            "patientUid":  patient_uid,
            "guardianUid": guardian_uid
        }), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500


def assign_doctor_controller():
    data        = request.json
    patient_uid = data.get("patientUid", "").strip()
    doctor_uid  = data.get("doctorUid",  "").strip()

    if not patient_uid or not doctor_uid:
        return jsonify({"error": "Both fields required"}), 400

    try:
        from config import db
        db.collection("patients").document(patient_uid).update({
            "assignedDoctor": doctor_uid
        })
        return jsonify({"success": True}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500