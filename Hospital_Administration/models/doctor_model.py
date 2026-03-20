from config import db
from datetime import datetime

def create_doctor(data):
    db.collection("doctors").document(data["uid"]).set({
        "uid":            data["uid"],
        "name":           data["name"],
        "email":          data["email"],
        "phone":          data["phone"],
        "specialization": data["specialization"],
        "employeeId":     data["employeeId"],
        "createdAt":      datetime.utcnow().isoformat()
    })

def get_all_doctors():
    docs = db.collection("doctors").stream()
    return [d.to_dict() for d in docs]