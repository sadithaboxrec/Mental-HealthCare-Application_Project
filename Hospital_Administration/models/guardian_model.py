from config import db
from datetime import datetime

def create_guardian(uid, patient_uid, name, email, phone):
    db.collection("guardians").document(uid).set({
        "uid":        uid,
        "patientUid": patient_uid,
        "name":       name,
        "email":      email,
        "phone":      phone,
        "createdAt":  datetime.utcnow().isoformat()
    })

def get_guardian_by_patient(patient_uid):
    docs = db.collection("guardians")\
             .where("patientUid", "==", patient_uid).stream()
    result = [d.to_dict() for d in docs]
    return result[0] if result else None