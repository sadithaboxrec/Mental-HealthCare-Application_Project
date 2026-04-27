import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification.dart';

class NotificationInboxService {
  static final _db = FirebaseFirestore.instance;

  // to Save notification to Firestore
  static Future<void> save({
    required String uid,
    required String title,
    required String body,
    required String type,
  }) async {
    await _db.collection('notifications').add({
      'uid': uid,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  //  Stream unread count
  static Stream<int> unreadCountStream(String uid) {
    return _db
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  //  Stream all notifications
  static Stream<List<AppNotification>> notificationsStream(String uid) {
    return _db
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AppNotification.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  //  Mark single as read
  static Future<void> markRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  //  Mark all as read
  static Future<void> markAllRead(String uid) async {
    final snap = await _db
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
