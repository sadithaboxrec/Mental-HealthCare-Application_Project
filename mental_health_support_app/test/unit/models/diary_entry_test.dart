import 'package:flutter_test/flutter_test.dart';
import 'package:mental_health_support_app/core/models/diary_entry.dart';

void main() {
  group('DiaryEntry', () {
    test('reads content fallback fields and normalizes DateTime values', () {
      final entry = DiaryEntry.fromMap('diary-1', {
        'uid': 'patient-1',
        'entryText': 'I went for a walk today.',
        'createdAt': DateTime.utc(2026, 4, 28, 9, 30),
        'updatedAt': DateTime.utc(2026, 4, 28, 10),
      });

      expect(entry.patientUid, 'patient-1');
      expect(entry.content, 'I went for a walk today.');
      expect(entry.createdAt, '2026-04-28T09:30:00.000Z');
      expect(entry.createdDateKey, '2026-04-28');
      expect(entry.isEdited, isTrue);
      expect(entry.toMap()['updatedAt'], '2026-04-28T10:00:00.000Z');
    });

    test(
      'normalizes Firestore-like timestamp maps and millisecond integers',
      () {
        final fromMap = DiaryEntry.fromMap('diary-2', {
          'patientUid': 'patient-1',
          'content': 'Feeling steady.',
          'createdAt': {'seconds': 1777370400, 'nanoseconds': 500000000},
        });
        final fromMillis = DiaryEntry.fromMap('diary-3', {
          'patientUid': 'patient-1',
          'content': 'Medication taken.',
          'createdAt': 1777370400000,
        });

        expect(fromMap.createdAt, '2026-04-28T10:00:00.500Z');
        expect(fromMillis.createdAt, '2026-04-28T10:00:00.000Z');
      },
    );
  });
}
