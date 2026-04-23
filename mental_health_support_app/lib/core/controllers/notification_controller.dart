import '../services/notification_service.dart';

class NotificationController {

  static Future<void> init() =>
      NotificationService.init();

  static Future<void> saveToken(String uid) =>
      NotificationService.saveToken(uid);

  // ── Patient ───────────────────────────────────────────

  static Future<void> patientMedicationReminder({
    required String medicineName,
    required String dose,
    required String mealTiming,
    required String timeSlot,
  }) =>
      NotificationService.show(
        title: '💊 Time for your medicine',
        body:  'Take $medicineName ($dose) $mealTiming. '
            'Slot: $timeSlot.',
        type:  'medication',
      );

  static Future<void> patientAppointmentReminder({
    required String date,
    required String time,
  }) =>
      NotificationService.show(
        title: '📅 Clinic Visit Tomorrow',
        body:  'You have an appointment tomorrow at $time on $date.',
        type:  'appointment',
      );

  static Future<void> patientWaterReminder() =>
      NotificationService.show(
        title: '💧 Stay Hydrated',
        body:  'Don\'t forget to drink water and log your intake.',
        type:  'general',
      );

  static Future<void> patientDiaryReminder() =>
      NotificationService.show(
        title: '📓 Write in your diary',
        body:  'Take a moment to record your thoughts today.',
        type:  'general',
      );

  // ── Guardian ──────────────────────────────────────────

  static Future<void> guardianMedicationReminder({
    required String patientName,
    required String medicineName,
    required String dose,
    required String mealTiming,
    required String timeSlot,
  }) =>
      NotificationService.show(
        title: '💊 Medication Time — $patientName',
        body:  '$patientName needs $medicineName ($dose) '
            '$mealTiming. Slot: $timeSlot.',
        type:  'medication',
      );

  static Future<void> guardianAppointmentReminder({
    required String patientName,
    required String date,
    required String time,
  }) =>
      NotificationService.show(
        title: '📅 Clinic Tomorrow — $patientName',
        body:  '$patientName has an appointment tomorrow '
            'at $time on $date.',
        type:  'appointment',
      );

  // ── Test ──────────────────────────────────────────────

  static Future<void> testAlarm() =>
      NotificationService.show(
        title: '🔔 Test Alarm',
        body:  'Alarm sound and vibration working correctly.',
        type:  'medication',
      );

  static Future<void> testGeneral() =>
      NotificationService.show(
        title: '🔔 Test General',
        body:  'General notification working correctly.',
        type:  'general',
      );
}