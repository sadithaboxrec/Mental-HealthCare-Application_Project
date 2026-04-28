import 'package:flutter_test/flutter_test.dart';
import 'package:mental_health_support_app/core/models/app_notification.dart';

void main() {
  group('AppNotification', () {
    test(
      'maps notification fields and defaults unread general notifications',
      () {
        final notification = AppNotification.fromMap('notification-1', {
          'uid': 'patient-1',
          'title': 'Medication reminder',
          'body': 'Take your morning medication.',
          'createdAt': '2026-04-28T08:00:00Z',
        });

        expect(notification.id, 'notification-1');
        expect(notification.type, 'general');
        expect(notification.isRead, isFalse);
        expect(notification.toMap(), {
          'uid': 'patient-1',
          'title': 'Medication reminder',
          'body': 'Take your morning medication.',
          'type': 'general',
          'isRead': false,
          'createdAt': '2026-04-28T08:00:00Z',
        });
      },
    );
  });
}
