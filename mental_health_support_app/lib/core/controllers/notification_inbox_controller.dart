import '../services/notification_inbox_service.dart';
import '../models/app_notification.dart';

class NotificationInboxController {
  static Future<void> save({
    required String uid,
    required String title,
    required String body,
    required String type,
  }) => NotificationInboxService.save(
    uid: uid,
    title: title,
    body: body,
    type: type,
  );

  static Stream<int> unreadCountStream(String uid) =>
      NotificationInboxService.unreadCountStream(uid);

  static Stream<List<AppNotification>> notificationsStream(String uid) =>
      NotificationInboxService.notificationsStream(uid);

  static Future<void> markRead(String id) =>
      NotificationInboxService.markRead(id);

  static Future<void> markAllRead(String uid) =>
      NotificationInboxService.markAllRead(uid);
}
