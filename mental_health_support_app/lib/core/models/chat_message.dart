class ChatMessage {
  final String id;
  final String senderUid;
  final String senderRole; // who is sending the message
  final String text;
  final String timestamp;

  const ChatMessage({
    required this.id,
    required this.senderUid,
    required this.senderRole,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> m) =>
      ChatMessage(
        id:         id,
        senderUid:  m['senderUid']  ?? '',
        senderRole: m['senderRole'] ?? '',
        text:       m['text']       ?? '',
        timestamp:  m['timestamp']  ?? '',
      );

  Map<String, dynamic> toMap() => {
    'senderUid':  senderUid,
    'senderRole': senderRole,
    'text':       text,
    'timestamp':  timestamp,
  };
}