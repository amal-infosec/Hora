import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class TimerProvider with ChangeNotifier {
  int _secondsRemaining = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  int _initialDuration = 0;
  StreamSubscription? _serviceSubscription;

  int get secondsRemaining => _secondsRemaining;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  int get initialDuration => _initialDuration;

  TimerProvider() {
    _listenToBackgroundService();
  }

  void _listenToBackgroundService() {
    _serviceSubscription = FlutterBackgroundService().on('update').listen((event) {
      if (event != null) {
        _secondsRemaining = event['secondsRemaining'] ?? 0;
        _isRunning = event['isRunning'] ?? false;
        _isPaused = event['isPaused'] ?? false;
        if (event.containsKey('initialDuration')) {
          _initialDuration = event['initialDuration'] ?? 0;
        }
        notifyListeners();
      }
    });
  }

  void setDuration(int seconds) {
    _initialDuration = seconds;
    _secondsRemaining = seconds;
    notifyListeners();
  }

  Future<void> startTimer(
    int seconds,
    int intervalSeconds,
    String sound,
    String alertMode, {
    String patientName = 'General',
    String alarmDuration = 'Once',
  }) async {
    _isRunning = true;
    _isPaused = false;
    _secondsRemaining = seconds;
    _initialDuration = seconds;
    notifyListeners();

    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
      // Wait for the background engine to spawn and register its event listeners
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    service.invoke('startTimer', {
      'duration': seconds,
      'intervalSeconds': intervalSeconds,
      'sound': sound,
      'alertMode': alertMode,
      'initialDuration': seconds,
      'patientName': patientName,
      'alarmDuration': alarmDuration,
    });
  }

  void pauseTimer() {
    FlutterBackgroundService().invoke('pauseTimer');
    _isRunning = false;
    _isPaused = true;
    notifyListeners();
  }

  void resumeTimer() {
    FlutterBackgroundService().invoke('resumeTimer');
    _isRunning = true;
    _isPaused = false;
    notifyListeners();
  }

  void stopTimer() {
    FlutterBackgroundService().invoke('stopService');
    _isRunning = false;
    _isPaused = false;
    notifyListeners();
  }

  void resetTimer() {
    stopTimer();
    _secondsRemaining = _initialDuration;
    notifyListeners();
  }

  @override
  void dispose() {
    _serviceSubscription?.cancel();
    super.dispose();
  }
}
