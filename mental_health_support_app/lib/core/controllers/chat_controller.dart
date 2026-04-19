import '../services/chat_service.dart';
import '../models/chat_session.dart';
import '../models/chat_message.dart';

class ChatController {

  static Future<ChatSession> requestSupport({
    required String patientUid,
    required String patientName,
  }) async =>
      await ChatService.requestSupport(
        patientUid:  patientUid,
        patientName: patientName,
      );

  static Future<void> acceptSession({
    required String sessionId,
    required String counselorUid,
    required String counselorName,
  }) async =>
      await ChatService.acceptSession(
        sessionId:     sessionId,
        counselorUid:  counselorUid,
        counselorName: counselorName,
      );

  static Future<void> endSession(String sessionId) async =>
      await ChatService.endSession(sessionId);

  static Future<void> sendMessage({
    required String sessionId,
    required String senderUid,
    required String senderRole,
    required String text,
  }) async =>
      await ChatService.sendMessage(
        sessionId:  sessionId,
        senderUid:  senderUid,
        senderRole: senderRole,
        text:       text,
      );


  static Stream<List<ChatMessage>> messagesStream(String sessionId) =>
      ChatService.messagesStream(sessionId);

  static Stream<ChatSession> sessionStream(String sessionId) =>
      ChatService.sessionStream(sessionId);

  static Stream<List<ChatSession>> waitingSessionsStream() =>
      ChatService.waitingSessionsStream();

  static Stream<ChatSession?> counselorActiveSessionStream(
      String counselorUid) =>
      ChatService.counselorActiveSessionStream(counselorUid);

  static Future<Map<String, dynamic>?> getPatientDetails(
      String patientUid) async =>
      await ChatService.getPatientDetails(patientUid);

  static Future<List<ChatSession>> getPatientHistory(
      String patientUid) async =>
      await ChatService.getPatientHistory(patientUid);
}