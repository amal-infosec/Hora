import 'package:flutter/material.dart';
import '../../core/db_helper.dart';
import '../../models/patient_model.dart';

class ClinicalService with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<PatientModel> _patients = [];

  List<PatientModel> get patients => _patients;

  Future<void> loadPatients() async {
    _patients = await _dbHelper.getPatients();
    notifyListeners();
  }

  Future<void> addPatient(PatientModel patient) async {
    await _dbHelper.insertPatient(patient);
    await loadPatients();
  }

  Future<void> deletePatient(String id) async {
    await _dbHelper.deletePatient(id);
    await loadPatients();
  }

  Future<void> logVitals(VitalsRecord vitals) async {
    await _dbHelper.insertVitals(vitals);
    notifyListeners();
  }

  Future<List<VitalsRecord>> getPatientVitals(String patientId) async {
    return await _dbHelper.getVitals(patientId);
  }

  Future<void> deleteVitals(String id) async {
    await _dbHelper.deleteVitals(id);
    notifyListeners();
  }
}
