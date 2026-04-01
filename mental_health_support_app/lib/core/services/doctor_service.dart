import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';
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
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return Prescription.fromMap(snap.docs.first.id, snap.docs.first.data());

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
        .where('date', isGreaterThanOrEqualTo: from)
        .where('date', isLessThanOrEqualTo: to)
        .orderBy('date')
        .get();
    return snap.docs
        .map((d) => DailyLog.fromMap(d.id, d.data()))
        .toList();
  }

  //  Get guardian logs between dates
  static Future<List<Map<String, dynamic>>> getGuardianLogs(
      String patientUid, String from, String to) async {
    final snap = await _db
        .collection('guardian_logs')
        .where('patientUid', isEqualTo: patientUid)
        .where('date', isGreaterThanOrEqualTo: from)
        .where('date', isLessThanOrEqualTo: to)
        .orderBy('date')
        .get();

    return snap.docs.map((d) => d.data()).toList();
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