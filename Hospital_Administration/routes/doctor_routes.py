from flask import Blueprint, Response, jsonify, render_template, request
from controllers.doctor_controller import create_doctor_controller
from models.doctor_model import get_all_doctors
from config import db
from services.clinical_report_service import (
    generate_clinical_report,
    get_report,
    list_patient_reports,
    record_report_export,
    report_to_pdf_bytes,
)

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


@doctor_routes.route("/doctor-dashboard")
def doctor_dashboard_index():
    doctors = get_all_doctors()
    return render_template("doctor_dashboard_index.html", doctors=doctors)


@doctor_routes.route("/doctor-dashboard/<doctor_uid>")
def doctor_dashboard(doctor_uid):
    doctor_doc = db.collection("doctors").document(doctor_uid).get()
    doctor = doctor_doc.to_dict() if doctor_doc.exists else {"uid": doctor_uid, "name": "Doctor"}
    patients = []
    patient_docs = db.collection("patients").where("assignedDoctor", "==", doctor_uid).stream()
    for doc in patient_docs:
        patient = doc.to_dict()
        patient_uid = patient.get("uid", doc.id)
        snapshot_doc = db.collection("analytics_snapshots").document(patient_uid).get()
        snapshot = snapshot_doc.to_dict() if snapshot_doc.exists else {}
        alerts = (
            db.collection("clinical_alerts")
            .where("patientUid", "==", patient_uid)
            .where("status", "==", "open")
            .stream()
        )
        open_alerts = [alert.to_dict() for alert in alerts]
        patients.append({
            "uid": patient_uid,
            "name": patient.get("name", "Unknown Patient"),
            "email": patient.get("email", ""),
            "severity": snapshot.get("severity", "stable"),
            "score": snapshot.get("score", 0),
            "confidence": snapshot.get("confidence", 0),
            "primaryDrivers": snapshot.get("primaryDrivers", [])[:3],
            "openAlertCount": len(open_alerts),
        })
    patients.sort(key=lambda item: (
        {"critical": 3, "warning": 2, "watch": 1, "stable": 0}.get(item["severity"], 0),
        item["score"],
    ), reverse=True)
    return render_template("doctor_dashboard.html", doctor=doctor, patients=patients)


@doctor_routes.route("/doctor-dashboard/<doctor_uid>/patients/<patient_uid>/report")
def doctor_patient_report(doctor_uid, patient_uid):
    report_type = request.args.get("type", "monthly")
    start_date = request.args.get("startDate")
    end_date = request.args.get("endDate")
    persist = request.args.get("persist", "1") != "0"
    report = generate_clinical_report(
        patient_uid,
        report_type=report_type,
        start_date=start_date,
        end_date=end_date,
        persist=persist,
    )
    reports = list_patient_reports(patient_uid)
    return render_template(
        "patient_report.html",
        doctor_uid=doctor_uid,
        report=report,
        reports=reports,
    )


@doctor_routes.route("/api/patients/<patient_uid>/clinical-report", methods=["POST"])
def clinical_report_api(patient_uid):
    data = request.json or {}
    report = generate_clinical_report(
        patient_uid,
        report_type=data.get("type", "monthly"),
        start_date=data.get("startDate"),
        end_date=data.get("endDate"),
        persist=bool(data.get("persist", True)),
    )
    return jsonify(report), 201


@doctor_routes.route("/clinical-reports/<report_id>/pdf")
def clinical_report_pdf(report_id):
    report = get_report(report_id)
    if report is None:
        return jsonify({"error": "Report not found"}), 404
    record_report_export(report_id, report.get("patientUid"), "pdf")
    pdf = report_to_pdf_bytes(report)
    filename = f"clinical-report-{report_id}.pdf"
    return Response(
        pdf,
        mimetype="application/pdf",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )
