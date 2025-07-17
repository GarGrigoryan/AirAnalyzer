import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_service.dart';

const notificationTask = "checkSensorTimestamp";

class NotificationService {
  static final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _flutterLocalNotificationsPlugin.initialize(settings);
  }

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

  static void registerBackgroundTask() {
    Workmanager().registerPeriodicTask(
      "staleSensorCheckTask",
      notificationTask,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(seconds: 10),
    );
  }

  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      if (task == notificationTask) {
        final firebase = FirebaseService();
        final timestamp = await firebase.getLastTimestamp();
        if (timestamp != null) {
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final diffMinutes = (now - timestamp) ~/ 60;
          if (diffMinutes >= 5) {
            await NotificationService.showStaleDataNotification();
          }
        }
      }
      return Future.value(true);
    });
  }
}
