class AppNotification {
  final String id;
  final String uid;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String createdAt;

  const AppNotification({
    required this.id,
    required this.uid,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> m) =>
      AppNotification(
        id: id,
        uid: m['uid'] ?? '',
        title: m['title'] ?? '',
        body: m['body'] ?? '',
        type: m['type'] ?? 'general',
        isRead: m['isRead'] ?? false,
        createdAt: m['createdAt'] ?? '',
      );

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'title': title,
    'body': body,
    'type': type,
    'isRead': isRead,
    'createdAt': createdAt,
  };
}
