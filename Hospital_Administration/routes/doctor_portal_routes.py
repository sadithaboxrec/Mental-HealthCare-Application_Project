from flask import Blueprint, Response, jsonify, render_template, request
from flask_login import current_user, login_required
from routes.auth_routes import role_required
from config import db
from services.clinical_report_service import (
    generate_clinical_report,
    get_report,
    list_patient_reports,
    record_report_export,
    report_to_pdf_bytes,
)
from services.xai_analysis_service import analyze_patient_xai

doctor_portal_routes = Blueprint("doctor_portal_routes", __name__, url_prefix="/portal")


def _parse_bool(value, default=True):
    if value is None:
        return default
    if isinstance(value, bool):
        return value
    return str(value).strip().lower() not in {"0", "false", "no", "off"}


def _patient_snapshot(patient_uid):
    snapshot_doc = db.collection("analytics_snapshots").document(patient_uid).get()
    if snapshot_doc.exists:
        return snapshot_doc.to_dict() or {}
    try:
        return analyze_patient_xai(patient_uid, persist=False, notify=False)
    except Exception as exc:
        print(f"XAI snapshot fallback failed for {patient_uid}: {exc}")
        return {}


@doctor_portal_routes.route("/")
@login_required
@role_required("doctor")
def portal_dashboard():
    """
    Doctor Portal: Dashboard — own patients with XAI severity.
    ---
    tags: [Doctor Portal]
    responses:
      200:
        description: Doctor dashboard HTML
    """
    doctor_uid = current_user.uid
    doctor_doc = db.collection("doctors").document(doctor_uid).get()
    if not doctor_doc.exists:
        doctor_doc = db.collection("users").document(doctor_uid).get()
    doctor = doctor_doc.to_dict() if doctor_doc.exists else {}
    doctor["uid"] = doctor_uid

    patients = []
    patient_docs = db.collection("patients").where("assignedDoctor", "==", doctor_uid).stream()
    for doc in patient_docs:
        patient = doc.to_dict()
        patient_uid = patient.get("uid", doc.id)
        snapshot = _patient_snapshot(patient_uid)
        alerts = list(
            db.collection("clinical_alerts")
            .where("patientUid", "==", patient_uid)
            .where("status", "==", "open")
            .stream()
        )
        patients.append({
            "uid":            patient_uid,
            "name":           patient.get("name", "Unknown Patient"),
            "email":          patient.get("email", ""),
            "gender":         patient.get("gender", ""),
            "dob":            patient.get("dob", ""),
            "severity":       snapshot.get("severity", "stable"),
            "score":          snapshot.get("score", 0),
            "confidence":     snapshot.get("confidence", 0),
            "primaryDrivers": snapshot.get("primaryDrivers", [])[:3],
            "openAlertCount": len(alerts),
            "lastEntryAt":    snapshot.get("lastEntryAt"),
        })
    patients.sort(
        key=lambda p: (
            {"critical": 3, "warning": 2, "watch": 1, "stable": 0}.get(p["severity"], 0),
            p["score"],
        ),
        reverse=True,
    )
    return render_template("portal/dashboard.html", doctor=doctor, patients=patients)


@doctor_portal_routes.route("/patients/<patient_uid>")
@login_required
@role_required("doctor")
def patient_detail(patient_uid):
    """
    Doctor Portal: Patient XAI Detail.
    ---
    tags: [Doctor Portal]
    parameters:
      - name: patient_uid
        in: path
        required: true
        schema:
          type: string
    responses:
      200:
        description: Patient detail HTML
      403:
        description: Patient not assigned to this doctor
    """
    # Scope check — ensure this patient belongs to the logged-in doctor
    patient_doc = db.collection("patients").document(patient_uid).get()
    if not patient_doc.exists:
        return render_template("404.html"), 404
    patient = patient_doc.to_dict()
    if patient.get("assignedDoctor") != current_user.uid:
        return render_template("403.html"), 403

    summary = _patient_snapshot(patient_uid)
    if not summary.get("patientName"):
        summary["patientName"] = patient.get("name", "Unknown")

    reports = list_patient_reports(patient_uid, limit=10)
    return render_template(
        "portal/patient_detail.html",
        patient=patient,
        summary=summary,
        reports=reports,
    )


@doctor_portal_routes.route("/patients/<patient_uid>/report")
@login_required
@role_required("doctor")
def patient_report(patient_uid):
    """
    Doctor Portal: Generate/View Clinical Report.
    ---
    tags: [Doctor Portal]
    parameters:
      - name: patient_uid
        in: path
        required: true
        schema:
          type: string
      - name: type
        in: query
        schema:
          type: string
          enum: [daily, weekly, monthly, yearly, custom]
      - name: startDate
        in: query
        schema:
          type: string
          format: date
      - name: endDate
        in: query
        schema:
          type: string
          format: date
    responses:
      200:
        description: Clinical report HTML
      403:
        description: Patient not assigned to this doctor
    """
    patient_doc = db.collection("patients").document(patient_uid).get()
    if not patient_doc.exists:
        return render_template("404.html"), 404
    patient = patient_doc.to_dict()
    if patient.get("assignedDoctor") != current_user.uid:
        return render_template("403.html"), 403

    report_type = request.args.get("type", "monthly")
    start_date  = request.args.get("startDate")
    end_date    = request.args.get("endDate")
    persist     = _parse_bool(request.args.get("persist"), default=True)

    report  = generate_clinical_report(patient_uid, report_type=report_type, start_date=start_date, end_date=end_date, persist=persist)
    reports = list_patient_reports(patient_uid)
    return render_template(
        "portal/patient_report.html",
        doctor_uid = current_user.uid,
        patient    = patient,
        report     = report,
        reports    = reports,
    )


@doctor_portal_routes.route("/reports/<report_id>/pdf")
@login_required
@role_required("doctor")
def report_pdf(report_id):
    """
    Doctor Portal: Export Clinical Report as PDF.
    ---
    tags: [Doctor Portal]
    parameters:
      - name: report_id
        in: path
        required: true
        schema:
          type: string
    responses:
      200:
        description: PDF file download
      404:
        description: Report not found
    """
    report = get_report(report_id)
    if report is None:
        return jsonify({"error": "Report not found"}), 404
    record_report_export(report_id, report.get("patientUid"), "pdf")
    pdf = report_to_pdf_bytes(report)
    return Response(
        pdf,
        mimetype="application/pdf",
        headers={"Content-Disposition": f"attachment; filename=clinical-report-{report_id}.pdf"},
    )
