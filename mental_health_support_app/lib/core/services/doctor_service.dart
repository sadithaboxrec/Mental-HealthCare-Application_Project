import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';
import '../models/diary_entry.dart';
import '../models/prescription.dart';
import '../models/reschedule_request.dart';
import '../models/daily_log.dart';

class DoctorService {

  static final _db = FirebaseFirestore.instance;

  // date sets
  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  //  New patients (assigned but no prescription yet)

  static Future<List<Map<String, dynamic>>> getNewPatients(
      String doctorUid) async {

    final snap = await _db
        .collection('patients')
        .where('assignedDoctor', isEqualTo: doctorUid)
        .get();

    final allPatients = snap.docs.map((d) => d.data()).toList();

    final presSnap = await _db
        .collection('prescriptions')
        .where('doctorUid', isEqualTo: doctorUid)
        .get();

    final patientsWithPrescription = presSnap.docs
        .map((d) => d.data()['patientUid'] as String)
        .toSet();

    return allPatients
        .where((p) => !patientsWithPrescription.contains(p['uid']))
        .toList();
  }

  //  Today's appointments
  static Future<List<Appointment>> getTodayAppointments(
      String doctorUid) async {

    final snap = await _db
        .collection('appointments')
        .where('doctorUid', isEqualTo: doctorUid)
        .where('date', isEqualTo: _today())
        .orderBy('time')
        .get();

    return snap.docs
        .map((d) => Appointment.fromMap(d.id, d.data()))
        .toList();

  }



  // All patients of the doctor that logged in
  static Future<List<Map<String, dynamic>>> getAllPatients(
      String doctorUid) async {

    final snap = await _db
        .collection('patients')
        .where('assignedDoctor', isEqualTo: doctorUid)
        .get();

    return snap.docs.map((d) => d.data()).toList();

  }

  // Save dr's prescription
  static Future<void> savePrescription(Prescription p) async {
    // deactivate old ones
    final old = await _db
        .collection('prescriptions')
        .where('patientUid', isEqualTo: p.patientUid)
        .where('isActive', isEqualTo: true)
        .get();
    for (final d in old.docs) {
      await d.reference.update({'isActive': false});
    }
    await _db.collection('prescriptions').add(p.toMap());
  }

  //  Save appointment
  static Future<void> saveAppointment(Appointment a) async {
    await _db.collection('appointments').add(a.toMap());
  }

  //  Mark appointment status as scedule complete etc
  static Future<void> updateAppointmentStatus(
      String appointmentId, String status) async {

    await _db
        .collection('appointments')
        .doc(appointmentId)
        .update({'status': status});
  }

  //  Get active prescription for patient
  static Future<Prescription?> getActivePrescription(
      String patientUid) async {
    final snap = await _db
        .collection('prescriptions')
        .where('patientUid', isEqualTo: patientUid)
        .get();

    final prescriptions = snap.docs
        .map((d) => Prescription.fromMap(d.id, d.data()))
        .where((p) => p.isActive)
        .toList();

    if (prescriptions.isEmpty) return null;

    prescriptions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return prescriptions.first;

  }

  //  Get all prescriptions for patient
  static Future<List<Prescription>> getAllPrescriptions(
      String patientUid) async {
    final snap = await _db
        .collection('prescriptions')
        .where('patientUid', isEqualTo: patientUid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) => Prescription.fromMap(d.id, d.data()))
        .toList();
  }

  // Get daily logs between dates
  static Future<List<DailyLog>> getDailyLogs(
      String patientUid, String from, String to) async {
    final snap = await _db
        .collection('daily_logs')
        .where('patientUid', isEqualTo: patientUid)
        .get();
    final logs = snap.docs
        .map((d) => DailyLog.fromMap(d.id, d.data()))
        .where((log) => log.date.compareTo(from) >= 0 && log.date.compareTo(to) <= 0)
        .toList();

    logs.sort((a, b) => a.date.compareTo(b.date));
    return logs;
  }

  static Future<List<DiaryEntry>> getDiaryEntries(
      String patientUid, String from, String to) async {
    final snap = await _db
        .collection('diary_entries')
        .where('patientUid', isEqualTo: patientUid)
        .get();

    final allEntries = snap.docs
        .map((d) => DiaryEntry.fromMap(d.id, d.data()))
        .where((entry) => entry.content.trim().isNotEmpty)
        .toList();

    allEntries.sort((a, b) => b.sortKey.compareTo(a.sortKey));

    final rangedEntries = allEntries.where((entry) {
      final entryDate = entry.createdDateKey;
      if (entryDate.isEmpty) return true;
      return entryDate.compareTo(from) >= 0 && entryDate.compareTo(to) <= 0;
    }).toList();

    if (rangedEntries.isNotEmpty) {
      return rangedEntries;
    }

    return allEntries;
  }

  static Future<Map<String, dynamic>?> getXaiAnalysisSnapshot(
      String patientUid) async {
    final directDoc = await _db
        .collection('analytics_snapshots')
        .doc(patientUid)
        .get();

    if (directDoc.exists) {
      final data = directDoc.data();
      if (data != null &&
          (data['type'] == 'xai_analysis' ||
              data['analysisType'] == 'xai_analysis_v1' ||
              data['type'] == 'diary_analysis')) {
        return data;
      }
    }

    final snap = await _db
        .collection('analytics_snapshots')
        .where('patientUid', isEqualTo: patientUid)
        .where('type', isEqualTo: 'xai_analysis')
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) return snap.docs.first.data();

    final legacySnap = await _db
        .collection('analytics_snapshots')
        .where('patientUid', isEqualTo: patientUid)
        .where('type', isEqualTo: 'diary_analysis')
        .limit(1)
        .get();

    if (legacySnap.docs.isEmpty) return null;
    return legacySnap.docs.first.data();
  }

  //  Get guardian logs between dates
  static Future<List<Map<String, dynamic>>> getGuardianLogs(
      String patientUid, String from, String to) async {
    final snap = await _db
        .collection('guardian_logs')
        .where('patientUid', isEqualTo: patientUid)
        .get();

    final logs = snap.docs
        .map((d) => d.data())
        .where((log) {
          final date = (log['date'] as String?) ?? '';
          return date.compareTo(from) >= 0 && date.compareTo(to) <= 0;
        })
        .toList();

    logs.sort((a, b) {
      final aDate = (a['date'] as String?) ?? '';
      final bDate = (b['date'] as String?) ?? '';
      return aDate.compareTo(bDate);
    });

    return logs;
  }

  //  Get medicines list
  static Future<List<String>> getMedicineNames() async {
    final snap = await _db.collection('medicines').orderBy('name').get();
    return snap.docs.map((d) => d.data()['name'] as String).toList();
  }


  // need more testing here

  // Get pending reschedule requests
  static Future<List<RescheduleRequest>> getPendingReschedules(
      String doctorUid) async {
    final snap = await _db
        .collection('reschedule_requests')
        .where('doctorUid', isEqualTo: doctorUid)
        .where('status', isEqualTo: 'pending')
        .get();
    return snap.docs
        .map((d) => RescheduleRequest.fromMap(d.id, d.data()))
        .toList();
  }

  //  Approve reschedule
  static Future<void> approveReschedule(
      RescheduleRequest req, String newDate) async {
    await _db
        .collection('reschedule_requests')
        .doc(req.id)
        .update({'status': 'approved'});

    await _db
        .collection('appointments')
        .doc(req.appointmentId)
        .update({'date': newDate, 'status': 'rescheduled'});
  }
}
