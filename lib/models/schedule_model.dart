import 'package:uuid/uuid.dart';

class ShiftModel {
  final String id;
  final String title;
  final String time; // e.g. "08:00 AM – 10:00 AM"
  final String date; // e.g. "Today" or a specific date

  ShiftModel({
    String? id,
    required this.title,
    required this.time,
    required this.date,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'time': time,
      'date': date,
    };
  }

  factory ShiftModel.fromMap(Map<String, dynamic> map) {
    return ShiftModel(
      id: map['id'],
      title: map['title'],
      time: map['time'],
      date: map['date'],
    );
  }
}

class ReminderModel {
  final String id;
  final String title;
  final String time; // e.g. "3:00 PM"
  final bool isActive;

  ReminderModel({
    String? id,
    required this.title,
    required this.time,
    this.isActive = true,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'time': time,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'],
      title: map['title'],
      time: map['time'],
      isActive: map['isActive'] == 1,
    );
  }
}
