import 'package:uuid/uuid.dart';

class PatientModel {
  final String id;
  final String? name;
  final int? age;
  final double? weight;
  final String? gender;

  PatientModel({
    String? id,
    this.name,
    this.age,
    this.weight,
    this.gender,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'weight': weight,
      'gender': gender,
    };
  }

  factory PatientModel.fromMap(Map<String, dynamic> map) {
    return PatientModel(
      id: map['id'],
      name: map['name'],
      age: map['age'],
      weight: map['weight'],
      gender: map['gender'],
    );
  }
}

class VitalsRecord {
  final String id;
  final String patientId;
  final double? spo2;
  final String? bp; // e.g. "120/80"
  final double? temperature;
  final int? heartRate;
  final String? notes;
  final DateTime recordedAt;

  VitalsRecord({
    String? id,
    required this.patientId,
    this.spo2,
    this.bp,
    this.temperature,
    this.heartRate,
    this.notes,
    DateTime? recordedAt,
  })  : id = id ?? const Uuid().v4(),
        recordedAt = recordedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'spo2': spo2,
      'bp': bp,
      'temperature': temperature,
      'heartRate': heartRate,
      'notes': notes,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  factory VitalsRecord.fromMap(Map<String, dynamic> map) {
    return VitalsRecord(
      id: map['id'],
      patientId: map['patientId'],
      spo2: map['spo2'],
      bp: map['bp'],
      temperature: map['temperature'],
      heartRate: map['heartRate'],
      notes: map['notes'],
      recordedAt: DateTime.parse(map['recordedAt']),
    );
  }
}
