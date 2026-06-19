import 'package:flutter/material.dart';
import '../../core/db_helper.dart';
import '../../models/task_model.dart';
import '../notifications/notification_service.dart';

class TaskService with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<TaskModel> _tasks = [];

  List<TaskModel> get tasks => _tasks;

  Future<void> loadTasks() async {
    _tasks = await _dbHelper.getTasks();
    notifyListeners();
  }

  Future<void> addTask(TaskModel task) async {
    await _dbHelper.insertTask(task);
    if (task.type == TaskType.temporary) {
      await NotificationService().scheduleExpiryWarning(task.id, task.name, task.createdAt);
    }
    await loadTasks();
  }

  Future<void> deleteTask(String id) async {
    await _dbHelper.deleteTask(id);
    await loadTasks();
  }

  Future<void> toggleTaskCompletion(TaskModel task) async {
    task.isCompleted = !task.isCompleted;
    await _dbHelper.insertTask(task);
    await loadTasks();
  }
}
