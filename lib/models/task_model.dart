import 'package:uuid/uuid.dart';

enum TaskType { normal, temporary }

class TaskModel {
  final String id;
  final String name;
  final int durationMinutes;
  final TaskType type;
  final DateTime createdAt;
  bool isCompleted;

  TaskModel({
    String? id,
    required this.name,
    required this.durationMinutes,
    required this.type,
    DateTime? createdAt,
    this.isCompleted = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  bool get isExpired => type == TaskType.temporary && 
      DateTime.now().difference(createdAt).inDays >= 7;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'durationMinutes': durationMinutes,
      'type': type.index,
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'],
      name: map['name'],
      durationMinutes: map['durationMinutes'],
      type: TaskType.values[map['type']],
      createdAt: DateTime.parse(map['createdAt']),
      isCompleted: map['isCompleted'] == 1,
    );
  }
}
