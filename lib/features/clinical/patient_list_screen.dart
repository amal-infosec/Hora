import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/patient_model.dart';
import '../../widgets/glass_container.dart';
import '../../core/app_themes.dart';
import 'clinical_service.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClinicalService>(context, listen: false).loadPatients();
    });
  }

  @override
  Widget build(BuildContext context) {
    final clinicalService = Provider.of<ClinicalService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isGlass = themeProvider.themeMode == ThemeModeType.liquidGlass;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: clinicalService.patients.isEmpty
          ? _buildEmptyState(isGlass)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: clinicalService.patients.length,
              itemBuilder: (context, index) {
                final patient = clinicalService.patients[index];
                return _buildPatientItem(patient, isGlass);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPatientDialog(context),
        backgroundColor: isGlass ? const Color(0xFF3B82F6) : Colors.black,
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(bool isGlass) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: isGlass ? const Color(0xFFCBD5E1) : Colors.black12),
          const SizedBox(height: 16),
          Text(
            'No patients recorded',
            style: TextStyle(color: isGlass ? const Color(0xFF64748B) : Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientItem(PatientModel patient, bool isGlass) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isGlass ? const Color(0xFF3B82F6).withAlpha(51) : Colors.grey[200], // 0.2 * 255 = 51
              child: Text(
                patient.name?.isNotEmpty == true ? patient.name![0].toUpperCase() : '?',
                style: TextStyle(color: isGlass ? const Color(0xFF3B82F6) : Colors.black),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.name ?? 'Unknown Patient',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isGlass ? const Color(0xFF1E293B) : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Age: ${patient.age ?? "--"} | Weight: ${patient.weight ?? "--"} kg',
                    style: TextStyle(fontSize: 12, color: isGlass ? const Color(0xFF64748B) : Colors.black54),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_chart_outlined, color: isGlass ? const Color(0xFF3B82F6) : Colors.black54),
              onPressed: () => _showLogVitalsDialog(context, patient),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPatientDialog(BuildContext context) {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final weightController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: 30,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Patient', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Patient Name (Optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final patient = PatientModel(
                    name: nameController.text.isEmpty ? null : nameController.text,
                    age: int.tryParse(ageController.text),
                    weight: double.tryParse(weightController.text),
                  );
                  Provider.of<ClinicalService>(context, listen: false).addPatient(patient);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Save Patient', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogVitalsDialog(BuildContext context, PatientModel patient) {
    final spo2Controller = TextEditingController();
    final bpController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: 30,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log Vitals - ${patient.name ?? "Unknown"}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: spo2Controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'SPO2 %', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: bpController,
                    decoration: const InputDecoration(labelText: 'BP (e.g. 120/80)', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes (e.g. Monitor IV 30 min)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final vitals = VitalsRecord(
                    patientId: patient.id,
                    spo2: double.tryParse(spo2Controller.text),
                    bp: bpController.text.isEmpty ? null : bpController.text,
                    notes: notesController.text.isEmpty ? null : notesController.text,
                  );
                  Provider.of<ClinicalService>(context, listen: false).logVitals(vitals);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Log Entry', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
