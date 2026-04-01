import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prescription.dart';
import '../models/appointment.dart';

import 'package:flutter/foundation.dart'; // for debugging


// 1.  Daily Log Management
// One log per guardian per day,Update if exists, create if not
// 2. aPatient doctor Fetching
// 3. Prescription and Appointment getting




class GuardianService {

  static final _db = FirebaseFirestore.instance;

  static String _today() {

    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';

  }

  static Future<Map<String, dynamic>?> _getTodayLog(
      String guardianUid) async {

    final snap = await _db
        .collection('guardian_logs')
        .where('guardianUid', isEqualTo: guardianUid)
        .where('date', isEqualTo: _today())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return {'id': snap.docs.first.id, ...snap.docs.first.data()};

  }

  static Future<void> updateMood(
      String guardianUid, String patientUid, int mood) async {


    final now      = DateTime.now().toIso8601String();
    final existing = await _getTodayLog(guardianUid);

    // Get today's log
    // if exists  update mood or create new log

    if (existing != null) {
      await _db.collection('guardian_logs')
          .doc(existing['id']).update({'mood': mood, 'updatedAt': now});
    } else {
      await _db.collection('guardian_logs').add({
        'guardianUid':  guardianUid,
        'patientUid':   patientUid,
        'date':         _today(),
        'mood':         mood,
        'waterIntake':  0,
        'observations': '',
        'createdAt':    now,
        'updatedAt':    now,
      });

    }

  }

  static Future<void> addWater(
      String guardianUid, String patientUid, int glasses) async {

    final now      = DateTime.now().toIso8601String();
    final existing = await _getTodayLog(guardianUid);
    final current  = existing?['waterIntake'] as int? ?? 0;

    // Get today's log
    // Read current water Add new glasses
    // Update OR create

    if (existing != null) {
      await _db.collection('guardian_logs')
          .doc(existing['id'])
          .update({'waterIntake': current + glasses, 'updatedAt': now});
    } else {
      await _db.collection('guardian_logs').add({
        'guardianUid':  guardianUid,
        'patientUid':   patientUid,
        'date':         _today(),
        'mood':         0,
        'waterIntake':  glasses,
        'observations': '',
        'createdAt':    now,
        'updatedAt':    now,
      });
    }

  }



  static Future<void> updateObservations(
      String guardianUid, String patientUid, String observations) async {

    final now      = DateTime.now().toIso8601String();
    final existing = await _getTodayLog(guardianUid);

    // Saves notes for the day
    // Update if exists
    // Create if not

    if (existing != null) {
      await _db.collection('guardian_logs')
          .doc(existing['id'])
          .update({'observations': observations, 'updatedAt': now});
    } else {
      await _db.collection('guardian_logs').add({
        'guardianUid':  guardianUid,
        'patientUid':   patientUid,
        'date':         _today(),
        'mood':         0,
        'waterIntake':  0,
        'observations': observations,
        'createdAt':    now,
        'updatedAt':    now,
      });
    }

  }

  // Finds which patient belongs to guardian
  static Future<String?> getPatientUid(String guardianUid) async {

    final doc = await _db.collection('guardians').doc(guardianUid).get();
    if (!doc.exists) return null;
    return doc.data()?['patientUid'] as String?;
  }

  static Future<String?> getPatientDoctorUid(String patientUid) async {
    final doc = await _db.collection('patients').doc(patientUid).get();
    if (!doc.exists) return null;
    return doc.data()?['assignedDoctor'] as String?;
  }

  static Future<Map<String, dynamic>?> getTodayLogPublic(
      String guardianUid) async {
    return await _getTodayLog(guardianUid);
  }


// get the prescription of patient
  static Future<Prescription?> getPatientActivePrescription(
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


  // get the nearest upcoming appointment

  static Future<Appointment?> getPatientNextAppointment(
      String patientUid) async {

    try {
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day
          .toString().padLeft(2, '0')}';
      final snap = await _db
          .collection('appointments')
          .where('patientUid', isEqualTo: patientUid)
          .where('date', isGreaterThanOrEqualTo: todayStr)
          .where('status', whereIn: ['scheduled', 'rescheduled'])
          .orderBy('date')
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return Appointment.fromMap(snap.docs.first.id, snap.docs.first.data());
    } catch (e) {
      debugPrint('getPatientNextAppointment error: $e');
      return null;
    }

  }



}