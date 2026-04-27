import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mental_health_support_app/core/models/clinical_report.dart';
import 'package:mental_health_support_app/core/services/api_service.dart';

/// Maps human-readable Flutter UI labels to backend report type keys.
const _reportTypeMap = {
  'Daily Log': 'daily',
  'Weekly Summary': 'weekly',
  'Monthly Review': 'monthly',
  'Yearly Review': 'yearly',
  'Custom Range': 'custom',
};

class ReportService {
  ReportService._();

  /// Generate a clinical report via the backend API.
  /// [reportTypeLabel] is the UI label (e.g. "Weekly Summary").
  /// [startDate] and [endDate] are only used when [reportTypeLabel] == "Custom Range".
  static Future<ClinicalReport> generateReport({
    required String patientUid,
    required String reportTypeLabel,
    String? startDate,
    String? endDate,
  }) async {
    final backendType = _reportTypeMap[reportTypeLabel] ?? 'monthly';
    final body = <String, dynamic>{'type': backendType, 'persist': true};
    if (startDate != null) body['startDate'] = startDate;
    if (endDate != null) body['endDate'] = endDate;

    final data = await ApiService.post(
      '/api/patients/$patientUid/clinical-report',
      body,
    );
    return ClinicalReport.fromMap(data);
  }

  /// List all clinical reports for a patient (from `clinical_reports` collection).
  static Future<List<ClinicalReport>> listReports(
    String patientUid, {
    int limit = 20,
  }) async {
    final snap = await FirebaseFirestore.instance
        .collection('clinical_reports')
        .where('patientUid', isEqualTo: patientUid)
        .orderBy('generatedAt', descending: true)
        .limit(limit)
        .get();

    return snap.docs
        .map((doc) => ClinicalReport.fromMap({'id': doc.id, ...doc.data()}))
        .toList();
  }

  /// Returns the full PDF download URL for a report.
  static String pdfUrl(String reportId) =>
      '${ApiService.backendBaseUrl}/api/clinical-reports/$reportId/pdf';
}
