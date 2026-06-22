import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task_model.dart';
import '../models/patient_model.dart';
import '../models/schedule_model.dart';
import '../models/timer_report_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'hora_database.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        name TEXT,
        durationMinutes INTEGER,
        type INTEGER,
        createdAt TEXT,
        isCompleted INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        name TEXT,
        age INTEGER,
        weight REAL,
        gender TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE vitals (
        id TEXT PRIMARY KEY,
        patientId TEXT,
        spo2 REAL,
        bp TEXT,
        temperature REAL,
        heartRate INTEGER,
        notes TEXT,
        recordedAt TEXT,
        FOREIGN KEY (patientId) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE shifts (
        id TEXT PRIMARY KEY,
        title TEXT,
        time TEXT,
        date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        title TEXT,
        time TEXT,
        isActive INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE timer_reports (
        id TEXT PRIMARY KEY,
        patientName TEXT,
        initialDurationSeconds INTEGER,
        elapsedSeconds INTEGER,
        startTime TEXT,
        status TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS patients (
          id TEXT PRIMARY KEY,
          name TEXT,
          age INTEGER,
          weight REAL,
          gender TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS vitals (
          id TEXT PRIMARY KEY,
          patientId TEXT,
          spo2 REAL,
          bp TEXT,
          temperature REAL,
          heartRate INTEGER,
          notes TEXT,
          recordedAt TEXT,
          FOREIGN KEY (patientId) REFERENCES patients (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS shifts (
          id TEXT PRIMARY KEY,
          title TEXT,
          time TEXT,
          date TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS reminders (
          id TEXT PRIMARY KEY,
          title TEXT,
          time TEXT,
          isActive INTEGER
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS timer_reports (
          id TEXT PRIMARY KEY,
          patientName TEXT,
          initialDurationSeconds INTEGER,
          elapsedSeconds INTEGER,
          startTime TEXT,
          status TEXT
        )
      ''');
    }
  }

  // Task Operations
  Future<void> insertTask(TaskModel task) async {
    final db = await database;
    await db.insert('tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TaskModel>> getTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => TaskModel.fromMap(maps[i]));
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteExpiredTasks() async {
    final db = await database;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    await db.delete(
      'tasks',
      where: 'type = ? AND createdAt < ?',
      whereArgs: [TaskType.temporary.index, sevenDaysAgo],
    );
  }

  // Patient Operations
  Future<void> insertPatient(PatientModel patient) async {
    final db = await database;
    await db.insert('patients', patient.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<PatientModel>> getPatients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('patients');
    return List.generate(maps.length, (i) => PatientModel.fromMap(maps[i]));
  }

  Future<void> deletePatient(String id) async {
    final db = await database;
    await db.delete('vitals', where: 'patientId = ?', whereArgs: [id]);
    await db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }

  // Vitals Operations
  Future<void> insertVitals(VitalsRecord vitals) async {
    final db = await database;
    await db.insert('vitals', vitals.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<VitalsRecord>> getVitals(String patientId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vitals',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'recordedAt DESC',
    );
    return List.generate(maps.length, (i) => VitalsRecord.fromMap(maps[i]));
  }

  Future<void> deleteVitals(String id) async {
    final db = await database;
    await db.delete('vitals', where: 'id = ?', whereArgs: [id]);
  }

  // Shift Operations
  Future<void> insertShift(ShiftModel shift) async {
    final db = await database;
    await db.insert('shifts', shift.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ShiftModel>> getShifts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('shifts');
    return List.generate(maps.length, (i) => ShiftModel.fromMap(maps[i]));
  }

  Future<void> deleteShift(String id) async {
    final db = await database;
    await db.delete('shifts', where: 'id = ?', whereArgs: [id]);
  }

  // Reminder Operations
  Future<void> insertReminder(ReminderModel reminder) async {
    final db = await database;
    await db.insert('reminders', reminder.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ReminderModel>> getReminders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('reminders');
    return List.generate(maps.length, (i) => ReminderModel.fromMap(maps[i]));
  }

  Future<void> deleteReminder(String id) async {
    final db = await database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('tasks');
    await db.delete('patients');
    await db.delete('vitals');
    await db.delete('shifts');
    await db.delete('reminders');
    await db.delete('timer_reports');
  }

  // Timer Report Operations
  Future<void> insertTimerReport(TimerReportModel report) async {
    final db = await database;
    await db.insert('timer_reports', report.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TimerReportModel>> getTimerReports() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('timer_reports', orderBy: 'startTime DESC');
    return List.generate(maps.length, (i) => TimerReportModel.fromMap(maps[i]));
  }

  Future<void> deleteTimerReport(String id) async {
    final db = await database;
    await db.delete('timer_reports', where: 'id = ?', whereArgs: [id]);
  }
}
