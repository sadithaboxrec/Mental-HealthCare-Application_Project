from config import db
from datetime import datetime

def create_counselor(data):
    db.collection("counselors").document(data["uid"]).set({
        "uid":            data["uid"],
        "name":           data["name"],
        "email":          data["email"],
        "phone":          data["phone"],
        "specialization": data["specialization"],
        "employeeId":     data["employeeId"],
        "createdAt":      datetime.utcnow().isoformat()
    })

def get_all_counselors():
    docs = db.collection("counselors").stream()
    return [d.to_dict() for d in docs]