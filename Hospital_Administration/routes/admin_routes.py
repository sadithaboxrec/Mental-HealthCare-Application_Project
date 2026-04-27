from flask import Blueprint, jsonify, render_template, request
from flask_login import login_required, current_user
from routes.auth_routes import role_required
from models.doctor_model import get_all_doctors
from models.counselor_model import get_all_counselors
from models.patient_model import get_all_patients
from models.user_model import get_users_by_role
from config import db

admin_routes = Blueprint("admin_routes", __name__, url_prefix="/admin")


@admin_routes.route("/")
@login_required
@role_required("super_admin", "admin")
def dashboard():
    """
    Admin Dashboard — system-wide KPIs.
    ---
    tags: [Admin]
    responses:
      200:
        description: Admin dashboard HTML
    """
    doctors    = get_all_doctors()
    counselors = get_all_counselors()
    patients   = get_all_patients()

    # Count open clinical alerts
    open_alerts = list(db.collection("clinical_alerts").where("status", "==", "open").stream())
    critical    = [a for a in open_alerts if a.to_dict().get("severity") == "critical"]
    warning     = [a for a in open_alerts if a.to_dict().get("severity") == "warning"]

    return render_template(
        "admin/dashboard.html",
        doctor_count    = len(doctors),
        counselor_count = len(counselors),
        patient_count   = len(patients),
        open_alert_count= len(open_alerts),
        critical_count  = len(critical),
        warning_count   = len(warning),
    )


# ── ADMIN MANAGEMENT (SUPER ADMIN ONLY) ──────────────────────────────────────

@admin_routes.route("/admins")
@login_required
@role_required("super_admin")
def admins():
    """
    Super Admin: Admins Directory.
    ---
    tags: [Admin]
    responses:
      200:
        description: Admins directory HTML
    """
    admins_list = get_users_by_role("admin")
    return render_template("admin/admins.html", admins=admins_list)


@admin_routes.route("/admins/create", methods=["GET"])
@login_required
@role_required("super_admin")
def create_admin_page():
    return render_template("admin/create_admin.html")


@admin_routes.route("/admins/create", methods=["POST"])
@login_required
@role_required("super_admin")
def create_admin():
    """
    Super Admin: Create a new Administrative user.
    ---
    tags: [Admin]
    parameters:
      - in: body
        name: body
        schema:
          type: object
          required: [name, email, password, phone]
          properties:
            name: {type: string}
            email: {type: string}
            password: {type: string}
            phone: {type: string}
    responses:
      201:
        description: Admin created successfully
      400:
        description: Validation error
    """
    from controllers.admin_controller import create_admin_controller
    return create_admin_controller()

# ── UNIVERSAL USER CRUD ──────────────────────────────────────────────────────

@admin_routes.route("/users/<uid>/toggle", methods=["POST"])
@login_required
@role_required("super_admin", "admin")
def toggle_user(uid):
    """
    Admin: Toggle user account status (Disable/Enable).
    ---
    tags: [Admin]
    parameters:
      - name: uid
        in: path
        required: true
        type: string
      - in: body
        name: body
        schema:
          type: object
          properties:
            disabled: {type: boolean, default: true}
    responses:
      200:
        description: Status updated
    """
    from controllers.admin_controller import toggle_user_status
    return toggle_user_status(uid)

@admin_routes.route("/users/<uid>/delete", methods=["POST"])
@login_required
@role_required("super_admin", "admin")
def delete_user(uid):
    """
    Admin: Permanently delete a user account.
    ---
    tags: [Admin]
    parameters:
      - name: uid
        in: path
        required: true
        type: string
    responses:
      200:
        description: User deleted
    """
    from controllers.admin_controller import delete_user_account
    return delete_user_account(uid)

# ── DOCTORS ──────────────────────────────────────────────────────────────────



@admin_routes.route("/doctors")
@login_required
@role_required("super_admin", "admin")
def doctors():
    """
    Admin: Doctors Directory.
    ---
    tags: [Admin]
    responses:
      200:
        description: Doctors list HTML
    """
    return render_template("admin/doctors.html", doctors=get_all_doctors())


@admin_routes.route("/doctors/create", methods=["GET"])
@login_required
@role_required("super_admin", "admin")
def create_doctor_page():
    return render_template("admin/create_doctor.html")


@admin_routes.route("/doctors/create", methods=["POST"])
@login_required
@role_required("super_admin", "admin")
def create_doctor():
    """
    Admin: Register a new Doctor.
    ---
    tags: [Admin]
    parameters:
      - in: body
        name: body
        schema:
          type: object
          required: [name, email, password, phone, specialization, employeeId]
          properties:
            name: {type: string}
            email: {type: string}
            password: {type: string}
            phone: {type: string}
            specialization: {type: string}
            employeeId: {type: string}
    responses:
      201:
        description: Doctor created
    """
    from controllers.doctor_controller import create_doctor_controller
    return create_doctor_controller()


@admin_routes.route("/counselors")
@login_required
@role_required("super_admin", "admin")
def counselors():
    """
    Admin: Counselors Directory.
    ---
    tags: [Admin]
    responses:
      200:
        description: Counselors list HTML
    """
    return render_template("admin/counselors.html", counselors=get_all_counselors())


@admin_routes.route("/counselors/create", methods=["GET"])
@login_required
@role_required("super_admin", "admin")
def create_counselor_page():
    return render_template("admin/create_counselor.html")


@admin_routes.route("/counselors/create", methods=["POST"])
@login_required
@role_required("super_admin", "admin")
def create_counselor():
    """
    Admin: Register a new Counselor.
    ---
    tags: [Admin]
    parameters:
      - in: body
        name: body
        schema:
          type: object
          required: [name, email, password, phone, bio, employeeId]
          properties:
            name: {type: string}
            email: {type: string}
            password: {type: string}
            phone: {type: string}
            bio: {type: string}
            employeeId: {type: string}
    responses:
      201:
        description: Counselor created
    """
    from controllers.counselor_controller import create_counselor_controller
    return create_counselor_controller()


@admin_routes.route("/patients")
@login_required
@role_required("super_admin", "admin")
def patients():
    """
    Admin: Patients Directory.
    ---
    tags: [Admin]
    responses:
      200:
        description: Patients list HTML
    """
    from models.guardian_model import get_guardian_by_patient
    patients_list = get_all_patients()
    for p in patients_list:
        p["guardian"] = get_guardian_by_patient(p.get("uid", ""))
        if p.get("assignedDoctor"):
            doc = db.collection("users").document(p["assignedDoctor"]).get()
            p["assignedDoctorName"] = doc.to_dict().get("name", "—") if doc.exists else "—"
        else:
            p["assignedDoctorName"] = None
    return render_template("admin/patients.html", patients=patients_list)


@admin_routes.route("/patients/create", methods=["GET"])
@login_required
@role_required("super_admin", "admin")
def create_patient_page():
    doctors = get_users_by_role("doctor")
    return render_template("admin/create_patient.html", doctors=doctors)


@admin_routes.route("/patients/create", methods=["POST"])
@login_required
@role_required("super_admin", "admin")
def create_patient():
    """
    Admin: Register a new Patient and optionally assign a Doctor.
    ---
    tags: [Admin]
    parameters:
      - in: body
        name: body
        schema:
          type: object
          required: [name, email, password, phone, gender, dob]
          properties:
            name: {type: string}
            email: {type: string}
            password: {type: string}
            phone: {type: string}
            gender: {type: string}
            dob: {type: string}
            assignedDoctor: {type: string}
    responses:
      201:
        description: Patient created
    """
    from controllers.patient_controller import create_patient_controller
    return create_patient_controller()


@admin_routes.route("/patients/assign-doctor", methods=["GET"])
@login_required
@role_required("super_admin", "admin")
def assign_doctor_page():
    return render_template(
        "admin/assign_doctor.html",
        patients=get_all_patients(),
        doctors=get_users_by_role("doctor"),
    )


@admin_routes.route("/patients/assign-doctor", methods=["POST"])
@login_required
@role_required("super_admin", "admin")
def assign_doctor():
    """
    Admin: Link a Patient to a specific Doctor.
    ---
    tags: [Admin]
    parameters:
      - in: body
        name: body
        schema:
          type: object
          required: [patientUid, doctorUid]
          properties:
            patientUid: {type: string}
            doctorUid: {type: string}
    responses:
      200:
        description: Doctor assigned
    """
    from controllers.patient_controller import assign_doctor_controller
    return assign_doctor_controller()


@admin_routes.route("/analytics")
@login_required
@role_required("super_admin", "admin")
def analytics():
    """
    Admin: XAI Analytics Overview — all patients.
    ---
    tags: [Admin, Analytics]
    responses:
      200:
        description: Analytics overview HTML
    """
    from services.xai_analysis_service import analyze_all_patient_xai
    summaries = analyze_all_patient_xai(persist=True, notify=False)
    return render_template("admin/analytics.html", summaries=summaries)


@admin_routes.route("/analytics/<patient_uid>")
@login_required
@role_required("super_admin", "admin")
def analytics_detail(patient_uid):
    """
    Admin: XAI Analytics Detail — single patient.
    ---
    tags: [Admin, Analytics]
    parameters:
      - name: patient_uid
        in: path
        required: true
        schema:
          type: string
    responses:
      200:
        description: Patient XAI detail HTML
    """
    from services.xai_analysis_service import analyze_patient_xai
    summary = analyze_patient_xai(patient_uid, persist=True, notify=False)
    if not summary.get("patientName"):
        p = db.collection("patients").document(patient_uid).get()
        summary["patientName"] = p.to_dict().get("name", "Unknown") if p.exists else "Unknown"
    return render_template("admin/analytics_detail.html", summary=summary)


@admin_routes.route("/diary-reports")
@login_required
@role_required("super_admin", "admin")
def diary_reports():
    """
    Admin: Diary Analysis Overview — all patients.
    ---
    tags: [Admin, Analytics]
    responses:
      200:
        description: Diary reports HTML
    """
    from services.xai_analysis_service import analyze_all_patient_xai
    summaries = analyze_all_patient_xai(persist=True, notify=False)
    return render_template("admin/diary_reports.html", summaries=summaries)


@admin_routes.route("/diary-reports/<patient_uid>")
@login_required
@role_required("super_admin", "admin")
def diary_report_detail(patient_uid):
    """
    Admin: Diary Analysis Detail — single patient.
    ---
    tags: [Admin, Analytics]
    parameters:
      - name: patient_uid
        in: path
        required: true
        schema:
          type: string
    responses:
      200:
        description: Diary detail HTML
    """
    from services.xai_analysis_service import analyze_patient_xai
    summary = analyze_patient_xai(patient_uid, persist=True, notify=False)
    if not summary.get("patientName"):
        p = db.collection("patients").document(patient_uid).get()
        summary["patientName"] = p.to_dict().get("name", "Unknown") if p.exists else "Unknown"
    return render_template("admin/diary_report_detail.html", summary=summary)


@admin_routes.route("/notifications")
@login_required
@role_required("super_admin", "admin")
def notifications():
    """
    Admin: Notification Trigger Panel.
    ---
    tags: [Admin]
    responses:
      200:
        description: Notification panel HTML
    """
    patients = get_all_patients()
    return render_template("admin/notifications.html", patients=patients)


@admin_routes.route("/api-console")
@login_required
@role_required("super_admin", "admin")
def api_console():
    """
    Admin: Swagger API Console.
    ---
    tags: [Admin]
    responses:
      200:
        description: API console HTML
    """
    return render_template("admin/api_console.html")
