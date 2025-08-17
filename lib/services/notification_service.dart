import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const notificationTask = "checkSensorTimestamp";
const lastNotifiedKey = "lastNotifiedTimestamp";

class NotificationService {
  static final _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _flutterLocalNotificationsPlugin.initialize(settings);

    const fcmChannel = AndroidNotificationChannel(
      'fcm_channel',
      'Firebase Push Notifications',
      description: 'General push notifications',
      importance: Importance.high,
    );

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(fcmChannel);
  }
}
