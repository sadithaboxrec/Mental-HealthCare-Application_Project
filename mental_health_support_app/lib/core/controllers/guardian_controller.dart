import '../services/guardian_service.dart';
import '../models/prescription.dart';
import '../models/appointment.dart';

class GuardianController {

  static Future<String?> getPatientUid(String guardianUid) async =>
      await GuardianService.getPatientUid(guardianUid);

  static Future<String?> getPatientDoctorUid(String patientUid) async =>
      await GuardianService.getPatientDoctorUid(patientUid);

  static Future<void> updateMood(
      String guardianUid, String patientUid, int mood) async =>
      await GuardianService.updateMood(guardianUid, patientUid, mood);

  static Future<void> addWater(
      String guardianUid, String patientUid, int glasses) async =>
      await GuardianService.addWater(guardianUid, patientUid, glasses);

  static Future<void> updateObservations(
      String guardianUid, String patientUid, String observations) async =>
      await GuardianService.updateObservations(
          guardianUid, patientUid, observations);

  static Future<Map<String, dynamic>?> getTodayLog(
      String guardianUid) async =>
      await GuardianService.getTodayLogPublic(guardianUid);


  static Future<Prescription?> getPatientPrescription(
      String patientUid) async =>
      await GuardianService.getPatientActivePrescription(patientUid);

  static Future<Appointment?> getPatientNextAppointment(
      String patientUid) async =>
      await GuardianService.getPatientNextAppointment(patientUid);
}