import 'package:flutter/material.dart';
import '../../../core/controllers/notification_controller.dart';
import '../../../core/models/prescription.dart';
import '../../../core/models/appointment.dart';

class TestNotificationTrigger extends StatelessWidget {
  final Prescription? prescription;
  final Appointment?  nextAppointment;
  final String        patientName;
  final bool          isGuardian;

  const TestNotificationTrigger({
    super.key,
    required this.patientName,
    this.prescription,
    this.nextAppointment,
    this.isGuardian = false,
  });

  String get _slot {
    final h = DateTime.now().hour;
    if (h >= 5  && h < 12) return 'morning';
    if (h >= 12 && h < 17) return 'afternoon';
    return 'night';
  }

  bool _isTomorrow(String dateStr) {
    try {
      final d        = DateTime.parse(dateStr);
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      return d.year  == tomorrow.year  &&
          d.month == tomorrow.month &&
          d.day   == tomorrow.day;
    } catch (_) {
      return false;
    }
  }

  Future<void> _check(BuildContext context) async {
    int count = 0;

    if (prescription != null) {
      for (final med in prescription!.medicines) {
        final bool due =
            (_slot == 'morning'   && med.morning)   ||
                (_slot == 'afternoon' && med.afternoon) ||
                (_slot == 'night'     && med.night);

        if (due) {
          final String meal =
          med.beforeMeal ? 'before meal' : 'after meal';
          if (isGuardian) {
            await NotificationController.guardianMedicationReminder(
              patientName:  patientName,
              medicineName: med.name,
              dose:         med.dose,
              mealTiming:   meal,
              timeSlot:     _slot,
            );
          } else {
            await NotificationController.patientMedicationReminder(

              medicineName: med.name,
              dose:         med.dose,
              mealTiming:   meal,
              timeSlot:     _slot,

              uid: '',    // for local save of notifications
            );
          }
          count++;
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    if (nextAppointment != null &&
        _isTomorrow(nextAppointment!.date)) {
      if (isGuardian) {
        await NotificationController.guardianAppointmentReminder(
          patientName: patientName,
          date:        nextAppointment!.date,
          time:        nextAppointment!.time,
        );
      } else {
        await NotificationController.patientAppointmentReminder(


          uid: '',    // for local save of notifications


          date: nextAppointment!.date,
          time: nextAppointment!.time,
        );
      }
      count++;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(count > 0
          ? '🔔 $count reminder${count > 1 ? "s" : ""} sent'
          : 'No reminders due right now ($_slot slot)'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: Colors.orange.shade200),
      ),
      child: Row(children: [
        const Icon(Icons.notifications_active,
            color: Colors.orange, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            isGuardian
                ? 'Send reminders for $patientName'
                : 'Check your reminders',
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
        ElevatedButton(
          onPressed: () => _check(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
          ),
          child: const Text('Check Now',
              style: TextStyle(fontSize: 12)),
        ),
      ]),
    );
  }
}