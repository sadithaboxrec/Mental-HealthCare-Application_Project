from flask import Blueprint, jsonify, make_response, render_template, request
from flasgger import swag_from

from services.diary_analysis_service import (
    analyze_all_patient_diaries,
    analyze_patient_diary,
)
from services.xai_analysis_service import (
    analyze_all_patient_xai,
    analyze_patient_xai,
)

analytics_routes = Blueprint("analytics_routes", __name__)


@analytics_routes.route("/analytics/diary", methods=["GET"])
def all_diary_analysis_summaries():
    """
    Get diary analysis for all patients.
    ---
    tags: [Analytics]
    responses:
      200:
        description: List of diary analysis summaries
        schema:
          type: array
          items:
            type: object
    """
    summaries = analyze_all_patient_diaries(persist=True, notify=False)
    return jsonify(summaries), 200


@analytics_routes.route("/analytics/diary/<patient_uid>", methods=["GET"])
def diary_analysis_summary(patient_uid):
    """
    Get diary analysis for a specific patient.
    ---
    tags: [Analytics]
    parameters:
      - name: patient_uid
        in: path
        required: true
        schema:
          type: string
    responses:
      200:
        description: Diary analysis summary
    """
    summary = analyze_patient_diary(patient_uid, persist=True, notify=False)
    return jsonify(summary), 200


@analytics_routes.route("/analytics/diary/<patient_uid>/recompute", methods=["POST"])
def recompute_diary_analysis(patient_uid):
    """
    Recompute diary analysis for a specific patient.
    ---
    tags: [Analytics]
    parameters:
      - name: patient_uid
        in: path
        required: true
        schema:
          type: string
    requestBody:
      content:
        application/json:
          schema:
            type: object
            properties:
              notify:
                type: boolean
                default: false
    responses:
      200:
        description: Recomputed diary analysis summary
    """
    data   = request.json or {}
    notify = bool(data.get("notify", False))
    summary = analyze_patient_diary(patient_uid, persist=True, notify=notify)
    return jsonify(summary), 200


@analytics_routes.route("/analytics/xai", methods=["GET"])
def all_xai_analysis_summaries():
    """
    Get XAI analysis for all patients.
    ---
    tags: [Analytics]
    responses:
      200:
        description: List of XAI analysis summaries
        schema:
          type: array
          items:
            type: object
    """
    summaries = analyze_all_patient_xai(persist=True, notify=False)
    return jsonify(summaries), 200


@analytics_routes.route("/analytics/xai/<patient_uid>", methods=["GET"])
def xai_analysis_summary(patient_uid):
    """
    Get XAI analysis for a specific patient.
    ---
    tags: [Analytics]
    parameters:
      - name: patient_uid
        in: path
        required: true
        schema:
          type: string
    responses:
      200:
        description: XAI analysis summary
    """
    summary = analyze_patient_xai(patient_uid, persist=True, notify=False)
    return jsonify(summary), 200


@analytics_routes.route("/analytics/xai/<patient_uid>/recompute", methods=["POST"])
def recompute_xai_analysis(patient_uid):
    """
    Recompute XAI analysis for a specific patient.
    ---
    tags: [Analytics]
    parameters:
      - name: patient_uid
        in: path
        required: true
        schema:
          type: string
    requestBody:
      content:
        application/json:
          schema:
            type: object
            properties:
              notify:
                type: boolean
                default: false
    responses:
      200:
        description: Recomputed XAI analysis summary
    """
    data   = request.json or {}
    notify = bool(data.get("notify", False))
    summary = analyze_patient_xai(patient_uid, persist=True, notify=notify)
    return jsonify(summary), 200


@analytics_routes.route("/analytics/recompute-all", methods=["POST"])
def recompute_all_analysis():
    """
    Recompute XAI and diary analysis for ALL patients.
    ---
    tags: [Analytics]
    requestBody:
      content:
        application/json:
          schema:
            type: object
            properties:
              notify:
                type: boolean
                default: false
    responses:
      200:
        description: Counts of recomputed XAI and diary summaries
        schema:
          type: object
          properties:
            status:
              type: string
            xaiCount:
              type: integer
            diaryCount:
              type: integer
    """
    data   = request.json or {}
    notify = bool(data.get("notify", False))
    xai_summaries   = analyze_all_patient_xai(persist=True, notify=notify)
    diary_summaries = analyze_all_patient_diaries(persist=True, notify=notify)
    return jsonify({
        "status":     "done",
        "xaiCount":   len(xai_summaries),
        "diaryCount": len(diary_summaries),
        "xai":        xai_summaries,
        "diary":      diary_summaries,
    }), 200


@analytics_routes.route("/api/patients/<patient_uid>/clinical-report", methods=["POST"])
def clinical_report_api(patient_uid):
    """
    Generate a clinical report for a patient (API).
    ---
    tags: [Clinical Reports]
    parameters:
      - name: patient_uid
        in: path
        required: true
        schema:
          type: string
    requestBody:
      content:
        application/json:
          schema:
            type: object
            properties:
              type:
                type: string
                enum: [daily, weekly, monthly, yearly, custom]
                default: monthly
              startDate:
                type: string
                format: date
              endDate:
                type: string
                format: date
              persist:
                type: boolean
                default: true
    responses:
      201:
        description: Generated clinical report object
    """
    from services.clinical_report_service import generate_clinical_report
    data = request.json or {}
    def _parse_bool(v, default=True):
        if v is None: return default
        if isinstance(v, bool): return v
        return str(v).strip().lower() not in {"0", "false", "no", "off"}

    report = generate_clinical_report(
        patient_uid,
        report_type=data.get("type", "monthly"),
        start_date=data.get("startDate"),
        end_date=data.get("endDate"),
        persist=_parse_bool(data.get("persist"), default=True),
    )
    return jsonify(report), 201


@analytics_routes.route("/api/patients/<patient_uid>/clinical-reports", methods=["GET"])
def list_clinical_reports_api(patient_uid):
    """
    List clinical reports for a patient.
    ---
    tags: [Clinical Reports]
    parameters:
      - name: patient_uid
        in: path
        required: true
        schema:
          type: string
      - name: limit
        in: query
        required: false
        schema:
          type: integer
          default: 20
    responses:
      200:
        description: List of clinical report objects
    """
    from services.clinical_report_service import list_patient_reports
    limit = int(request.args.get("limit", 20))
    reports = list_patient_reports(patient_uid, limit=limit)
    return jsonify(reports), 200


@analytics_routes.route("/api/clinical-reports/<report_id>/pdf", methods=["GET"])
def download_clinical_report_pdf(report_id):
    """
    Download a clinical report as a PDF.
    ---
    tags: [Clinical Reports]
    parameters:
      - name: report_id
        in: path
        required: true
        schema:
          type: string
    responses:
      200:
        description: PDF file
        content:
          application/pdf:
            schema:
              type: string
              format: binary
      404:
        description: Report not found
    """
    from services.clinical_report_service import get_report, record_report_export, report_to_pdf_bytes
    report = get_report(report_id)
    if report is None:
        return jsonify({"error": "Report not found"}), 404
    patient_uid = report.get("patientUid", "unknown")
    record_report_export(report_id, patient_uid, export_type="pdf")
    pdf_bytes = report_to_pdf_bytes(report)
    patient_name = report.get("patientName", "report").replace(" ", "_")
    filename = f"MindCare_{patient_name}_{report.get('startDate', 'report')}.pdf"
    response = make_response(pdf_bytes)
    response.headers["Content-Type"] = "application/pdf"
    response.headers["Content-Disposition"] = f'attachment; filename="{filename}"'
    return response, 200
