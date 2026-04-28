import 'package:flutter_test/flutter_test.dart';
import 'package:mental_health_support_app/core/models/prescription.dart';

void main() {
  group('Prescription', () {
    test('maps nested medicines', () {
      final prescription = Prescription.fromMap('rx-1', {
        'patientUid': 'patient-1',
        'doctorUid': 'doctor-1',
        'patientName': 'Maya Perera',
        'diagnosis': 'Anxiety',
        'notes': 'Monitor sleep.',
        'suggestions': 'Follow up in two weeks.',
        'nextAppointmentDate': '2026-05-12',
        'isActive': true,
        'createdAt': '2026-04-28T08:00:00Z',
        'medicines': [
          {'name': 'Sertraline', 'dose': '50mg', 'morning': true},
        ],
      });

      expect(prescription.id, 'rx-1');
      expect(prescription.medicines.single.name, 'Sertraline');
      expect(prescription.toMap()['medicines'], isA<List<dynamic>>());
    });
  });
}
