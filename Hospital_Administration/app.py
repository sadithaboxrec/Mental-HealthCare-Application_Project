from flask import Flask, render_template
from config import db
from routes.doctor_routes   import doctor_routes
from routes.counselor_routes import counselor_routes
from routes.patient_routes  import patient_routes

app = Flask(__name__)

app.register_blueprint(doctor_routes)
app.register_blueprint(counselor_routes)
app.register_blueprint(patient_routes)

@app.route("/")
def dashboard():
    from models.user_model import get_users_by_role
    doctors    = get_users_by_role("doctor")
    counselors = get_users_by_role("counselor")
    patients   = get_users_by_role("patient")
    return render_template("dashboard.html",
                           doctors=doctors,
                           counselors=counselors,
                           patients=patients)

if __name__ == "__main__":
    app.run(debug=True)