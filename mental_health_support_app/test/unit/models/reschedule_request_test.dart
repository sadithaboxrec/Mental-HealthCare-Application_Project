import 'package:flutter_test/flutter_test.dart';
import 'package:mental_health_support_app/core/models/reschedule_request.dart';

void main() {
  group('RescheduleRequest', () {
    test('defaults request status to pending and serializes without id', () {
      final request = RescheduleRequest.fromMap('request-1', {
        'patientUid': 'patient-1',
        'doctorUid': 'doctor-1',
        'appointmentId': 'appointment-1',
        'requestedDate': '2026-05-01',
        'reason': 'Exam conflict',
      });

      expect(request.status, 'pending');
      expect(request.toMap(), {
        'patientUid': 'patient-1',
        'doctorUid': 'doctor-1',
        'appointmentId': 'appointment-1',
        'requestedDate': '2026-05-01',
        'reason': 'Exam conflict',
        'status': 'pending',
        'createdAt': '',
      });
    });
  });
}
