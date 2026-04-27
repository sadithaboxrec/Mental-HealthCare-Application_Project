import 'package:mental_health_support_app/core/services/api_service.dart';

/// Strongly-typed model for a clinical report returned by the backend.
class ClinicalReport {
  final String id;
  final String patientUid;
  final String patientName;
  final String? doctorUid;
  final String type; // daily | weekly | monthly | yearly | custom
  final String startDate;
  final String endDate;
  final String generatedAt;
  final String aggregatedSeverity;
  final int band;
  final num score;
  final num textConcernScore;
  final double confidence;
  final Map<String, dynamic> summary;
  final List<dynamic> moodTrend;
  final Map<String, dynamic> adherenceSummary;
  final Map<String, dynamic> appointmentSummary;
  final List<dynamic> topDrivers;
  final Map<String, dynamic> themeCounts;
  final Map<String, dynamic> sourceBreakdown;
  final List<dynamic> evidence;
  final String? engineVersion;
  final String? lexiconVersion;

  const ClinicalReport({
    required this.id,
    required this.patientUid,
    required this.patientName,
    this.doctorUid,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.generatedAt,
    required this.aggregatedSeverity,
    required this.band,
    required this.score,
    required this.textConcernScore,
    required this.confidence,
    required this.summary,
    required this.moodTrend,
    required this.adherenceSummary,
    required this.appointmentSummary,
    required this.topDrivers,
    required this.themeCounts,
    required this.sourceBreakdown,
    required this.evidence,
    this.engineVersion,
    this.lexiconVersion,
  });

  factory ClinicalReport.fromMap(Map<String, dynamic> m) {
    return ClinicalReport(
      id: m['id'] as String? ?? '',
      patientUid: m['patientUid'] as String? ?? '',
      patientName: m['patientName'] as String? ?? 'Unknown',
      doctorUid: m['doctorUid'] as String?,
      type: m['type'] as String? ?? 'monthly',
      startDate: m['startDate'] as String? ?? '',
      endDate: m['endDate'] as String? ?? '',
      generatedAt: m['generatedAt'] as String? ?? '',
      aggregatedSeverity: m['aggregatedSeverity'] as String? ?? 'stable',
      band: (m['band'] as num?)?.toInt() ?? 0,
      score: m['score'] as num? ?? 0,
      textConcernScore: m['textConcernScore'] as num? ?? 0,
      confidence: (m['confidence'] as num?)?.toDouble() ?? 0.0,
      summary: m['summary'] as Map<String, dynamic>? ?? {},
      moodTrend: m['moodTrend'] as List<dynamic>? ?? [],
      adherenceSummary: m['adherenceSummary'] as Map<String, dynamic>? ?? {},
      appointmentSummary:
      m['appointmentSummary'] as Map<String, dynamic>? ?? {},
      topDrivers: m['topDrivers'] as List<dynamic>? ?? [],
      themeCounts: m['themeCounts'] as Map<String, dynamic>? ?? {},
      sourceBreakdown: m['sourceBreakdown'] as Map<String, dynamic>? ?? {},
      evidence: m['evidence'] as List<dynamic>? ?? [],
      engineVersion: m['engineVersion'] as String?,
      lexiconVersion: m['lexiconVersion'] as String?,
    );
  }

  String get pdfUrl =>
      '${ApiService.backendBaseUrl}/api/clinical-reports/$id/pdf';
}
