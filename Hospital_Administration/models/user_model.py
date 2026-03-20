from config import db
from datetime import datetime

def create_user(uid, name, email, phone, role):
    db.collection("users").document(uid).set({
        "uid":       uid,
        "name":      name,
        "email":     email,
        "phone":     phone,
        "role":      role,
        "createdAt": datetime.utcnow().isoformat()
    })

def get_users_by_role(role):
    docs = db.collection("users").where("role", "==", role).stream()
    return [d.to_dict() for d in docs]