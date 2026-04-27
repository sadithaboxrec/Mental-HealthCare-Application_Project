import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_session.dart';
import '../models/chat_message.dart';

// for debugging purpose
import 'package:flutter/foundation.dart';

class ChatService {
  static final _db = FirebaseFirestore.instance;

  // Patient asking for chat support
  static Future<ChatSession> requestSupport({
    required String patientUid,
    required String patientName,
  }) async {
    // Check if patient already has an active/waiting session
    final existing = await _db
        .collection('chat_sessions')
        .where('patientUid', isEqualTo: patientUid)
        .where('status', whereIn: ['waiting', 'active'])
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return ChatSession.fromMap(
        existing.docs.first.id,
        existing.docs.first.data(),
      );
    }

    // Create new session
    final now = DateTime.now().toIso8601String();
    final ref = await _db.collection('chat_sessions').add({
      'patientUid': patientUid,
      'patientName': patientName,
      'counselorUid': null,
      'counselorName': null,
      'status': 'waiting',
      'createdAt': now,
      'startedAt': null,
      'endedAt': null,
    });

    final doc = await ref.get();
    return ChatSession.fromMap(doc.id, doc.data()!);
  }

  // Counselor accepts the request for chat session
  static Future<void> acceptSession({
    required String sessionId,
    required String counselorUid,
    required String counselorName,
  }) async {
    await _db.collection('chat_sessions').doc(sessionId).update({
      'counselorUid': counselorUid,
      'counselorName': counselorName,
      'status': 'active',
      'startedAt': DateTime.now().toIso8601String(),
    });
  }

  //  End session
  static Future<void> endSession(String sessionId) async {
    await _db.collection('chat_sessions').doc(sessionId).update({
      'status': 'ended',
      'endedAt': DateTime.now().toIso8601String(),
    });
  }

  //  Send message
  static Future<void> sendMessage({
    required String sessionId,
    required String senderUid,
    required String senderRole,
    required String text,
  }) async {
    await _db
        .collection('chat_sessions')
        .doc(sessionId)
        .collection('messages')
        .add({
          'senderUid': senderUid,
          'senderRole': senderRole,
          'text': text.trim(),
          'timestamp': DateTime.now().toIso8601String(),
        });
  }

  //  Stream messages (real time)
  static Stream<List<ChatMessage>> messagesStream(String sessionId) {
    return _db
        .collection('chat_sessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ChatMessage.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  //  Stream session

  // Patient watches this to know when counselor joins
  static Stream<ChatSession> sessionStream(String sessionId) {
    return _db
        .collection('chat_sessions')
        .doc(sessionId)
        .snapshots()
        .map((d) => ChatSession.fromMap(d.id, d.data()!));
  }

  //  Stream waiting sessions (for counselor dashboard) ─
  // static Stream<List<ChatSession>> waitingSessionsStream() {
  //
  //   return _db
  //       .collection('chat_sessions')
  //       .where('status', isEqualTo: 'waiting')
  //       .snapshots()
  //       .map((snap) => snap.docs
  //       .map((d) => ChatSession.fromMap(d.id, d.data()))
  //       .toList());
  //
  // }

  static Stream<List<ChatSession>> waitingSessionsStream() {
    debugPrint('=== waitingSessionsStream called ===');
    return _db
        .collection('chat_sessions')
        .where('status', isEqualTo: 'waiting')
        .snapshots()
        .map((snap) {
          debugPrint('=== snap docs count: ${snap.docs.length} ===');
          return snap.docs
              .map((d) => ChatSession.fromMap(d.id, d.data()))
              .toList();
        });
  }

  //  Stream counselor's active session
  static Stream<ChatSession?> counselorActiveSessionStream(
    String counselorUid,
  ) {
    return _db
        .collection('chat_sessions')
        .where('counselorUid', isEqualTo: counselorUid)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          return ChatSession.fromMap(
            snap.docs.first.id,
            snap.docs.first.data(),
          );
        });
  }

  //  Get patient info for counselor
  static Future<Map<String, dynamic>?> getPatientDetails(
    String patientUid,
  ) async {
    final doc = await _db.collection('patients').doc(patientUid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  //  Get chat history for a patient
  static Future<List<ChatSession>> getPatientHistory(String patientUid) async {
    final snap = await _db
        .collection('chat_sessions')
        .where('patientUid', isEqualTo: patientUid)
        .where('status', isEqualTo: 'ended')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => ChatSession.fromMap(d.id, d.data())).toList();
  }
}
