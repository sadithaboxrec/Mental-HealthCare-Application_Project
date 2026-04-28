import 'package:flutter_test/flutter_test.dart';
import 'package:mental_health_support_app/core/models/chat_message.dart';

void main() {
  group('ChatMessage', () {
    test('round-trips chat message fields without serializing the id', () {
      final message = ChatMessage.fromMap('message-1', {
        'senderUid': 'doctor-1',
        'senderRole': 'doctor',
        'text': 'How are you feeling today?',
        'timestamp': '2026-04-28T07:30:00Z',
      });

      expect(message.id, 'message-1');
      expect(message.toMap(), {
        'senderUid': 'doctor-1',
        'senderRole': 'doctor',
        'text': 'How are you feeling today?',
        'timestamp': '2026-04-28T07:30:00Z',
      });
    });
  });
}
