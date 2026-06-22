import 'package:flutter/material.dart';
import '../../core/db_helper.dart';
import '../../models/schedule_model.dart';
import '../notifications/notification_service.dart';

class ScheduleProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();

  List<ShiftModel> _shifts = [];
  List<ReminderModel> _reminders = [];

  List<ShiftModel> get shifts => _shifts;
  List<ReminderModel> get reminders => _reminders;

  Future<void> loadSchedule() async {
    _shifts = await _dbHelper.getShifts();
    _reminders = await _dbHelper.getReminders();
    notifyListeners();
  }

  // Shift Operations
  Future<void> addShift(ShiftModel shift) async {
    await _dbHelper.insertShift(shift);
    await loadSchedule();
  }

  Future<void> deleteShift(String id) async {
    await _dbHelper.deleteShift(id);
    await loadSchedule();
  }

  // Reminder Operations
  Future<void> addReminder(ReminderModel reminder) async {
    await _dbHelper.insertReminder(reminder);
    if (reminder.isActive) {
      await _notificationService.scheduleReminderNotification(
        reminder.id.hashCode,
        reminder.title,
        reminder.time,
      );
    }
    await loadSchedule();
  }

  Future<void> deleteReminder(String id) async {
    await _dbHelper.deleteReminder(id);
    await _notificationService.cancelReminderNotification(id.hashCode);
    await loadSchedule();
  }

  Future<void> toggleReminderActive(ReminderModel reminder) async {
    final updated = ReminderModel(
      id: reminder.id,
      title: reminder.title,
      time: reminder.time,
      isActive: !reminder.isActive,
    );
    await _dbHelper.insertReminder(updated);
    
    if (updated.isActive) {
      await _notificationService.scheduleReminderNotification(
        updated.id.hashCode,
        updated.title,
        updated.time,
      );
    } else {
      await _notificationService.cancelReminderNotification(updated.id.hashCode);
    }
    await loadSchedule();
  }
}
