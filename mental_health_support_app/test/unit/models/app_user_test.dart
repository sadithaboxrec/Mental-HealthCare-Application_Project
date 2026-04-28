import 'package:flutter_test/flutter_test.dart';
import 'package:mental_health_support_app/core/models/app_user.dart';

void main() {
  group('AppUser', () {
    test('maps all supported fields and exposes role helpers', () {
      final user = AppUser.fromMap({
        'uid': 'patient-1',
        'name': 'Maya Perera',
        'email': 'maya@example.com',
        'phone': '0771234567',
        'role': 'patient',
        'createdAt': '2026-04-20T10:00:00Z',
      });

      expect(user.uid, 'patient-1');
      expect(user.name, 'Maya Perera');
      expect(user.email, 'maya@example.com');
      expect(user.phone, '0771234567');
      expect(user.createdAt, '2026-04-20T10:00:00Z');
      expect(user.isPatient, isTrue);
      expect(user.isDoctor, isFalse);
      expect(user.isCounselor, isFalse);
      expect(user.isGuardian, isFalse);
    });

    test('falls back to empty strings for missing map values', () {
      final user = AppUser.fromMap({});

      expect(user.uid, isEmpty);
      expect(user.name, isEmpty);
      expect(user.email, isEmpty);
      expect(user.phone, isEmpty);
      expect(user.role, isEmpty);
      expect(user.createdAt, isEmpty);
    });
  });
}
