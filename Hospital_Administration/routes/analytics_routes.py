from flask import Blueprint, jsonify, render_template, request

from services.diary_analysis_service import (
    analyze_all_patient_diaries,
    analyze_patient_diary,
)


analytics_routes = Blueprint("analytics_routes", __name__)


@analytics_routes.route("/diary-reports", methods=["GET"])
def diary_reports_page():
    summaries = analyze_all_patient_diaries(
        persist=False,
        notify=False,
    )
    return render_template("diary_reports.html", summaries=summaries)


@analytics_routes.route("/diary-reports/<patient_uid>", methods=["GET"])
def diary_report_detail_page(patient_uid):
    summary = analyze_patient_diary(
        patient_uid,
        persist=False,
        notify=False,
    )
    return render_template("diary_report_detail.html", summary=summary)


@analytics_routes.route("/analytics/diary", methods=["GET"])
def all_diary_analysis_summaries():
    summaries = analyze_all_patient_diaries(
        persist=False,
        notify=False,
    )
    return jsonify(summaries), 200


@analytics_routes.route("/analytics/diary/<patient_uid>", methods=["GET"])
def diary_analysis_summary(patient_uid):
    summary = analyze_patient_diary(
        patient_uid,
        persist=False,
        notify=False,
    )
    return jsonify(summary), 200


@analytics_routes.route("/analytics/diary/<patient_uid>/recompute", methods=["POST"])
def recompute_diary_analysis(patient_uid):
    data = request.json or {}
    notify = bool(data.get("notify", False))

    summary = analyze_patient_diary(
        patient_uid,
        persist=True,
        notify=notify,
    )
    return jsonify(summary), 200
