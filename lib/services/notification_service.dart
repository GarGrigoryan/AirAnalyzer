import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_service.dart';

const notificationTask = "checkSensorTimestamp";

class NotificationService {
  static final _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize notification plugin + channels
  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _flutterLocalNotificationsPlugin.initialize(settings);

    // Create channels so remote FCM can post into them
    const staleChannel = AndroidNotificationChannel(
      'stale_data_channel',
      'Stale Sensor Data',
      description: 'Alerts when sensor data is older than 5 minutes',
      importance: Importance.high,
    );
    const fcmChannel = AndroidNotificationChannel(
      'fcm_channel',
      'Firebase Push Notifications',
      description: 'General push notifications',
      importance: Importance.high,
    );

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(staleChannel);
    await androidPlugin?.createNotificationChannel(fcmChannel);
  }

  /// Local notification (used for WorkManager fallback or manual trigger)
  static Future<void> showStaleDataNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'stale_data_channel',
      'Stale Sensor Data',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notifDetails = NotificationDetails(android: androidDetails);
    await _flutterLocalNotificationsPlugin.show(
      1,
      'Device might be offline',
      'No new sensor data received for 5+ minutes',
      notifDetails,
    );
  }

  /// Register WorkManager task (OPTIONAL: only if you want local checking as backup)
  static void registerBackgroundTask() {
    Workmanager().registerPeriodicTask(
      "staleSensorCheckTask",
      notificationTask,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(seconds: 10),
    );
  }

  /// Background check logic for WorkManager (OPTIONAL)
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);
      await _flutterLocalNotificationsPlugin.initialize(settings);

      if (task == notificationTask) {
        final firebase = FirebaseService();
        final timestamp = await firebase.getLastTimestamp();
        if (timestamp != null) {
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final diffMinutes = (now - timestamp) ~/ 60;
          if (diffMinutes >= 5) {
            await showStaleDataNotification();
          }
        }
      }

      return Future.value(true);
    });
  }
}
