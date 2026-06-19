import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones();
  }

  Future<void> scheduleExpiryWarning(String taskId, String taskName, DateTime createdAt) async {
    final expiryDate = createdAt.add(const Duration(days: 7));
    final warningDate = expiryDate.subtract(const Duration(days: 1)); // 6 days later

    if (warningDate.isBefore(DateTime.now())) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      taskId.hashCode,
      'Task Expiring Soon',
      'The temporary task "$taskName" will be deleted in 24 hours.',
      tz.TZDateTime.from(warningDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_expiry',
          'Task Expiry Warnings',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
