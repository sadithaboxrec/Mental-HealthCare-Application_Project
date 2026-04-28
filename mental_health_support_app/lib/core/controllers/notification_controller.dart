import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../services/notification_service.dart';

class NotificationController {
  static Future<void> init() => NotificationService.init();

  static Future<void> saveToken(String uid) => NotificationService.saveToken(uid);

  static IconData iconForType(String type) {
    switch (type) {
      case 'medication':
        return PhosphorIcons.pill(PhosphorIconsStyle.duotone);
      case 'appointment':
        return PhosphorIcons.calendarCheck(PhosphorIconsStyle.duotone);
      case 'hydration':
        return PhosphorIcons.drop(PhosphorIconsStyle.duotone);
      case 'diary':
        return PhosphorIcons.notebook(PhosphorIconsStyle.duotone);
      default:
        return PhosphorIcons.bell(PhosphorIconsStyle.duotone);
    }
  }

  static Future<void> patientMedicationReminder({
    required String uid,
    required String medicineName,
    required String dose,
    required String mealTiming,
    required String timeSlot,
  }) => NotificationService.show(
    uid: uid,
    title: 'Time for your medicine',
    body: 'Take $medicineName ($dose) $mealTiming. Slot: $timeSlot.',
    type: 'medication',
    icon: iconForType('medication'),
  );

  static Future<void> patientAppointmentReminder({
    required String uid,
    required String date,
    required String time,
  }) => NotificationService.show(
    uid: uid,
    title: 'Clinic visit tomorrow',
    body: 'You have an appointment tomorrow at $time on $date.',
    type: 'appointment',
    icon: iconForType('appointment'),
  );

  static Future<void> patientWaterReminder({String? uid}) =>
      NotificationService.show(
        uid: uid,
        title: 'Stay hydrated',
        body: 'Don\'t forget to drink water and log your intake.',
        type: 'hydration',
        icon: iconForType('hydration'),
      );

  static Future<void> patientDiaryReminder({String? uid}) =>
      NotificationService.show(
        uid: uid,
        title: 'Write in your diary',
        body: 'Take a moment to record your thoughts today.',
        type: 'diary',
        icon: iconForType('diary'),
      );

  static Future<void> guardianMedicationReminder({
    required String patientName,
    required String medicineName,
    required String dose,
    required String mealTiming,
    required String timeSlot,
  }) => NotificationService.show(
    title: 'Medication time - $patientName',
    body:
        '$patientName needs $medicineName ($dose) '
        '$mealTiming. Slot: $timeSlot.',
    type: 'medication',
    icon: iconForType('medication'),
  );

  static Future<void> guardianAppointmentReminder({
    required String patientName,
    required String date,
    required String time,
  }) => NotificationService.show(
    title: 'Clinic tomorrow - $patientName',
    body: '$patientName has an appointment tomorrow at $time on $date.',
    type: 'appointment',
    icon: iconForType('appointment'),
  );

  static Future<void> testAlarm() => NotificationService.show(
    title: 'Test alarm',
    body: 'Alarm sound and vibration working correctly.',
    type: 'medication',
    icon: iconForType('medication'),
  );

  static Future<void> testGeneral() => NotificationService.show(
    title: 'Test general',
    body: 'General notification working correctly.',
    type: 'general',
    icon: iconForType('general'),
  );
}
