from flask import Blueprint, render_template
from controllers.patient_controller import (
    create_patient_controller,
    assign_doctor_controller
)
from models.patient_model import get_all_patients
from models.guardian_model import get_guardian_by_patient
from models.doctor_model import get_all_doctors
from models.user_model import get_users_by_role

patient_routes = Blueprint("patient_routes", __name__)

@patient_routes.route("/patients")
def patients_page():
    patients  = get_all_patients()
    # attach guardian to each patient
    for p in patients:
        p["guardian"] = get_guardian_by_patient(p["uid"])
        # attach doctor name
        if p.get("assignedDoctor"):
            from config import db
            doc = db.collection("users")\
                    .document(p["assignedDoctor"]).get()
            p["doctorName"] = doc.to_dict().get("name", "—") \
                              if doc.exists else "—"
        else:
            p["doctorName"] = "Not assigned"
    return render_template("patients.html", patients=patients)

@patient_routes.route("/create-patient", methods=["GET"])
def create_patient_page():
    doctors = get_users_by_role("doctor")
    return render_template("create_patient.html", doctors=doctors)

@patient_routes.route("/create-patient", methods=["POST"])
def create_patient():
    return create_patient_controller()

@patient_routes.route("/assign-doctor", methods=["GET"])
def assign_doctor_page():
    from config import db
    patients = get_all_patients()
    doctors  = get_users_by_role("doctor")
    return render_template("assign_doctor.html",
                           patients=patients, doctors=doctors)

@patient_routes.route("/assign-doctor", methods=["POST"])
def assign_doctor():
    return assign_doctor_controller()