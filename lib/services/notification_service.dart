import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const notificationTask = "checkSensorTimestamp";
const lastNotifiedKey = "lastNotifiedTimestamp";

class NotificationService {
  static final _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize notification channels and plugin
  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _flutterLocalNotificationsPlugin.initialize(settings);

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
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(staleChannel);
    await androidPlugin?.createNotificationChannel(fcmChannel);
  }

  /// Show notification about stale sensor data
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

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(lastNotifiedKey, now);
  }

  /// Register periodic background task
  static void registerBackgroundTask() {
    Workmanager().registerPeriodicTask(
      "staleSensorCheckTask",
      notificationTask,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(seconds: 10),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  /// Callback dispatcher for WorkManager
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);
      await _flutterLocalNotificationsPlugin.initialize(settings);

      if (task == notificationTask) {
        final firebase = FirebaseService();
        final timestamp = await firebase.getLastTimestamp(); // in milliseconds
        if (timestamp != null) {
          final now = DateTime.now().millisecondsSinceEpoch;
          final prefs = await SharedPreferences.getInstance();
          final lastNotified = prefs.getInt(lastNotifiedKey) ?? 0;

          final diffMinutes = (now - timestamp) ~/ 60000; // ms → minutes
          final cooldownMinutes = (now - lastNotified) ~/ 60000;

          // Only notify if data is stale and we haven't notified in last 10 minutes
          if (diffMinutes >= 5 && cooldownMinutes >= 10) {
            await showStaleDataNotification();
          }
        }
      }

      return Future.value(true);
    });
  }

  /// Foreground check for stale data
  static Future<void> checkStaleDataForeground() async {
    final firebase = FirebaseService();
    final timestamp = await firebase.getLastTimestamp(); // in milliseconds
    if (timestamp != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final prefs = await SharedPreferences.getInstance();
      final lastNotified = prefs.getInt(lastNotifiedKey) ?? 0;

      final diffMinutes = (now - timestamp) ~/ 60000;
      final cooldownMinutes = (now - lastNotified) ~/ 60000;

      if (diffMinutes >= 5 && cooldownMinutes >= 10) {
        await showStaleDataNotification();
      }
    }
  }
}
