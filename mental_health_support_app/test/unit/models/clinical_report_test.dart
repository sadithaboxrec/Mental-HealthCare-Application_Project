import 'package:flutter_test/flutter_test.dart';
import 'package:mental_health_support_app/core/models/clinical_report.dart';

void main() {
  group('ClinicalReport', () {
    test('maps report payloads and builds the PDF endpoint', () {
      final report = ClinicalReport.fromMap({
        'id': 'report-1',
        'patientUid': 'patient-1',
        'patientName': 'Maya Perera',
        'doctorUid': 'doctor-1',
        'type': 'weekly',
        'startDate': '2026-04-21',
        'endDate': '2026-04-28',
        'generatedAt': '2026-04-28T08:00:00Z',
        'aggregatedSeverity': 'warning',
        'band': 2.0,
        'score': 6.5,
        'textConcernScore': 3,
        'confidence': 0.82,
        'summary': {'note': 'Needs review'},
        'moodTrend': [
          {'date': '2026-04-28', 'mood': 2},
        ],
        'adherenceSummary': {'missed': 1},
        'appointmentSummary': {'rescheduled': 2},
        'topDrivers': ['Low mood'],
        'themeCounts': {'low_mood': 2},
        'sourceBreakdown': {'daily_logs': 3},
        'evidence': ['Mood dropped'],
        'engineVersion': 'xai-1',
        'lexiconVersion': 'lex-1',
      });

      expect(report.patientUid, 'patient-1');
      expect(report.band, 2);
      expect(report.confidence, 0.82);
      expect(report.summary['note'], 'Needs review');
      expect(report.pdfUrl, contains('/api/clinical-reports/report-1/pdf'));
    });

    test('uses safe defaults for sparse report payloads', () {
      final report = ClinicalReport.fromMap({});

      expect(report.patientName, 'Unknown');
      expect(report.type, 'monthly');
      expect(report.aggregatedSeverity, 'stable');
      expect(report.band, 0);
      expect(report.confidence, 0);
      expect(report.evidence, isEmpty);
    });
  });
}
