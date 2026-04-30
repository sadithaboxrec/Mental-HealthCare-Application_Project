
import requests as _http
from datetime import datetime, timedelta

from flask import Flask, jsonify, redirect, url_for
from flasgger import Swagger
from flask_login import login_required

from config import db
from routes.auth_routes import auth_routes, login_manager, role_required
from routes.admin_routes import admin_routes
from routes.doctor_portal_routes import doctor_portal_routes
from routes.analytics_routes import analytics_routes
from routes.notification_routes import (
    
    notification_routes,
    run_medication_reminders,
    run_appointment_reminders,
    
)

from apscheduler.schedulers.background import BackgroundScheduler

# App
app = Flask ( __name__ )
app.secret_key = "mindcare-admin-secret-key"

# Flask Login
login_manager.init_app ( app )

# Flasgger
swagger_config = {
    
    "headers" : [ ],
    "specs" : [
        
        {
            
            "endpoint" : "apispec",
            "route" : "/apispec.json",
            "rule_filter" : lambda rule : True,
            "model_filter" : lambda tag : True,
            
        }
        
    ],
    "static_url_path" : "/flasgger_static",
    "swagger_ui" : True,
    "specs_route" : "/swagger/",
    
}

swagger_template = {
    
    "swagger" : "2.0",
    "info" : {
        
        "title" : "MindCare Hospital API",
        "description" : (
            
            "Backend API for the MindCare Hospital Administration platform. "
            "Covers clinical analytics, notifications, patient management, and clinical reports."
            
        ),
        "version" : "1.0.0",
        "contact" : { "email" : "admin@mindcare.io" },
    },
    "host" : "localhost:5000",
    "basePath" : "/",
    "schemes" : [ "http" ],
    "tags" : [
        
        { "name" : "Admin" , "description" : "Admin-only dashboard and management" },
        { "name" : "Doctor Portal" , "description" : "Doctor portal — own patients only" },
        { "name" : "Analytics" , "description" : "XAI and diary clinical analytics" },
        { "name" : "Notifications" , "description" : "FCM push notification triggers" },
        { "name" : "Clinical Reports" , "description" : "Clinical report generation and export" },
        
    ],
}

swagger = Swagger ( app , config=swagger_config , template=swagger_template )

@app.context_processor
def inject_now ( ) :
    return { "now" : datetime.now }

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "service": "MindCare API"}), 200

@app.route("/")
def index():
    return redirect(url_for("auth_routes.login"))

# Error Pages
@app.errorhandler ( 403 )
def forbidden ( e ):
    from flask import render_template
    return render_template ( "403.html" ) , 403

@app.errorhandler ( 404 )
def not_found ( e ):
    from flask import render_template
    return render_template ( "404.html" ) , 404

app.register_blueprint ( auth_routes )
app.register_blueprint ( admin_routes )
app.register_blueprint ( doctor_portal_routes )
app.register_blueprint ( analytics_routes )
app.register_blueprint ( notification_routes )

# Scheduler
scheduler = BackgroundScheduler ( )

scheduler.add_job ( run_medication_reminders , "cron" , hour = 8 , minute = 0 )
scheduler.add_job ( run_medication_reminders , "cron" , hour = 13 , minute = 0 )
scheduler.add_job ( run_medication_reminders , "cron" , hour = 21 , minute = 0 ) 
scheduler.add_job ( run_appointment_reminders , "cron" , hour = 21 , minute = 0 )

scheduler.add_job(
    
    lambda : _http.post ( "http://localhost:5000/trigger/water" , timeout = 5 ),
    "cron" , hour=9 , minute=0,
    
)
scheduler.add_job(
    
    lambda : _http.post ( "http://localhost:5000/trigger/water" , timeout = 5 ),
    "cron" , hour = 14 , minute = 0,
)
scheduler.add_job(
    
    lambda : _http.post ( "http://localhost:5000/trigger/water" , timeout = 5 ),
    "cron" , hour = 19 , minute = 0,
    
)
scheduler.add_job(
    
    lambda : _http.post ( "http://localhost:5000/trigger/diary" , timeout = 5 ),
    "cron" , hour=20 , minute = 0,
    
)

scheduler.start ( )
print ( "Scheduler started" )

if __name__ == "__main__":
    app.run ( debug = True )
