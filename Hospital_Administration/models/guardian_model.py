from config import db
from datetime import datetime
from typing import List, Optional

def create_guardian(
    uid: str, 
    patient_uid: str, 
    name: str, 
    email: str, 
    phones: List[str],
    gender: Optional[str] = None,
    dob: Optional[str] = None,
    employment_status: Optional[str] = None,
    relationship: Optional[str] = None
):
    db.collection("guardians").document(uid).set({
        "uid":               uid,
        "patientUid":        patient_uid,
        "name":              name,
        "email":             email,
        "phones":            phones,
        "gender":            gender,
        "dob":               dob,
        "employmentStatus":  employment_status,
        "relationshipToPatient": relationship,
        "createdAt":         datetime.utcnow().isoformat()
    })

def get_guardian_by_patient(patient_uid: str):
    docs = db.collection("guardians")\
             .where("patientUid", "==", patient_uid).stream()
    result = [d.to_dict() for d in docs]
    return result[0] if result else None