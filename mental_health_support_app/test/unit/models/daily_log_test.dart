import 'package:flutter_test/flutter_test.dart';
import 'package:mental_health_support_app/core/models/daily_log.dart';

void main() {
  group('DailyLog', () {
    test('maps and serializes mood, hydration, sleep, and medication data', () {
      const log = DailyLog(
        id: 'log-1',
        patientUid: 'patient-1',
        date: '2026-04-28',
        mood: 4,
        moodUpdatedAt: '2026-04-28T08:10:00Z',
        waterIntake: 6,
        sleepHours: '7.5',
        medicationTaken: true,
        createdAt: '2026-04-28T08:00:00Z',
        updatedAt: '2026-04-28T09:00:00Z',
      );

      expect(log.toMap(), {
        'patientUid': 'patient-1',
        'date': '2026-04-28',
        'mood': 4,
        'moodUpdatedAt': '2026-04-28T08:10:00Z',
        'waterIntake': 6,
        'sleepHours': '7.5',
        'medicationTaken': true,
        'createdAt': '2026-04-28T08:00:00Z',
        'updatedAt': '2026-04-28T09:00:00Z',
      });
    });

    test('uses safe defaults for empty maps', () {
      final log = DailyLog.fromMap('log-2', {});

      expect(log.id, 'log-2');
      expect(log.mood, 0);
      expect(log.waterIntake, 0);
      expect(log.medicationTaken, isFalse);
      expect(log.patientUid, isEmpty);
    });
  });
}
