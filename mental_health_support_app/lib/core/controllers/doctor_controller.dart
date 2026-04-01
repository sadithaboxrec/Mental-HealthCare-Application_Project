import '../services/doctor_service.dart';
import '../models/appointment.dart';
import '../models/prescription.dart';
import '../models/daily_log.dart';
import '../models/reschedule_request.dart';

class DoctorController {

  static Future<List<Map<String, dynamic>>> getNewPatients(
      String doctorUid) async =>
      await DoctorService.getNewPatients(doctorUid);

  static Future<List<Appointment>> getTodayAppointments(
      String doctorUid) async =>
      await DoctorService.getTodayAppointments(doctorUid);

  static Future<List<Map<String, dynamic>>> getAllPatients(
      String doctorUid) async =>
      await DoctorService.getAllPatients(doctorUid);

  static Future<void> savePrescription(Prescription p) async =>
      await DoctorService.savePrescription(p);

  static Future<void> saveAppointment(Appointment a) async =>
      await DoctorService.saveAppointment(a);

  static Future<void> markAbsent(String appointmentId) async =>
      await DoctorService.updateAppointmentStatus(appointmentId, 'absent');

  static Future<void> markCompleted(String appointmentId) async =>
      await DoctorService.updateAppointmentStatus(
          appointmentId, 'completed');

  static Future<Prescription?> getActivePrescription(
      String patientUid) async =>
      await DoctorService.getActivePrescription(patientUid);

  static Future<List<Prescription>> getAllPrescriptions(
      String patientUid) async =>
      await DoctorService.getAllPrescriptions(patientUid);

  static Future<List<DailyLog>> getDailyLogs(
      String patientUid, String from, String to) async =>
      await DoctorService.getDailyLogs(patientUid, from, to);

  static Future<List<Map<String, dynamic>>> getGuardianLogs(
      String patientUid, String from, String to) async =>
      await DoctorService.getGuardianLogs(patientUid, from, to);

  static Future<List<String>> getMedicineNames() async =>
      await DoctorService.getMedicineNames();

  static Future<List<RescheduleRequest>> getPendingReschedules(
      String doctorUid) async =>
      await DoctorService.getPendingReschedules(doctorUid);

  static Future<void> approveReschedule(
      RescheduleRequest req, String newDate) async =>
      await DoctorService.approveReschedule(req, newDate);
}