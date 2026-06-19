import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task_model.dart';
import '../models/patient_model.dart';

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
      version: 1,
      onCreate: _onCreate,
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
}
