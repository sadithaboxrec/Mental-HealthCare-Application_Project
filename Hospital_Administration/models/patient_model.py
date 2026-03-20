from config import db
from datetime import datetime

def create_patient(data):
    db.collection("patients").document(data["uid"]).set({
        "uid":            data["uid"],
        "name":           data["name"],
        "email":          data["email"],
        "phone":          data["phone"],
        "gender":         data["gender"],
        "dob":            data["dob"],
        "employeeStatus": data["employeeStatus"],
        "assignedDoctor": data["assignedDoctor"],
        "guardianUid":    data.get("guardianUid"),
        "hasGuardian":    data.get("hasGuardian", False),
        "createdAt":      datetime.utcnow().isoformat()
    })

def get_all_patients():
    docs = db.collection("patients").stream()
    return [d.to_dict() for d in docs]