from flask import request, jsonify
from services.firebase_service import create_firebase_user
from config import db
from firebase_admin import auth

def create_admin_controller():
    data = request.json

    name = data.get("name", "").strip()
    email = data.get("email", "").strip()
    password = data.get("password", "").strip()
    phone = data.get("phone", "").strip()

    if not all([name, email, password, phone]):
        return jsonify({"error": "All fields are required"}), 400

    try:
        # Create user in Firebase Auth
        uid = create_firebase_user(email, password, name)
        
        # Set custom claims
        auth.set_custom_user_claims(uid, {'role': 'admin'})

        # Save to Firestore
        db.collection("users").document(uid).set({
            "uid": uid,
            "name": name,
            "email": email,
            "phone": phone,
            "role": "admin"
        })

        return jsonify({"success": True, "uid": uid})

    except Exception as e:
        return jsonify({"error": str(e)}), 400


def toggle_user_status(uid):
    from flask_login import current_user
    data = request.json
    disabled = data.get("disabled", True)
    
    try:
        # Security: Only super_admin can disable admins
        user_record = auth.get_user(uid)
        claims = user_record.custom_claims or {}
        if claims.get("role") == "admin" and current_user.role != "super_admin":
            return jsonify({"error": "Permission denied. Only Super Admins can modify Admins."}), 403
            
        auth.update_user(uid, disabled=disabled)
        
        # Sync the state to Firestore so the Dashboard UI can show a badge without querying Auth
        status_str = "disabled" if disabled else "active"
        db.collection("users").document(uid).update({"accountStatus": status_str})
        
        return jsonify({"success": True, "disabled": disabled, "status": status_str})
    except Exception as e:
        return jsonify({"error": str(e)}), 400


def delete_user_account(uid):
    from flask_login import current_user
    try:
        # Security check
        user_record = auth.get_user(uid)
        claims = user_record.custom_claims or {}
        role = claims.get("role")
        
        # Fallback check if claims missing
        if not role:
            doc = db.collection("users").document(uid).get()
            if doc.exists:
                role = doc.to_dict().get("role")
                
        if role in ["admin", "super_admin"] and current_user.role != "super_admin":
            return jsonify({"error": "Permission denied."}), 403

        # 1. Delete from Auth
        auth.delete_user(uid)
        
        # 2. Delete from users collection
        db.collection("users").document(uid).delete()
        
        # 3. Delete from specific role collection
        if role:
            db.collection(f"{role}s").document(uid).delete()
            
        return jsonify({"success": True})
    except Exception as e:
        return jsonify({"error": str(e)}), 400
