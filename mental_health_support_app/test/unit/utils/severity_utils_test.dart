import 'package:flutter_test/flutter_test.dart';
import 'package:mental_health_support_app/core/utils/severity_utils.dart';

void main() {
  group('SeverityUtils', () {
    test('normalizes labels for clinical severity levels', () {
      expect(SeverityUtils.label('critical'), 'Critical');
      expect(SeverityUtils.label('warning'), 'Needs Review');
      expect(SeverityUtils.label('watch'), 'Watch');
      expect(SeverityUtils.label('stable'), 'Stable');
      expect(SeverityUtils.label('unknown'), 'Stable');
    });

    test('returns clinical action copy for each severity', () {
      expect(
        SeverityUtils.clinicalAction('critical'),
        'Urgent assessment required',
      );
      expect(
        SeverityUtils.clinicalAction('warning'),
        'Same-day review recommended',
      );
      expect(SeverityUtils.clinicalAction('watch'), 'Monitor closely');
      expect(SeverityUtils.clinicalAction('stable'), 'Continue routine care');
    });

    test('ranks severity in escalation order', () {
      expect(SeverityUtils.rank('critical'), 3);
      expect(SeverityUtils.rank('warning'), 2);
      expect(SeverityUtils.rank('watch'), 1);
      expect(SeverityUtils.rank('stable'), 0);
      expect(SeverityUtils.rank('unexpected'), 0);
    });

    test('handles severity values case-insensitively', () {
      expect(SeverityUtils.label('CRITICAL'), 'Critical');
      expect(SeverityUtils.rank('Warning'), 2);
      expect(SeverityUtils.clinicalAction('WATCH'), 'Monitor closely');
    });
  });
}
