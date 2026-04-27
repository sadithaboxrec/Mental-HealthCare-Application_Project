from datetime import datetime, timedelta, timezone

from config import db
from services.appointment_analysis_service import fetch_appointments, fetch_reschedule_requests
from services.daily_log_analysis_service import fetch_daily_logs
from services.guardian_analysis_service import fetch_guardian_logs
from services.xai_analysis_service import analyze_patient_xai
from services.xai_utils import now_utc, parse_datetime


def _date_str(value):
    return value.date().isoformat()


def _parse_date(value):
    parsed = parse_datetime(value)
    if parsed:
        return parsed
    return None


def resolve_report_range(report_type, start_date=None, end_date=None):
    end = _parse_date(end_date) or now_utc()
    report_type = (report_type or "monthly").lower()
    if report_type == "daily":
        start = end.replace(hour=0, minute=0, second=0, microsecond=0)
    elif report_type == "weekly":
        start = end - timedelta(days=7)
    elif report_type == "yearly":
        start = end - timedelta(days=365)
    elif report_type == "custom":
        start = _parse_date(start_date) or (end - timedelta(days=30))
    else:
        report_type = "monthly"
        start = end - timedelta(days=30)
    if start > end:
        start, end = end, start
    return report_type, start, end


def _patient_doc(patient_uid):
    doc = db.collection("patients").document(patient_uid).get()
    if not doc.exists:
        return {}
    return doc.to_dict()


def _adherence_summary(daily_logs):
    logs = [log for log in daily_logs if "medicationTaken" in log]
    if not logs:
        return {
            "trackedDays": 0,
            "takenDays": 0,
            "missedDays": 0,
            "adherencePercent": None,
        }
    taken = len([log for log in logs if log.get("medicationTaken") is True])
    missed = len([log for log in logs if log.get("medicationTaken") is False])
    return {
        "trackedDays": len(logs),
        "takenDays": taken,
        "missedDays": missed,
        "adherencePercent": round((taken / len(logs)) * 100, 1),
    }


def _appointment_summary(appointments, reschedules):
    by_status = {}
    for item in appointments:
        status = item.get("status", "scheduled")
        by_status[status] = by_status.get(status, 0) + 1
    return {
        "total": len(appointments),
        "byStatus": by_status,
        "rescheduleRequests": len(reschedules),
    }


def _mood_trend(daily_logs):
    trend = []
    for log in daily_logs:
        mood = log.get("mood")
        if mood is None:
            continue
        trend.append({
            "date": log.get("date", ""),
            "mood": mood,
            "sleepHours": log.get("sleepHours", ""),
            "medicationTaken": log.get("medicationTaken"),
        })
    return trend


def generate_clinical_report(patient_uid, report_type="monthly", start_date=None, end_date=None, persist=True):
    report_type, start, end = resolve_report_range(report_type, start_date, end_date)
    patient = _patient_doc(patient_uid)
    doctor_uid = patient.get("assignedDoctor")
    xai_summary = analyze_patient_xai(patient_uid, persist=True, notify=False)

    daily_logs = fetch_daily_logs(patient_uid, start, end)
    guardian_logs = fetch_guardian_logs(patient_uid, start, end)
    appointments = fetch_appointments(patient_uid, start, end)
    reschedules = fetch_reschedule_requests(patient_uid, start, end)

    report = {
        "patientUid": patient_uid,
        "patientName": patient.get("name", "Unknown Patient"),
        "doctorUid": doctor_uid,
        "type": report_type,
        "startDate": _date_str(start),
        "endDate": _date_str(end),
        "generatedAt": now_utc().isoformat(),
        "aggregatedSeverity": xai_summary.get("severity", "stable"),
        "band": xai_summary.get("band", 0),
        "score": xai_summary.get("score", 0),
        "confidence": xai_summary.get("confidence", 0),
        "summary": {
            "action": xai_summary.get("action"),
            "screeningNote": xai_summary.get("screeningNote"),
            "entryCount": xai_summary.get("entryCount", 0),
            "chatMessageCount": xai_summary.get("chatMessageCount", 0),
            "guardianObservationCount": xai_summary.get("guardianObservationCount", 0),
            "behavioralSignalCount": xai_summary.get("behavioralSignalCount", 0),
        },
        "scoreTrend": [{
            "date": _date_str(end),
            "score": xai_summary.get("score", 0),
            "severity": xai_summary.get("severity", "stable"),
        }],
        "moodTrend": _mood_trend(daily_logs),
        "adherenceSummary": _adherence_summary(daily_logs),
        "appointmentSummary": _appointment_summary(appointments, reschedules),
        "guardianLogCount": len(guardian_logs),
        "topDrivers": xai_summary.get("primaryDrivers", [])[:10],
        "themeCounts": xai_summary.get("themeCounts", {}),
        "sourceBreakdown": xai_summary.get("sourceBreakdown", {}),
        "evidence": xai_summary.get("evidence", [])[:10],
        "pdfUrl": None,
        "engineVersion": xai_summary.get("engineVersion"),
        "lexiconVersion": xai_summary.get("lexiconVersion"),
    }

    if persist:
        ref = db.collection("clinical_reports").add(report)
        report["id"] = ref[1].id
    return report


def list_patient_reports(patient_uid, limit=20):
    reports = []
    try:
        snap = (
            db.collection("clinical_reports")
            .where("patientUid", "==", patient_uid)
            .stream()
        )
        for doc in snap:
            data = doc.to_dict()
            data["id"] = doc.id
            reports.append(data)
    except Exception:
        return []
    reports.sort(key=lambda item: item.get("generatedAt", ""), reverse=True)
    return reports[:limit]


def get_report(report_id):
    doc = db.collection("clinical_reports").document(report_id).get()
    if not doc.exists:
        return None
    data = doc.to_dict()
    data["id"] = doc.id
    return data


def record_report_export(report_id, patient_uid, export_type="pdf"):
    payload = {
        "reportId": report_id,
        "patientUid": patient_uid,
        "exportType": export_type,
        "delivery": "direct_response",
        "createdAt": datetime.now(timezone.utc).isoformat(),
    }
    ref = db.collection("report_exports").add(payload)
    payload["id"] = ref[1].id
    return payload


def report_to_pdf_bytes(report):
    lines = [
        "MindCare Clinical Report",
        f"Patient: {report.get('patientName', 'Unknown Patient')}",
        f"Patient UID: {report.get('patientUid', '')}",
        f"Range: {report.get('startDate', '')} to {report.get('endDate', '')}",
        f"Generated: {report.get('generatedAt', '')}",
        "",
        f"Severity: {report.get('aggregatedSeverity', 'stable')}",
        f"Score: {report.get('score', 0)}",
        f"Confidence: {report.get('confidence', 0)}",
        "",
        "Top Drivers:",
    ]
    drivers = report.get("topDrivers", [])[:8]
    if drivers:
        for driver in drivers:
            lines.append(f"- {driver.get('displayName') or driver.get('theme')}: {driver.get('evidenceSnippet', '')}")
    else:
        lines.append("- No high-priority XAI drivers in this range.")

    lines.extend(["", "Adherence:"])
    adherence = report.get("adherenceSummary", {})
    lines.append(
        f"Tracked days: {adherence.get('trackedDays', 0)}, "
        f"taken: {adherence.get('takenDays', 0)}, missed: {adherence.get('missedDays', 0)}, "
        f"percent: {adherence.get('adherencePercent')}"
    )

    lines.extend(["", "Screening note:", report.get("summary", {}).get("screeningNote", "")])
    return _minimal_pdf(lines)


def _minimal_pdf(lines):
    escaped_lines = [_escape_pdf_text(line) for line in lines]
    text_ops = ["BT", "/F1 11 Tf", "50 780 Td"]
    for index, line in enumerate(escaped_lines):
        if index:
            text_ops.append("0 -16 Td")
        text_ops.append(f"({line}) Tj")
    text_ops.append("ET")
    stream = "\n".join(text_ops)
    objects = [
        "<< /Type /Catalog /Pages 2 0 R >>",
        "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>",
        "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
        f"<< /Length {len(stream.encode('utf-8'))} >>\nstream\n{stream}\nendstream",
    ]
    output = "%PDF-1.4\n"
    offsets = [0]
    for idx, obj in enumerate(objects, start=1):
        offsets.append(len(output.encode("utf-8")))
        output += f"{idx} 0 obj\n{obj}\nendobj\n"
    xref_offset = len(output.encode("utf-8"))
    output += f"xref\n0 {len(objects) + 1}\n0000000000 65535 f \n"
    for offset in offsets[1:]:
        output += f"{offset:010d} 00000 n \n"
    output += (
        f"trailer\n<< /Size {len(objects) + 1} /Root 1 0 R >>\n"
        f"startxref\n{xref_offset}\n%%EOF"
    )
    return output.encode("utf-8")


def _escape_pdf_text(value):
    return str(value).replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")[:120]
