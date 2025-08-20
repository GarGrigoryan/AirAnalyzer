import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  static Future<void> init() async {
    await _messaging.requestPermission();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("⚠️ User not logged in, cannot save FCM token.");
      return;
    }

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToDatabase(user.uid, token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print("♻️ Refreshed FCM Token: $newToken");
      await _saveTokenToDatabase(user.uid, newToken);
    });

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showNotification(message.notification!);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📲 App opened via notification: ${message.messageId}");
    });
  }

  static Future<void> _saveTokenToDatabase(String uid, String token) async {
    final ref = _database.ref("devices/$uid");
    await ref.update({
      'fcmToken': token,
      'tokenUpdatedAt': ServerValue.timestamp,
    });
    print("✅ Saved FCM token for user $uid to Realtime Database");
  }

  static void _showNotification(RemoteNotification notification) {
    const androidDetails = AndroidNotificationDetails(
      'fcm_channel',
      'Firebase Push Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notifDetails = NotificationDetails(android: androidDetails);
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notifDetails,
    );
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 [Background/Terminated] FCM message: ${message.messageId}');
}
