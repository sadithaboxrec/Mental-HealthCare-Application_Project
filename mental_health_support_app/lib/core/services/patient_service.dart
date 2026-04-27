import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_log.dart';
import '../models/diary_entry.dart';
import '../models/prescription.dart';
import '../models/appointment.dart';

class PatientService {
  static final _db = FirebaseFirestore.instance;

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  //  Get or create today's log
  static Future<DailyLog?> getTodayLog(String patientUid) async {

    final snap = await _db
        .collection('daily_logs')
        .where('patientUid', isEqualTo: patientUid)
        .where('date', isEqualTo: _today())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return DailyLog.fromMap(snap.docs.first.id, snap.docs.first.data());

  }


  // Update mood
  static Future<void> updateMood(String patientUid, int mood) async {

    final now     = DateTime.now().toIso8601String();
    final existing = await getTodayLog(patientUid);

    if (existing != null) {
      await _db.collection('daily_logs').doc(existing.id).update({
        'mood':          mood,
        'moodUpdatedAt': now,
        'updatedAt':     now,
      });
    }
    // (overwrites the mood value, last mood go to db)
    else {
      await _db.collection('daily_logs').add({
        'patientUid':      patientUid,
        'date':            _today(),
        'mood':            mood,
        'moodUpdatedAt':   now,
        'waterIntake':     0,
        'sleepHours':      '',
        'medicationTaken': false,
        'createdAt':       now,
        'updatedAt':       now,
      });
    }

  }



  // Add water intake
  static Future<void> addWater(String patientUid, int glasses) async {

    final now      = DateTime.now().toIso8601String();
    final existing = await getTodayLog(patientUid);

    if (existing != null) {
      await _db.collection('daily_logs').doc(existing.id).update({
        'waterIntake': existing.waterIntake + glasses,
        'updatedAt':   now,
      });
    }
    // need to chck on the update logic
    else {
      await _db.collection('daily_logs').add({
        'patientUid':      patientUid,
        'date':            _today(),
        'mood':            0,
        'moodUpdatedAt':   now,
        'waterIntake':     glasses,
        'sleepHours':      '',
        'medicationTaken': false,
        'createdAt':       now,
        'updatedAt':       now,
      });
    }
  }



  //  Update sleep
  static Future<void> updateSleep(
      String patientUid, String sleepHours) async {

    final now      = DateTime.now().toIso8601String();
    final existing = await getTodayLog(patientUid);

    if (existing != null) {
      await _db.collection('daily_logs').doc(existing.id).update({
        'sleepHours': sleepHours,
        'updatedAt':  now,
      });
    } else {
      await _db.collection('daily_logs').add({
        'patientUid':      patientUid,
        'date':            _today(),
        'mood':            0,
        'moodUpdatedAt':   now,
        'waterIntake':     0,
        'sleepHours':      sleepHours,
        'medicationTaken': false,
        'createdAt':       now,
        'updatedAt':       now,
      });
    }

  }

  //  Mark medication taken
  static Future<void> updateMedication(
      String patientUid, bool taken) async {

    final now      = DateTime.now().toIso8601String();
    final existing = await getTodayLog(patientUid);

    if (existing != null) {
      await _db.collection('daily_logs').doc(existing.id).update({
        'medicationTaken': taken,
        'updatedAt':       now,
      });
    } else {
      await _db.collection('daily_logs').add({
        'patientUid':      patientUid,
        'date':            _today(),
        'mood':            0,
        'moodUpdatedAt':   now,
        'waterIntake':     0,
        'sleepHours':      '',
        'medicationTaken': taken,
        'createdAt':       now,
        'updatedAt':       now,
      });
    }

    await _db.collection('medication_adherence_events').add({
      'patientUid': patientUid,
      'prescriptionId': null,
      'medicineId': null,
      'slot': 'daily',
      'scheduledAt': now,
      'status': taken ? 'taken' : 'missed',
      'reportedBy': 'patient',
      'reportedAt': now,
      'guardianVerification': null,
    });
  }

  // Save diary entry
  static Future<void> saveDiaryEntry(
      String patientUid, String content) async {
    await createDiaryEntry(patientUid, content);
  }

  static Future<String> createDiaryEntry(
      String patientUid, String content) async {
    final now = DateTime.now().toIso8601String();

    final doc = await _db.collection('diary_entries').add({
      'patientUid': patientUid,
      'content': content,
      'createdAt': now,
      'updatedAt': now,
    });

    return doc.id;
  }

  static Future<List<DiaryEntry>> getDiaryEntries(String patientUid) async {
    final snap = await _db
        .collection('diary_entries')
        .where('patientUid', isEqualTo: patientUid)
        .get();

    final entries = snap.docs
        .map((d) => DiaryEntry.fromMap(d.id, d.data()))
        .where((entry) => entry.content.trim().isNotEmpty)
        .toList();

    entries.sort((a, b) => b.sortKey.compareTo(a.sortKey));
    return entries.take(20).toList();
  }

  static Future<void> updateDiaryEntry(
      String entryId, String content) async {
    await _db.collection('diary_entries').doc(entryId).update({
      'content': content,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> deleteDiaryEntry(String entryId) async {
    await _db.collection('diary_entries').doc(entryId).delete();
  }

  //  Get  prescription of patient
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

  // ── Get next appointment ──────────────────────────────
  // static Future<Appointment?> getNextAppointment(
  //     String patientUid) async {
  //   final snap = await _db
  //       .collection('appointments')
  //       .where('patientUid', isEqualTo: patientUid)
  //       .where('date', isGreaterThanOrEqualTo: _today())
  //       .where('status', isEqualTo: 'scheduled')
  //       .orderBy('date')
  //       .limit(1)
  //       .get();
  //   if (snap.docs.isEmpty) return null;
  //   return Appointment.fromMap(snap.docs.first.id, snap.docs.first.data());
  // }

  // upcoming appointment check
  static Future<Appointment?> getNextAppointment(String patientUid) async {

    final snap = await _db
        .collection('appointments')
        .where('patientUid', isEqualTo: patientUid)
        .where('date', isGreaterThanOrEqualTo: _today())
        .where('status', whereIn: ['scheduled', 'rescheduled'])
        .orderBy('date')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Appointment.fromMap(snap.docs.first.id, snap.docs.first.data());
  }


  //  Request reschedule of appointment of patient

  static Future<void> requestReschedule({
    required String patientUid,
    required String doctorUid,
    required String appointmentId,
    required String requestedDate,
    required String reason,
  }) async {

    await _db.collection('reschedule_requests').add({
      'patientUid':    patientUid,
      'doctorUid':     doctorUid,
      'appointmentId': appointmentId,
      'requestedDate': requestedDate,
      'reason':        reason,
      'status':        'pending',
      'createdAt':     DateTime.now().toIso8601String(),
    });
  }


}
