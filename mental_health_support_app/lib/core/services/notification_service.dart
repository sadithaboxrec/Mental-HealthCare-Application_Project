import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await NotificationService.show(
    title: message.notification?.title ?? 'Health Alert',
    body: message.notification?.body ?? '',
    type: message.data['type'] ?? 'general',
  );
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static bool _initialized = false;

  static const String _channelId = 'health_alerts';
  static const String _channelName = 'Health Alerts';

  static Future<void> init() async {
    if (_initialized) return;

    // 1. Request FCM permission
    await _fcm.requestPermission(alert: true, sound: true, badge: true);

    // 2. Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: (NotificationResponse r) {
        debugPrint('Notification tapped: ${r.payload}');
      },
    );

    // 3. Create notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Medication and appointment reminders',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      enableVibration: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(channel);

    // 4. Foreground FCM handler
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      show(
        title: msg.notification?.title ?? 'Health Alert',
        body: msg.notification?.body ?? '',
        type: msg.data['type'] ?? 'general',
      );
    });

    // 5. Background FCM handler
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    _initialized = true;
    debugPrint('NotificationService initialized and running ..======== ');
  }

  // static Future<void> show({
  //   required String title,
  //   required String body,
  //   String type = 'general',
  // }) async {
  //   final bool isAlarm =
  //       type == 'medication' || type == 'appointment';
  //
  //   final AndroidNotificationDetails androidDetails =
  //   AndroidNotificationDetails(
  //     _channelId,
  //     _channelName,
  //     importance:       Importance.max,
  //     priority:         Priority.high,
  //     playSound:        true,
  //     sound:            isAlarm
  //         ? const RawResourceAndroidNotificationSound('alarm_sound')
  //         : null,
  //     enableVibration:  isAlarm,
  //     fullScreenIntent: isAlarm,
  //     autoCancel:       true,
  //     timeoutAfter:     10000,
  //     styleInformation: BigTextStyleInformation(body),
  //   );
  //
  //   await _plugin.show(
  //     DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000,
  //     title,
  //     body,
  //     NotificationDetails(android: androidDetails),
  //   );
  // }

  ///////////////////////
  //  updated below      //
  //////////////////////////

  //
  // static Future<void> saveToken(String uid) async {
  //   try {
  //     final String? token = await _fcm.getToken();
  //     if (token == null) return;
  //     await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(uid)
  //         .update({'fcmToken': token});
  //     _fcm.onTokenRefresh.listen((String t) {
  //       FirebaseFirestore.instance
  //           .collection('users')
  //           .doc(uid)
  //           .update({'fcmToken': t});
  //     });
  //     debugPrint('FCM token saved ✅');
  //   } catch (e) {
  //     debugPrint('Token error: $e');
  //   }
  // }

  static Future<void> saveToken(String uid) async {
    try {
      debugPrint('=== saveToken called for uid: $uid ===');
      final String? token = await _fcm.getToken();
      debugPrint('=== FCM token received: ${token?.substring(0, 20)} ===');

      if (token == null) {
        debugPrint('=== TOKEN IS NULL — FCM not working ===');
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
      });

      debugPrint('=== FCM token saved to Firestore  ===');

      _fcm.onTokenRefresh.listen((String t) {
        FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': t,
        });
      });
    } catch (e) {
      debugPrint('=== Token error: $e ===');
    }
  }

  // When a notification is shown locally, also save it to Firestore.

  static Future<void> show({
    required String title,
    required String body,
    String type = 'general',
    String? uid, // ← add this optional param
  }) async {
    final bool isAlarm = type == 'medication' || type == 'appointment';

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: isAlarm
              ? const RawResourceAndroidNotificationSound('alarm_sound')
              : null,
          enableVibration: isAlarm,
          fullScreenIntent: isAlarm,
          autoCancel: true,
          timeoutAfter: 10000,
          styleInformation: BigTextStyleInformation(body),
        );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );

    // Save to Firestore inbox if uid provided
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('notifications').add({
          'uid': uid,
          'title': title,
          'body': body,
          'type': type,
          'isRead': false,
          'createdAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Inbox save error: $e');
      }
    }
  }
}
