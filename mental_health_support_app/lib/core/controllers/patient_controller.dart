import '../services/patient_service.dart';
import '../models/daily_log.dart';
import '../models/diary_entry.dart';
import '../models/prescription.dart';
import '../models/appointment.dart';

class PatientController {

  static Future<DailyLog?> getTodayLog(String patientUid) async =>
      await PatientService.getTodayLog(patientUid);

  static Future<void> updateMood(String patientUid, int mood) async =>
      await PatientService.updateMood(patientUid, mood);

  static Future<void> addWater(String patientUid, int glasses) async =>
      await PatientService.addWater(patientUid, glasses);

  static Future<void> updateSleep(
      String patientUid, String sleepHours) async =>
      await PatientService.updateSleep(patientUid, sleepHours);

  static Future<void> updateMedication(
      String patientUid, bool taken) async =>
      await PatientService.updateMedication(patientUid, taken);

  static Future<void> saveDiaryEntry(
      String patientUid, String content) async =>
      await PatientService.saveDiaryEntry(patientUid, content);

  static Future<List<DiaryEntry>> getDiaryEntries(
      String patientUid) async =>
      await PatientService.getDiaryEntries(patientUid);

  static Future<void> updateDiaryEntry(
      String entryId, String content) async =>
      await PatientService.updateDiaryEntry(entryId, content);

  static Future<void> deleteDiaryEntry(String entryId) async =>
      await PatientService.deleteDiaryEntry(entryId);

  static Future<Prescription?> getActivePrescription(
      String patientUid) async =>
      await PatientService.getActivePrescription(patientUid);

  static Future<Appointment?> getNextAppointment(
      String patientUid) async =>
      await PatientService.getNextAppointment(patientUid);

  static Future<void> requestReschedule({
    required String patientUid,
    required String doctorUid,
    required String appointmentId,
    required String requestedDate,
    required String reason,
  }) async =>
      await PatientService.requestReschedule(
        patientUid:    patientUid,
        doctorUid:     doctorUid,
        appointmentId: appointmentId,
        requestedDate: requestedDate,
        reason:        reason,
      );
}
