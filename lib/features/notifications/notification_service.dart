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
        AndroidInitializationSettings('launcher_icon');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones();

    // Request notification permission programmatically for Android 13+ (API 33+)
    try {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      // Suppress exceptions on unsupported platforms or versions
    }
  }

  Future<void> scheduleExpiryWarning(String taskId, String taskName, DateTime createdAt) async {
    final expiryDate = createdAt.add(const Duration(days: 7));
    final warningDate = expiryDate.subtract(const Duration(days: 1)); // 6 days later

    if (warningDate.isBefore(DateTime.now())) return;

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        taskId.hashCode,
        'Task Expiring Soon',
        'The temporary task "$taskName" will be deleted in 24 hours.',
        tz.TZDateTime.from(warningDate.toUtc(), tz.UTC),
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
    } catch (e) {
      // Graceful fallback to inexact scheduling if exact alarm permission is denied or restricted
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          taskId.hashCode,
          'Task Expiring Soon',
          'The temporary task "$taskName" will be deleted in 24 hours.',
          tz.TZDateTime.from(warningDate.toUtc(), tz.UTC),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'task_expiry',
              'Task Expiry Warnings',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (ex) {
        // Suppress scheduling errors
      }
    }
  }

  Future<void> scheduleReminderNotification(int id, String title, String timeStr) async {
    try {
      // Parse e.g. "03:00 PM" or "3:00 PM"
      final parts = timeStr.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      if (parts.length > 1) {
        final ampm = parts[1].toLowerCase();
        if (ampm == 'pm' && hour < 12) hour += 12;
        if (ampm == 'am' && hour == 12) hour = 0;
      }
      
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final scheduledUtc = scheduledDate.toUtc();

      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          'Reminder: $title',
          'Time to complete your scheduled task ($timeStr).',
          tz.TZDateTime.from(scheduledUtc, tz.UTC),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'shift_reminders',
              'Shift Reminders',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time, // repeat daily at this time!
        );
      } catch (e) {
        // Graceful fallback to inexact scheduling if exact alarm permission is denied or restricted
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          'Reminder: $title',
          'Time to complete your scheduled task ($timeStr).',
          tz.TZDateTime.from(scheduledUtc, tz.UTC),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'shift_reminders',
              'Shift Reminders',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    } catch (e) {
      // Suppress format exceptions
    }
  }

  Future<void> cancelReminderNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
