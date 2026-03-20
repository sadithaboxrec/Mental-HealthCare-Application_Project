from flask import request, jsonify
from services.firebase_service import create_firebase_user
from models.user_model import create_user
from models.counselor_model import create_counselor

def create_counselor_controller():
    data = request.json

    name           = data.get("name",           "").strip()
    email          = data.get("email",          "").strip()
    password       = data.get("password",       "").strip()
    phone          = data.get("phone",          "").strip()
    specialization = data.get("specialization", "").strip()
    employee_id    = data.get("employeeId",     "").strip()

    if not all([name, email, password, phone, specialization, employee_id]):
        return jsonify({"error": "All fields are required"}), 400

    try:
        uid = create_firebase_user(email, password, name)
        create_user(uid, name, email, phone, "counselor")
        create_counselor({
            "uid":            uid,
            "name":           name,
            "email":          email,
            "phone":          phone,
            "specialization": specialization,
            "employeeId":     employee_id
        })
        return jsonify({"success": True, "uid": uid}), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500