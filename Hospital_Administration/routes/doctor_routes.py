from flask import Blueprint, render_template
from controllers.doctor_controller import create_doctor_controller
from models.doctor_model import get_all_doctors

doctor_routes = Blueprint("doctor_routes", __name__)

@doctor_routes.route("/doctors")
def doctors_page():
    doctors = get_all_doctors()
    return render_template("doctors.html", doctors=doctors)

@doctor_routes.route("/create-doctor", methods=["GET"])
def create_doctor_page():
    return render_template("create_doctor.html")

@doctor_routes.route("/create-doctor", methods=["POST"])
def create_doctor():
    return create_doctor_controller()