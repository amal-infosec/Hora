import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:vibration/vibration.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:system_alert_window/system_alert_window.dart';
import '../../core/app_themes.dart';
import '../../core/db_helper.dart';
import '../../models/patient_model.dart';
import '../../widgets/glass_container.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int _secondsRemaining = 0;
  Timer? _timer;
  bool _isRunning = false;
  int _initialDuration = 0;
  String _selectedSound = 'Clinical Beep';
  String _alertMode = 'Both'; // 'Sound', 'Vibration', 'Both'
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _intervalSeconds = 0; // 0 means no interval alert
  StreamSubscription? _serviceSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _listenToBackgroundService();
  }

  Future<void> _checkPermissions() async {
    await SystemAlertWindow.requestPermissions(prefMode: SystemWindowPrefMode.OVERLAY);
  }

  void _listenToBackgroundService() {
    _serviceSubscription = FlutterBackgroundService().on('update').listen((event) {
      if (event != null && mounted) {
        setState(() {
          _secondsRemaining = event['secondsRemaining'];
          _isRunning = event['isRunning'];
          
          if (_secondsRemaining == 0 && _isRunning == false) {
            _showCompletionDialog();
            _isRunning = false;
          }
        });
      }
    });
  }

  final List<String> _medicalSounds = [
    'Clinical Beep',
    'Vital Alert (Soft)',
    'Emergency Pulse',
    'IV Completion Blip',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _bpController = TextEditingController();

  void _startTimer() {
    if (_secondsRemaining == 0) return;
    
    // Only show form if not already running to prevent double-prompts
    if (!_isRunning) {
      _showVitalsForm();
    } else {
      _resumeTimer();
    }
  }

  void _resumeTimer() async {
    setState(() {
      _isRunning = true;
    });

    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    
    if (!isRunning) {
      await service.startService();
    }

    service.invoke('startTimer', {
      'duration': _secondsRemaining,
      'intervalSeconds': _intervalSeconds,
      'sound': _selectedSound,
      'alertMode': _alertMode,
    });
  }

  Future<void> _saveVitalsAndStart() async {
    if (_formKey.currentState!.validate()) {
      // Create and save Patient
      final patientId = DateTime.now().millisecondsSinceEpoch.toString();
      final patient = PatientModel(
        id: patientId,
        name: _nameController.text,
        age: int.tryParse(_ageController.text) ?? 0,
        weight: double.tryParse(_weightController.text) ?? 0.0,
      );
      await DatabaseHelper().insertPatient(patient);

      // Create and save Vitals
      final vitalsId = DateTime.now().millisecondsSinceEpoch.toString() + "_vt";
      final vitals = VitalsRecord(
        id: vitalsId,
        patientId: patientId,
        spo2: double.tryParse(_spo2Controller.text) ?? 0.0,
        bp: _bpController.text,
        recordedAt: DateTime.now(),
        notes: "Started Timer for ${_formatTime(_initialDuration)} with ${_intervalSeconds}s interval",
      );
      await DatabaseHelper().insertVitals(vitals);

      Navigator.pop(context); // Close form
      _resumeTimer(); // Start timer
    }
  }

  void _stopTimer() {
    FlutterBackgroundService().invoke('stopService');
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _stopTimer();
    _audioPlayer.stop();
    setState(() {
      _secondsRemaining = _initialDuration;
    });
  }

  void _setDuration(Duration duration) {
    if (_isRunning) _stopTimer();
    setState(() {
      _initialDuration = duration.inSeconds;
      _secondsRemaining = _initialDuration;
    });
    Vibration.vibrate(duration: 50, amplitude: 64);
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return '${hours > 0 ? '${hours.toString().padLeft(2, '0')}:' : ''}${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Timer Finished'),
        content: const Text('Clinical task duration completed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _triggerAlert({bool isCompletion = false}) async {
    if (_alertMode == 'Vibration' || _alertMode == 'Both') {
      if (isCompletion) {
        // Powerful haptic sequence
        for (int i = 0; i < 3; i++) {
          Vibration.vibrate(duration: 500, amplitude: 255);
          await Future.delayed(const Duration(milliseconds: 700));
        }
      } else {
        Vibration.vibrate(duration: 150, amplitude: 128);
      }
    }

    if (_alertMode == 'Sound' || _alertMode == 'Both') {
      await _audioPlayer.stop();
      if (_selectedSound.startsWith('/')) {
        await _audioPlayer.play(DeviceFileSource(_selectedSound));
      } else {
        String assetPath;
        switch (_selectedSound) {
          case 'Emergency Pulse':
            assetPath = 'sounds/emergency_pulse.ogg';
            break;
          case 'Vital Alert (Soft)':
            assetPath = 'sounds/vital_alert.ogg';
            break;
          case 'IV Completion Blip':
            assetPath = 'sounds/iv_completion.ogg';
            break;
          case 'Clinical Beep':
          default:
            assetPath = 'sounds/clinical_beep.ogg';
            break;
        }
        await _audioPlayer.play(AssetSource(assetPath));
      }
    }
  }

  void _previewAlert() {
    _triggerAlert(isCompletion: false);
  }

  Future<void> _pickCustomRingtone() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedSound = result.files.single.path!;
        // Add to the top of the list if not there
        if (!_medicalSounds.contains(_selectedSound)) {
          _medicalSounds.insert(0, _selectedSound);
        }
      });
      _previewAlert();
    }
  }

  @override
  void dispose() {
    _serviceSubscription?.cancel();
    _audioPlayer.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _spo2Controller.dispose();
    _bpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGlass = Provider.of<ThemeProvider>(context).themeMode == ThemeModeType.liquidGlass;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTimerDisplay(isGlass),
          const SizedBox(height: 32),
          _buildCustomSelectors(isGlass),
          const SizedBox(height: 32),
          _buildControls(isGlass),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(bool isGlass) {
    return Center(
      child: GlassContainer(
        borderRadius: 150,
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Text(
              _formatTime(_secondsRemaining),
              style: GoogleFonts.outfit(
                fontSize: 64,
                fontWeight: FontWeight.w300,
                color: isGlass ? const Color(0xFF1E293B) : Colors.black,
              ),
            ),
            Text(
              'REMAINING',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 4,
                color: isGlass ? const Color(0xFF64748B) : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSelectors(bool isGlass) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSelectorButton(
              context, 
              isGlass, 
              title: 'Duration', 
              value: _initialDuration == 0 ? 'Set Time' : _formatTime(_initialDuration),
              onTap: () => _showDurationPicker(context, isGlass),
            ),
            _buildSelectorButton(
              context, 
              isGlass, 
              title: 'Intervals', 
              value: _intervalSeconds == 0 ? 'None' : '${_intervalSeconds ~/ 60}m ${_intervalSeconds % 60}s',
              onTap: () => _showIntervalPicker(context, isGlass),
            ),
          ],
        ),
      ],
    );
  }

  void _showVitalsForm() {
    final isGlass = Provider.of<ThemeProvider>(context, listen: false).themeMode == ThemeModeType.liquidGlass;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Patient Vitals', style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold,
                    color: isGlass ? const Color(0xFF1E293B) : Colors.black
                  )),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: isGlass ? const Color(0xFF1E293B) : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Patient Name',
                      labelStyle: TextStyle(color: isGlass ? Colors.white70 : Colors.black54),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: isGlass ? const Color(0xFF1E293B) : Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Age',
                            labelStyle: TextStyle(color: isGlass ? Colors.white70 : Colors.black54),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: isGlass ? const Color(0xFF1E293B) : Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Weight (kg)',
                            labelStyle: TextStyle(color: isGlass ? Colors.white70 : Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _spo2Controller,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: isGlass ? const Color(0xFF1E293B) : Colors.black),
                          decoration: InputDecoration(
                            labelText: 'SPO2 (%)',
                            labelStyle: TextStyle(color: isGlass ? Colors.white70 : Colors.black54),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _bpController,
                          style: TextStyle(color: isGlass ? const Color(0xFF1E293B) : Colors.black),
                          decoration: InputDecoration(
                            labelText: 'BP (e.g. 120/80)',
                            labelStyle: TextStyle(color: isGlass ? Colors.white70 : Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: TextStyle(color: isGlass ? const Color(0xFF64748B) : Colors.black54)),
                      ),
                      ElevatedButton(
                        onPressed: _saveVitalsAndStart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isGlass ? const Color(0xFF3B82F6) : Colors.black,
                        ),
                        child: const Text('Start Timer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorButton(BuildContext context, bool isGlass, {required String title, required String value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isGlass ? const Color(0xFF64748B) : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isGlass ? const Color(0xFF1E293B) : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDurationPicker(BuildContext context, bool isGlass) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext builder) {
        return GlassContainer(
          borderRadius: 30,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Set Timer Duration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 200,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      pickerTextStyle: TextStyle(color: isGlass ? const Color(0xFF1E293B) : Colors.black, fontSize: 24),
                    ),
                  ),
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hm,
                    initialTimerDuration: Duration(seconds: _initialDuration),
                    onTimerDurationChanged: (Duration newDuration) {
                      _setDuration(newDuration);
                    },
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              )
            ],
          ),
        );
      },
    );
  }

  void _showIntervalPicker(BuildContext context, bool isGlass) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext builder) {
        return GlassContainer(
          borderRadius: 30,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Set Alerts Interval', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 200,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      pickerTextStyle: TextStyle(color: isGlass ? const Color(0xFF1E293B) : Colors.black, fontSize: 24),
                    ),
                  ),
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.ms,
                    initialTimerDuration: Duration(seconds: _intervalSeconds),
                    onTimerDurationChanged: (Duration newDuration) {
                      setState(() {
                        _intervalSeconds = newDuration.inSeconds;
                      });
                      Vibration.vibrate(duration: 50, amplitude: 64);
                    },
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls(bool isGlass) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _resetTimer,
          icon: Icon(Icons.refresh, size: 32, color: isGlass ? const Color(0xFF64748B) : Colors.black38),
        ),
        const SizedBox(width: 32),
        GestureDetector(
          onTap: _isRunning ? _stopTimer : _startTimer,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isGlass ? const Color(0xFF3B82F6) : Colors.black,
              boxShadow: [
                BoxShadow(
                  color: (isGlass ? const Color(0xFF3B82F6) : Colors.black).withAlpha(77), // 0.3 * 255 = 76.5 -> 77
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              _isRunning ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        const SizedBox(width: 32),
        IconButton(
          onPressed: () => _showSoundPicker(context, isGlass),
          icon: Icon(Icons.music_note, size: 32, color: isGlass ? const Color(0xFF64748B) : Colors.black38),
        ),
      ],
    );
  }

  void _showSoundPicker(BuildContext context, bool isGlass) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: 30,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Alert Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Mode Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['Sound', 'Vibration', 'Both'].map((mode) => ChoiceChip(
                label: Text(mode, style: TextStyle(color: isGlass ? const Color(0xFF1E293B) : Colors.black)),
                selected: _alertMode == mode,
                selectedColor: isGlass ? const Color(0xFF3B82F6).withAlpha(128) : Colors.black26,
                backgroundColor: Colors.transparent,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _alertMode = mode);
                    _previewAlert();
                  }
                },
              )).toList(),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.upload_file, color: isGlass ? const Color(0xFF3B82F6) : Colors.black),
              title: Text('Import Custom Ringtone', style: TextStyle(color: isGlass ? const Color(0xFF3B82F6) : Colors.black, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _pickCustomRingtone();
              },
            ),
            const Divider(),
            ..._medicalSounds.map((sound) => ListTile(
              title: Text(
                sound.startsWith('/') ? sound.split('/').last : sound, 
                style: TextStyle(color: isGlass ? const Color(0xFF1E293B) : Colors.black)
              ),
              trailing: _selectedSound == sound 
                  ? Icon(Icons.check_circle, color: isGlass ? const Color(0xFF3B82F6) : Colors.black) 
                  : null,
              onTap: () {
                setState(() => _selectedSound = sound);
                _previewAlert();
              },
            )),
          ],
        ),
      ),
    );
  }
}
