import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
    final isDark = themeProvider.themeMode == ThemeModeType.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: clinicalService.patients.isEmpty
          ? _buildEmptyState(isDark)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: clinicalService.patients.length,
              itemBuilder: (context, index) {
                final patient = clinicalService.patients[index];
                return _buildPatientItem(patient, isDark);
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_patients_screen',
        onPressed: () => _showAddPatientDialog(context),
        backgroundColor: isDark ? const Color(0xFF3B82F6) : Colors.black,
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 16),
          Text(
            'No patients recorded',
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientItem(PatientModel patient, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showVitalsHistory(context, patient),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isDark 
                          ? Colors.white.withOpacity(0.08)
                          : Colors.grey[200],
                      child: Text(
                        patient.name?.isNotEmpty == true ? patient.name![0].toUpperCase() : '?',
                        style: TextStyle(color: isDark ? const Color(0xFF60A5FA) : Colors.black),
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
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Age: ${patient.age ?? "--"} | Weight: ${patient.weight ?? "--"} kg',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_chart_outlined, color: isDark ? const Color(0xFF60A5FA) : Colors.black54),
              onPressed: () => _showLogVitalsDialog(context, patient),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.withAlpha(isDark ? 178 : 128)),
              onPressed: () => _showDeleteConfirmation(context, patient),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PatientModel patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient?'),
        content: Text('Are you sure you want to delete ${patient.name ?? "this patient"}? All logged vitals will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<ClinicalService>(context, listen: false).deletePatient(patient.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
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

  void _showVitalsHistory(BuildContext context, PatientModel patient) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeModeType.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VitalsHistorySheet(patient: patient, isDark: isDark),
    );
  }

  void _showLogVitalsDialog(BuildContext context, PatientModel patient) {
    final spo2Controller = TextEditingController();
    final bpController = TextEditingController();
    final tempController = TextEditingController();
    final hrController = TextEditingController();
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tempController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Temp (°C)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: hrController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Heart Rate (bpm)', border: OutlineInputBorder()),
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
                    temperature: double.tryParse(tempController.text),
                    heartRate: int.tryParse(hrController.text),
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

class _VitalsHistorySheet extends StatefulWidget {
  final PatientModel patient;
  final bool isDark;

  const _VitalsHistorySheet({required this.patient, required this.isDark});

  @override
  State<_VitalsHistorySheet> createState() => _VitalsHistorySheetState();
}

class _VitalsHistorySheetState extends State<_VitalsHistorySheet> {
  List<VitalsRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVitals();
  }

  Future<void> _loadVitals() async {
    setState(() => _isLoading = true);
    final clinicalService = Provider.of<ClinicalService>(context, listen: false);
    final records = await clinicalService.getPatientVitals(widget.patient.id);
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  Future<void> _deleteRecord(VitalsRecord record) async {
    final clinicalService = Provider.of<ClinicalService>(context, listen: false);
    await clinicalService.deleteVitals(record.id);
    _loadVitals();
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 30,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Activity Log: ${widget.patient.name ?? "Unknown"}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? Colors.white : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: widget.isDark ? Colors.white60 : Colors.black54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()))
              : _records.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Column(
                          children: [
                            Icon(Icons.assignment_outlined, size: 48, color: widget.isDark ? Colors.white24 : Colors.black26),
                            const SizedBox(height: 12),
                            Text(
                              'No vital records logged yet.',
                              style: TextStyle(color: widget.isDark ? Colors.white38 : Colors.black38),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _records.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final record = _records[index];
                          final formattedTime = _formatDateTime(record.recordedAt);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        formattedTime,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: widget.isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 6,
                                        children: [
                                          if (record.spo2 != null)
                                            _buildVitalChip('SPO2: ${record.spo2!.toStringAsFixed(0)}%', Icons.air),
                                          if (record.bp != null && record.bp!.isNotEmpty)
                                            _buildVitalChip('BP: ${record.bp}', Icons.favorite),
                                          if (record.temperature != null)
                                            _buildVitalChip('Temp: ${record.temperature}°C', Icons.thermostat),
                                          if (record.heartRate != null)
                                            _buildVitalChip('HR: ${record.heartRate} bpm', Icons.favorite_border),
                                        ],
                                      ),
                                      if (record.notes != null && record.notes!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          record.notes!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: widget.isDark ? Colors.white70 : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => _deleteRecord(record),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildVitalChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.white10 : Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: widget.isDark ? Colors.white60 : Colors.black54),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    try {
      return DateFormat('MMM dd · hh:mm a').format(dt);
    } catch (e) {
      return dt.toIso8601String();
    }
  }
}
