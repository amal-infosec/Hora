class TimerReportModel {
  final String id;
  final String patientName;
  final int initialDurationSeconds;
  final int elapsedSeconds;
  final String startTime; // ISO format string
  final String status;    // "Completed" or "Stopped"

  TimerReportModel({
    required this.id,
    required this.patientName,
    required this.initialDurationSeconds,
    required this.elapsedSeconds,
    required this.startTime,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientName': patientName,
      'initialDurationSeconds': initialDurationSeconds,
      'elapsedSeconds': elapsedSeconds,
      'startTime': startTime,
      'status': status,
    };
  }

  factory TimerReportModel.fromMap(Map<String, dynamic> map) {
    return TimerReportModel(
      id: map['id'] ?? '',
      patientName: map['patientName'] ?? 'General',
      initialDurationSeconds: map['initialDurationSeconds'] ?? 0,
      elapsedSeconds: map['elapsedSeconds'] ?? 0,
      startTime: map['startTime'] ?? '',
      status: map['status'] ?? 'Stopped',
    );
  }
}
