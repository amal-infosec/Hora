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
import '../../models/patient_model.dart';
import '../../widgets/glass_container.dart';
import '../clinical/clinical_service.dart';
import '../../core/settings_provider.dart';
import 'timer_provider.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _intervalSeconds = 0; // 0 means no interval alert
  StreamSubscription? _serviceSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _listenToBackgroundService();

    // Load custom sound into list if exists in settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      if (settings.selectedSound.startsWith('/') && !_medicalSounds.contains(settings.selectedSound)) {
        setState(() {
          _medicalSounds.insert(0, settings.selectedSound);
        });
      }
    });
  }

  Future<void> _checkPermissions() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.enableOverlayAlerts) {
      try {
        bool? hasPermission = await SystemAlertWindow.checkPermissions(prefMode: SystemWindowPrefMode.OVERLAY);
        if (hasPermission != true) {
          await SystemAlertWindow.requestPermissions(prefMode: SystemWindowPrefMode.OVERLAY);
        }
      } catch (e) {
        // Suppress permission check exceptions on restricted environments
      }
    }
  }

  void _listenToBackgroundService() {
    _serviceSubscription = FlutterBackgroundService().on('update').listen((event) {
      if (event != null && mounted) {
        final secondsRemaining = event['secondsRemaining'] ?? 0;
        final isRunning = event['isRunning'] ?? false;
        
        if (secondsRemaining == 0 && isRunning == false) {
          _showCompletionDialog();
        }
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
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    if (timerProvider.secondsRemaining == 0) return;
    
    // Only show form if not already running or paused to prevent double-prompts
    if (!timerProvider.isRunning && !timerProvider.isPaused) {
      _showVitalsForm();
    } else if (timerProvider.isPaused) {
      timerProvider.resumeTimer();
    } else {
      _resumeTimer();
    }
  }

  void _resumeTimer() async {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    timerProvider.startTimer(
      timerProvider.secondsRemaining,
      _intervalSeconds,
      settings.selectedSound,
      settings.alertMode,
      patientName: _nameController.text.isNotEmpty ? _nameController.text : 'General',
      alarmDuration: settings.alarmDuration,
    );
  }

  Future<void> _saveVitalsAndStart() async {
    if (_formKey.currentState!.validate()) {
      final timerProvider = Provider.of<TimerProvider>(context, listen: false);
      
      // Create and save Patient
      final patientId = DateTime.now().millisecondsSinceEpoch.toString();
      final patient = PatientModel(
        id: patientId,
        name: _nameController.text,
        age: int.tryParse(_ageController.text) ?? 0,
        weight: double.tryParse(_weightController.text) ?? 0.0,
      );
      
      final clinicalService = Provider.of<ClinicalService>(context, listen: false);
      await clinicalService.addPatient(patient);

      // Create and save Vitals
      final vitalsId = "${DateTime.now().millisecondsSinceEpoch}_vt";
      final vitals = VitalsRecord(
        id: vitalsId,
        patientId: patientId,
        spo2: double.tryParse(_spo2Controller.text) ?? 0.0,
        bp: _bpController.text,
        recordedAt: DateTime.now(),
        notes: "Started Timer for ${_formatTime(timerProvider.initialDuration)} with ${_intervalSeconds}s interval",
      );
      await clinicalService.logVitals(vitals);

      if (!mounted) return;
      Navigator.pop(context); // Close form
      _resumeTimer(); // Start timer
    }
  }

  void _stopTimer() {
    Provider.of<TimerProvider>(context, listen: false).stopTimer();
  }

  void _resetTimer() {
    Provider.of<TimerProvider>(context, listen: false).resetTimer();
    _audioPlayer.stop();
  }

  void _setDuration(Duration duration) {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    if (timerProvider.isRunning) _stopTimer();
    timerProvider.setDuration(duration.inSeconds);
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
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final alertMode = settings.alertMode;
    final selectedSound = settings.selectedSound;

    if (alertMode == 'Vibration' || alertMode == 'Both') {
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

    if (alertMode == 'Sound' || alertMode == 'Both') {
      await _audioPlayer.stop();
      if (selectedSound.startsWith('/')) {
        await _audioPlayer.play(DeviceFileSource(selectedSound));
      } else {
        String assetPath;
        switch (selectedSound) {
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
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      final customPath = result.files.single.path!;
      await settings.setSelectedSound(customPath);

      setState(() {
        // Add to the top of the list if not there
        if (!_medicalSounds.contains(customPath)) {
          _medicalSounds.insert(0, customPath);
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeModeType.dark;
    final timerProvider = Provider.of<TimerProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTimerDisplay(isDark, timerProvider),
          const SizedBox(height: 32),
          _buildCustomSelectors(isDark, timerProvider),
          const SizedBox(height: 32),
          _buildControls(isDark, timerProvider),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(bool isDark, TimerProvider timerProvider) {
    return Center(
      child: GlassContainer(
        borderRadius: 150,
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Text(
              _formatTime(timerProvider.secondsRemaining),
              style: GoogleFonts.outfit(
                fontSize: 64,
                fontWeight: FontWeight.w300,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            Text(
              'REMAINING',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 4,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSelectors(bool isDark, TimerProvider timerProvider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSelectorButton(
              context, 
              isDark,
              title: 'Duration', 
              value: timerProvider.initialDuration == 0 ? 'Set Time' : _formatTime(timerProvider.initialDuration),
              onTap: () => _showDurationPicker(context, isDark, timerProvider),
            ),
            _buildSelectorButton(
              context, 
              isDark,
              title: 'Intervals', 
              value: _intervalSeconds == 0 ? 'None' : '${_intervalSeconds ~/ 60}m ${_intervalSeconds % 60}s',
              onTap: () => _showIntervalPicker(context, isDark),
            ),
          ],
        ),
      ],
    );
  }

  void _showVitalsForm() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeModeType.dark;
    
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
                    color: isDark ? Colors.white : Colors.black
                  )),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Patient Name',
                      labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Age',
                            labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Weight (kg)',
                            labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
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
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            labelText: 'SPO2 (%)',
                            labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _bpController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            labelText: 'BP (e.g. 120/80)',
                            labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
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
                        child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
                      ),
                      ElevatedButton(
                        onPressed: _saveVitalsAndStart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF3B82F6) : Colors.black,
                          foregroundColor: Colors.white,
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

  Widget _buildSelectorButton(BuildContext context, bool isDark, {required String title, required String value, required VoidCallback onTap}) {
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
                color: isDark ? Colors.white38 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDurationPicker(BuildContext context, bool isDark, TimerProvider timerProvider) {
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
              Text('Set Timer Duration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              SizedBox(
                height: 200,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      pickerTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24),
                    ),
                  ),
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hm,
                    initialTimerDuration: Duration(seconds: timerProvider.initialDuration),
                    onTimerDurationChanged: (Duration newDuration) {
                      _setDuration(newDuration);
                    },
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF3B82F6) : Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Done'),
              )
            ],
          ),
        );
      },
    );
  }

  void _showIntervalPicker(BuildContext context, bool isDark) {
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
              Text('Set Alerts Interval', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              SizedBox(
                height: 200,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      pickerTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF3B82F6) : Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Done'),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls(bool isDark, TimerProvider timerProvider) {
    final isRunningOrPaused = timerProvider.isRunning || timerProvider.isPaused;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: isRunningOrPaused ? _stopTimer : _resetTimer,
          icon: Icon(
            isRunningOrPaused ? Icons.stop : Icons.refresh,
            size: 32,
            color: isDark ? Colors.white60 : Colors.black38,
          ),
        ),
        const SizedBox(width: 32),
        GestureDetector(
          onTap: () {
            if (timerProvider.isRunning) {
              timerProvider.pauseTimer();
            } else if (timerProvider.isPaused) {
              timerProvider.resumeTimer();
            } else {
              _startTimer();
            }
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF3B82F6) : Colors.black,
              boxShadow: [
                BoxShadow(
                  color: (isDark ? const Color(0xFF3B82F6) : Colors.black).withAlpha(77),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              timerProvider.isRunning ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        const SizedBox(width: 32),
        IconButton(
          onPressed: () => _showSoundPicker(context, isDark),
          icon: Icon(Icons.music_note, size: 32, color: isDark ? Colors.white60 : Colors.black38),
        ),
      ],
    );
  }

  void _showSoundPicker(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<SettingsProvider>(
        builder: (context, settings, child) => GlassContainer(
          borderRadius: 30,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Alert Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 16),
              // Mode Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['Sound', 'Vibration', 'Both'].map((mode) => ChoiceChip(
                  label: Text(mode, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  selected: settings.alertMode == mode,
                  selectedColor: isDark ? const Color(0xFF3B82F6).withAlpha(128) : Colors.black26,
                  backgroundColor: Colors.transparent,
                  onSelected: (selected) async {
                    if (selected) {
                      await settings.setAlertMode(mode);
                      _previewAlert();
                    }
                  },
                )).toList(),
              ),
              const Divider(),
              Text('Alarm Repetition', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['Once', '5s', '15s', '30s', 'Continuous'].map((duration) => ChoiceChip(
                  label: Text(duration, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 12)),
                  selected: settings.alarmDuration == duration,
                  selectedColor: isDark ? const Color(0xFF3B82F6).withAlpha(128) : Colors.black26,
                  backgroundColor: Colors.transparent,
                  onSelected: (selected) {
                    if (selected) {
                      settings.setAlarmDuration(duration);
                    }
                  },
                )).toList(),
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.upload_file, color: isDark ? const Color(0xFF60A5FA) : Colors.black),
                title: Text('Import Custom Ringtone', style: TextStyle(color: isDark ? const Color(0xFF60A5FA) : Colors.black, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _pickCustomRingtone();
                },
              ),
              const Divider(),
              ..._medicalSounds.map((sound) => ListTile(
                title: Text(
                  sound.startsWith('/') ? sound.split('/').last : sound, 
                  style: TextStyle(color: isDark ? Colors.white : Colors.black)
                ),
                trailing: settings.selectedSound == sound 
                    ? Icon(Icons.check_circle, color: isDark ? const Color(0xFF60A5FA) : Colors.black) 
                    : null,
                onTap: () async {
                  await settings.setSelectedSound(sound);
                  _previewAlert();
                },
              )),
            ],
          ),
        ),
      ),
    );
  }
}
