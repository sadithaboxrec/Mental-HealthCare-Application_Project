from flask import Flask, render_template
import requests
from config import db
from routes.doctor_routes   import doctor_routes
from routes.counselor_routes import counselor_routes
from routes.patient_routes  import patient_routes
from routes.analytics_routes import analytics_routes
from routes.notification_routes import notification_routes

# from testing of notifications
from datetime import datetime, timedelta

#notifications
from apscheduler.schedulers.background import BackgroundScheduler
from routes.notification_routes import (
    run_medication_reminders,
    run_appointment_reminders
)


app = Flask(__name__)


# notifications
app.register_blueprint(notification_routes)
app.register_blueprint(analytics_routes)

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







# ── Scheduler ─────────────────────────────────────────────
scheduler = BackgroundScheduler()

# Medication — 3 times daily
scheduler.add_job(run_medication_reminders, 'cron', hour=8,  minute=0)
scheduler.add_job(run_medication_reminders, 'cron', hour=13, minute=0)
scheduler.add_job(run_medication_reminders, 'cron', hour=21, minute=0)

# Appointments —  night at 9pm
scheduler.add_job(run_appointment_reminders, 'cron', hour=21, minute=0)



# Water  — 3 times a day
scheduler.add_job(
    lambda: requests.post('http://localhost:5000/trigger/water'),
    'cron', hour=9,  minute=0
)
scheduler.add_job(
    lambda: requests.post('http://localhost:5000/trigger/water'),
    'cron', hour=14, minute=0
)
scheduler.add_job(
    lambda: requests.post('http://localhost:5000/trigger/water'),
    'cron', hour=19, minute=0
)

# Diary  — once a day at 8pm
scheduler.add_job(
    lambda: requests.post('http://localhost:5000/trigger/diary'),
    'cron', hour=20, minute=0
)





scheduler.start()
print('Notification Scheduler started ')






test_time = datetime.now() + timedelta(minutes=0.3)
scheduler.add_job(
    run_medication_reminders,
    'date',
    run_date=test_time,
    id='test_immediate'
)
print(f'Test job fires at: {test_time}')

if __name__ == "__main__":
    app.run(debug=True)
