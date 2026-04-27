from functools import wraps
from flask import Blueprint, flash, redirect, render_template, request, url_for
from flask_login import LoginManager, UserMixin, current_user, login_user, logout_user
import requests as http_requests
from config import db
from firebase_admin import auth

# ── Flask-Login user class ───────────────────────────────────────────────────

class User(UserMixin):
    def __init__(self, uid: str, name: str, email: str, role: str):
        self.id    = uid
        self.uid   = uid
        self.name  = name
        self.email = email
        self.role  = role


# ── Login manager setup (call this in app.py) ────────────────────────────────

login_manager = LoginManager()
login_manager.login_view        = "auth_routes.login"
login_manager.login_message     = "Please log in to access this page."
login_manager.login_message_category = "warning"

FIREBASE_API_KEY = "AIzaSyCeYPlNIvZl6HwLVjDKSjQXhERsxmslYYc"
FIREBASE_SIGN_IN_URL = (
    f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword"
    f"?key={FIREBASE_API_KEY}"
)


@login_manager.user_loader
def load_user(uid: str):
    """
    Reload user from Firestore on every request.
    (Note: In a pure JWT stateless architecture, we wouldn't need a DB read here,
    but Flask-Login requires server-side session loading. We trust the role stored in DB
    for session persistence, but the initial login MUST verify via Custom Claims).
    """
    doc = db.collection("users").document(uid).get()
    if not doc.exists:
        return None
    data = doc.to_dict()
    return User(
        uid=uid,
        name=data.get("name", ""),
        email=data.get("email", ""),
        role=data.get("role", ""),
    )


# ── Role-based access decorator ──────────────────────────────────────────────

def role_required(*roles):
    """Restrict a view to users with one of the specified roles."""
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            if not current_user.is_authenticated:
                return redirect(url_for("auth_routes.login"))
            if current_user.role not in roles:
                return render_template("403.html"), 403
            return fn(*args, **kwargs)
        return wrapper
    return decorator


# ── Blueprint ────────────────────────────────────────────────────────────────

auth_routes = Blueprint("auth_routes", __name__)


@auth_routes.route("/login", methods=["GET", "POST"])
def login():
    if current_user.is_authenticated:
        return _redirect_for_role(current_user.role)

    error = None
    if request.method == "POST":
        email    = request.form.get("email", "").strip()
        password = request.form.get("password", "").strip()

        if not email or not password:
            error = "Email and password are required."
        else:
            # Step 1: Verify credentials via Firebase Identity Toolkit
            try:
                resp = http_requests.post(
                    FIREBASE_SIGN_IN_URL,
                    json={"email": email, "password": password, "returnSecureToken": True},
                    timeout=8,
                )
                resp_data = resp.json()
            except Exception:
                error = "Could not connect to authentication service. Try again."
                return render_template("login.html", error=error)

            if "error" in resp_data:
                firebase_msg = resp_data["error"].get("message", "INVALID_CREDENTIALS")
                if "EMAIL_NOT_FOUND" in firebase_msg or "INVALID_PASSWORD" in firebase_msg or "INVALID_LOGIN_CREDENTIALS" in firebase_msg:
                    error = "Invalid email or password."
                elif "TOO_MANY_ATTEMPTS" in firebase_msg:
                    error = "Too many failed attempts. Please try again later."
                else:
                    error = "Authentication failed. Please try again."
                return render_template("login.html", error=error)

            # Step 2: Decode the ID Token to enforce Custom Claims (Industry Standard)
            id_token = resp_data.get("idToken", "")
            try:
                decoded_token = auth.verify_id_token(id_token)
            except Exception as e:
                error = "Invalid authentication token. Please try logging in again."
                return render_template("login.html", error=error)
            
            # Extract role from cryptographic claims. Fallback to Firestore only if missing (for legacy doctors).
            # SOTA requires Custom Claims for admin-tier roles.
            role = decoded_token.get("role")
            uid = decoded_token.get("uid")
            
            if not role:
                # Fallback for existing legacy doctors without custom claims yet
                user_doc = db.collection("users").document(uid).get()
                if user_doc.exists:
                    role = user_doc.to_dict().get("role")
            
            if role not in ("super_admin", "admin", "doctor"):
                error = "Access denied. You do not have portal access permissions."
                return render_template("login.html", error=error)
            
            # Fetch user details for the session
            user_doc = db.collection("users").document(uid).get()
            user_data = user_doc.to_dict() if user_doc.exists else {}

            user = User(
                uid=uid,
                name=user_data.get("name", "User"),
                email=user_data.get("email", email),
                role=role,
            )
            login_user(user, remember=False)
            next_url = request.args.get("next")
            if next_url:
                return redirect(next_url)
            return _redirect_for_role(role)

    return render_template("login.html", error=error)


@auth_routes.route("/logout")
def logout():
    logout_user()
    return redirect(url_for("auth_routes.login"))


def _redirect_for_role(role: str):
    if role in ("super_admin", "admin"):
        return redirect(url_for("admin_routes.dashboard"))
    if role == "doctor":
        return redirect(url_for("doctor_portal_routes.portal_dashboard"))
    return redirect(url_for("auth_routes.login"))
