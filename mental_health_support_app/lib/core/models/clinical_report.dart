
import 'dart:convert';

import 'package:mental_health_support_app/core/services/api_service.dart';

class ClinicalReport {

  final String id;
  final String patientUid;
  final String patientName;
  final String? doctorUid;
  final String type; // daily , weekly , monthly , yearly , custom
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

  const ClinicalReport ( {

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

  } );

  // Coerces any value to Map<String, dynamic>: passes Maps through,
  // JSON-decodes Strings, and falls back to {} for anything else.
  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is String) {
      try {
        final decoded = jsonDecode(v);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  // Coerces any value to List<dynamic>: passes Lists through,
  // JSON-decodes Strings, and falls back to [] for anything else.
  static List<dynamic> _asList(dynamic v) {
    if (v is List) return v;
    if (v is String) {
      try {
        final decoded = jsonDecode(v);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
    return [];
  }

  factory ClinicalReport.fromMap( Map<String , dynamic> m ) {

    return ClinicalReport (

      id : m[ 'id' ] as String? ?? '',
      patientUid : m[ 'patientUid' ] as String? ?? '',
      patientName : m[ 'patientName' ] as String? ?? 'Unknown',
      doctorUid : m[ 'doctorUid' ] as String?,
      type : m[ 'type' ] as String? ?? 'monthly',
      startDate : m[ 'startDate' ] as String? ?? '',
      endDate : m[ 'endDate' ] as String? ?? '',
      generatedAt : m[ 'generatedAt' ] is String
          ? m[ 'generatedAt' ] as String
          : m[ 'generatedAt' ]?.toString() ?? '',
      aggregatedSeverity : m[ 'aggregatedSeverity' ] as String? ?? 'stable',
      band : ( m[ 'band' ] as num? )?.toInt( ) ?? 0,
      score : m[ 'score' ] as num? ?? 0,
      textConcernScore : m[ 'textConcernScore' ] as num? ?? 0,
      confidence : ( m[ 'confidence' ] as num? )?.toDouble( ) ?? 0.0,
      summary : _asMap( m[ 'summary' ] ),
      moodTrend : _asList( m[ 'moodTrend' ] ),
      adherenceSummary : _asMap( m[ 'adherenceSummary' ] ),
      appointmentSummary : _asMap( m[ 'appointmentSummary' ] ),
      topDrivers : _asList( m[ 'topDrivers' ] ),
      themeCounts : _asMap( m[ 'themeCounts' ] ),
      sourceBreakdown : _asMap( m[ 'sourceBreakdown' ] ),
      evidence : _asList( m[ 'evidence' ] ),
      engineVersion : m[ 'engineVersion' ] as String?,
      lexiconVersion : m[ 'lexiconVersion' ] as String?,

    );

  }

  String get pdfUrl => '${ApiService.backendBaseUrl}/api/clinical-reports/$id/pdf';

}
