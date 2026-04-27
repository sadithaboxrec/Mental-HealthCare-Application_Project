from config import db
from datetime import datetime

def create_counselor(data):
    db.collection("counselors").document(data["uid"]).set({
        "uid":               data["uid"],
        "name":              data["name"],
        "email":             data["email"],
        "phone":             data["phone"],
        "specializationIds": data.get("specializationIds", []),
        "licenseNumber":     data.get("licenseNumber", ""),
        "departmentId":      data.get("departmentId", ""),
        "yearsOfExperience": data.get("yearsOfExperience", 0),
        "bio":               data.get("bio", ""),
        "employeeId":        data.get("employeeId", ""),
        "createdAt":         datetime.utcnow().isoformat()
    })

def get_all_counselors():
    counselors = {}

    for doc in db.collection("counselors").stream():
        data = doc.to_dict() or {}
        uid = data.get("uid", doc.id)
        data["uid"] = uid
        counselors[uid] = data

    for doc in db.collection("users").where("role", "==", "counselor").stream():
        data = doc.to_dict() or {}
        uid = data.get("uid", doc.id)
        data["uid"] = uid
        existing = counselors.get(uid, {})
        counselors[uid] = {**data, **existing}

    return sorted(counselors.values(), key=lambda item: item.get("name", "").lower())
