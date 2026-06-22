import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  String _doctorName = '';
  String _profilePhotoPath = '';
  bool _enableOverlayAlerts = false;
  bool _isFirstTime = true;
  bool _isLoaded = false;
  String _alarmDuration = 'Once';
  String _selectedSound = 'Clinical Beep';
  String _alertMode = 'Both';

  String get doctorName => _doctorName;
  String get profilePhotoPath => _profilePhotoPath;
  bool get enableOverlayAlerts => _enableOverlayAlerts;
  bool get isFirstTime => _isFirstTime;
  bool get isLoaded => _isLoaded;
  String get alarmDuration => _alarmDuration;
  String get selectedSound => _selectedSound;
  String get alertMode => _alertMode;

  SettingsProvider({SharedPreferences? prefs}) {
    if (prefs != null) {
      _loadFromPrefs(prefs);
    } else {
      loadSettings();
    }
  }

  void _loadFromPrefs(SharedPreferences prefs) {
    _doctorName = prefs.getString('doctor_name') ?? '';
    _profilePhotoPath = prefs.getString('profile_photo_path') ?? '';
    _enableOverlayAlerts = prefs.getBool('enable_overlay_alerts') ?? false;
    _isFirstTime = prefs.getBool('is_first_time') ?? true;
    _alarmDuration = prefs.getString('alarm_duration') ?? 'Once';
    _selectedSound = prefs.getString('selected_sound') ?? 'Clinical Beep';
    _alertMode = prefs.getString('alert_mode') ?? 'Both';
    _isLoaded = true;
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _loadFromPrefs(prefs);
    notifyListeners();
  }

  Future<void> setDoctorName(String name) async {
    _doctorName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('doctor_name', name);
    notifyListeners();
  }

  Future<void> setProfilePhotoPath(String path) async {
    _profilePhotoPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_photo_path', path);
    notifyListeners();
  }

  Future<void> setEnableOverlayAlerts(bool value) async {
    _enableOverlayAlerts = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_overlay_alerts', value);
    notifyListeners();
  }

  Future<void> setAlarmDuration(String value) async {
    _alarmDuration = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarm_duration', value);
    notifyListeners();
  }

  Future<void> setSelectedSound(String value) async {
    _selectedSound = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_sound', value);
    notifyListeners();
  }

  Future<void> setAlertMode(String value) async {
    _alertMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alert_mode', value);
    notifyListeners();
  }

  Future<void> setCompletedFirstTime() async {
    _isFirstTime = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);
    notifyListeners();
  }

  Future<void> clearSettings() async {
    _doctorName = '';
    _profilePhotoPath = '';
    _enableOverlayAlerts = false;
    _isFirstTime = true;
    _alarmDuration = 'Once';
    _selectedSound = 'Clinical Beep';
    _alertMode = 'Both';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('doctor_name');
    await prefs.remove('profile_photo_path');
    await prefs.remove('enable_overlay_alerts');
    await prefs.remove('is_first_time');
    await prefs.remove('theme_mode');
    await prefs.remove('alarm_duration');
    await prefs.remove('selected_sound');
    await prefs.remove('alert_mode');
    notifyListeners();
  }
}
