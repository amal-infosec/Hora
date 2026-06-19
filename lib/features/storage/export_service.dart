import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/db_helper.dart';

class ExportService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<String> exportClinicalData() async {
    final patients = await _dbHelper.getPatients();
    List<List<dynamic>> rows = [];

    // Header
    rows.add(["Patient ID", "Name", "Age", "Weight", "SPO2", "BP", "Notes", "Date"]);

    for (var patient in patients) {
      final vitals = await _dbHelper.getVitals(patient.id);
      if (vitals.isEmpty) {
        rows.add([patient.id, patient.name, patient.age, patient.weight, "", "", "", ""]);
      } else {
        for (var record in vitals) {
          rows.add([
            patient.id,
            patient.name,
            patient.age,
            patient.weight,
            record.spo2,
            record.bp,
            record.notes,
            record.recordedAt.toIso8601String(),
          ]);
        }
      }
    }

    String csvData = const ListToCsvConverter().convert(rows);
    
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/hora_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    
    await file.writeAsString(csvData);
    return file.path;
  }
}
