import 'package:flutter_test/flutter_test.dart';
import 'package:mental_health_support_app/core/models/chat_session.dart';

void main() {
  group('ChatSession', () {
    test('maps optional counselor fields and exposes status helpers', () {
      final session = ChatSession.fromMap('chat-1', {
        'patientUid': 'patient-1',
        'patientName': 'Maya Perera',
        'counselorUid': 'counselor-1',
        'counselorName': 'Counselor Silva',
        'status': 'active',
        'createdAt': '2026-04-28T08:00:00Z',
        'startedAt': '2026-04-28T08:05:00Z',
      });

      expect(session.id, 'chat-1');
      expect(session.isActive, isTrue);
      expect(session.isWaiting, isFalse);
      expect(session.isEnded, isFalse);
      expect(session.toMap()['counselorUid'], 'counselor-1');
    });

    test('defaults new sessions to waiting', () {
      final session = ChatSession.fromMap('chat-2', {});

      expect(session.status, 'waiting');
      expect(session.isWaiting, isTrue);
    });
  });
}
