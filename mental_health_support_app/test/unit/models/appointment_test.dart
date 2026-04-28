import 'package:flutter_test/flutter_test.dart';
import 'package:mental_health_support_app/core/models/appointment.dart';

void main() {
  group('Appointment', () {
    test('maps Firestore data and keeps document id separately', () {
      final appointment = Appointment.fromMap('appointment-1', {
        'patientUid': 'patient-1',
        'doctorUid': 'doctor-1',
        'patientName': 'Maya Perera',
        'date': '2026-04-28',
        'time': '09:30',
        'status': 'completed',
        'createdAt': '2026-04-25T08:00:00Z',
      });

      expect(appointment.id, 'appointment-1');
      expect(appointment.patientUid, 'patient-1');
      expect(appointment.doctorUid, 'doctor-1');
      expect(appointment.patientName, 'Maya Perera');
      expect(appointment.date, '2026-04-28');
      expect(appointment.time, '09:30');
      expect(appointment.status, 'completed');
      expect(appointment.createdAt, '2026-04-25T08:00:00Z');
    });

    test('defaults status to scheduled and omits id from toMap', () {
      final appointment = Appointment.fromMap('appointment-2', {});

      expect(appointment.status, 'scheduled');
      expect(appointment.toMap(), {
        'patientUid': '',
        'doctorUid': '',
        'patientName': '',
        'date': '',
        'time': '',
        'status': 'scheduled',
        'createdAt': '',
      });
    });
  });
}
