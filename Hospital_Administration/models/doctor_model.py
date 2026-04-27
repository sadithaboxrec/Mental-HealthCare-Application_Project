from config import db
from datetime import datetime
from typing import List

def create_doctor(data):
    db.collection("doctors").document(data["uid"]).set({
        "uid":               data["uid"],
        "name":              data["name"],
        "email":             data["email"],
        "phone":             data["phone"],
        "specializationIds": data.get("specializationIds", []), # Array of specialization IDs
        "licenseNumber":     data.get("licenseNumber", ""),
        "departmentId":      data.get("departmentId", ""),
        "yearsOfExperience": data.get("yearsOfExperience", 0),
        "bio":               data.get("bio", ""),
        "employeeId":        data.get("employeeId", ""),
        "createdAt":         datetime.utcnow().isoformat()
    })

def get_all_doctors():
    doctors = {}

    for doc in db.collection("doctors").stream():
        data = doc.to_dict() or {}
        uid = data.get("uid", doc.id)
        data["uid"] = uid
        doctors[uid] = data

    for doc in db.collection("users").where("role", "==", "doctor").stream():
        data = doc.to_dict() or {}
        uid = data.get("uid", doc.id)
        data["uid"] = uid
        existing = doctors.get(uid, {})
        doctors[uid] = {**data, **existing}

    return sorted(doctors.values(), key=lambda item: item.get("name", "").lower())
