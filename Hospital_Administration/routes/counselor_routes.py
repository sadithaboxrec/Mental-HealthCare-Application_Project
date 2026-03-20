from flask import Blueprint, render_template
from controllers.counselor_controller import create_counselor_controller
from models.counselor_model import get_all_counselors

counselor_routes = Blueprint("counselor_routes", __name__)

@counselor_routes.route("/counselors")
def counselors_page():
    counselors = get_all_counselors()
    return render_template("counselors.html", counselors=counselors)

@counselor_routes.route("/create-counselor", methods=["GET"])
def create_counselor_page():
    return render_template("create_counselor.html")

@counselor_routes.route("/create-counselor", methods=["POST"])
def create_counselor():
    return create_counselor_controller()