import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:system_alert_window/system_alert_window.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../../core/db_helper.dart';
import '../../models/timer_report_model.dart';

// Background Service Initialization
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'timer_foreground', // id
    'Timer Service', // title
    description: 'This channel is used for the active clinical timer.', // description
    importance: Importance.low, // importance must be at low or higher level
  );

  const AndroidNotificationChannel alertsChannel = AndroidNotificationChannel(
    'timer_alerts', // id
    'Timer Alerts', // title
    description: 'This channel is used for timer completion and interval alerts.', // description
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(alertsChannel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'timer_foreground',
      initialNotificationTitle: 'Timer stopped',
      initialNotificationContent: 'Waiting to start...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer, color: Color(0xFF3B82F6), size: 48),
              const SizedBox(height: 16),
              const Text(
                "Timer Finished!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please check on your patient.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
                  },
                  child: const Text("Stop Alarm", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showLocalAlertNotification(String title, String body) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('launcher_icon');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  try {
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  } catch (e) {
    // Suppress background notifications init exceptions
  }
  
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'timer_alerts', // id
        'Timer Alerts', // name
        channelDescription: 'Alerts for clinical timer completions and intervals',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
  
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
      
  await flutterLocalNotificationsPlugin.show(
    999, // ID for active alert popups
    title,
    body,
    platformChannelSpecifics,
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // DartPluginRegistrant.ensureInitialized(); // Commented out to prevent "This class should only be used in the main isolate" exception in background isolates

  final AudioPlayer audioPlayer = AudioPlayer();
  Timer? periodicTimer;
  int secondsRemaining = 0;
  int initialDuration = 0;
  int intervalSeconds = 0;
  String selectedSound = 'sounds/clinical_beep.ogg';
  String alertMode = 'Both';

  String patientName = 'General';
  String startTime = '';
  int elapsedSeconds = 0;
  bool isReportLogged = false;
  bool isPaused = false;
  String alarmDurationStr = 'Once';

  void startTicking() {
    periodicTimer?.cancel();
    isPaused = false;
    
    // Map sound name to path
    String assetPath;
    if (selectedSound.startsWith('/')) {
        assetPath = selectedSound; // absolute path
    } else {
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
    }

    periodicTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (secondsRemaining > 0) {
        secondsRemaining--;
        elapsedSeconds++;
        
        // Update notification
        if (service is AndroidServiceInstance) {
          int hours = secondsRemaining ~/ 3600;
          int minutes = (secondsRemaining % 3600) ~/ 60;
          int secs = secondsRemaining % 60;
          String timeStr = '${hours > 0 ? '${hours.toString().padLeft(2, '0')}:' : ''}${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
          
          service.setForegroundNotificationInfo(
            title: "Hora Timer Active",
            content: "Time remaining: $timeStr",
          );
        }

        // Interval Logic
        int passedSeconds = initialDuration - secondsRemaining;
        if (intervalSeconds > 0 && passedSeconds % intervalSeconds == 0 && passedSeconds > 0 && secondsRemaining > 0) {
           _triggerAlert(audioPlayer, assetPath, alertMode, alarmDurationStr, isCompletion: false);
           showLocalAlertNotification(
             "Timer Interval ($patientName)!", 
             "Check on patient $patientName. Elapsed: ${passedSeconds ~/ 60}m ${passedSeconds % 60}s."
           );
        }
        
      } else {
        // COMPLETED
        timer.cancel();
        if (service is AndroidServiceInstance) {
           service.setForegroundNotificationInfo(
            title: "Timer Completed ($patientName)!",
            content: "Please check on patient $patientName immediately.",
          );
        }
        _triggerAlert(audioPlayer, assetPath, alertMode, alarmDurationStr, isCompletion: true);
        showLocalAlertNotification(
          "Timer Completed ($patientName)!", 
          "Clinical timer finished for $patientName. Check on patient immediately."
        );
        
        if (!isReportLogged) {
          isReportLogged = true;
          try {
            final report = TimerReportModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              patientName: patientName,
              initialDurationSeconds: initialDuration,
              elapsedSeconds: initialDuration,
              startTime: startTime,
              status: 'Completed',
            );
            await DatabaseHelper().insertTimerReport(report);
          } catch (e) {
            // Suppress background database logging errors
          }
        }
        
        // Show System Alert Window natively via Flutter if permission is granted
        try {
          SystemAlertWindow.checkPermissions(prefMode: SystemWindowPrefMode.OVERLAY).then((hasPermission) {
            if (hasPermission == true) {
              SystemAlertWindow.showSystemWindow(
                  height: 250,
                  width: 0, // 0 usually means MATCH_PARENT or default
                  gravity: SystemWindowGravity.TOP,
                  prefMode: SystemWindowPrefMode.OVERLAY,
                  layoutParamFlags: [
                    SystemWindowFlags.FLAG_NOT_FOCUSABLE,
                  ],
              );
            }
          });
        } catch (e) {
          // Suppress permission or window display exceptions on restricted devices
        }
      }
      
      // Send updates to UI
      service.invoke('update', {
        'secondsRemaining': secondsRemaining,
        'isRunning': secondsRemaining > 0,
        'isPaused': isPaused,
        'initialDuration': initialDuration,
      });
    });
  }

  service.on('stopService').listen((event) async {
    periodicTimer?.cancel();
    await audioPlayer.stop();
    await audioPlayer.setReleaseMode(ReleaseMode.release);

    if (!isReportLogged && elapsedSeconds > 0) {
      isReportLogged = true;
      try {
        final report = TimerReportModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          patientName: patientName,
          initialDurationSeconds: initialDuration,
          elapsedSeconds: elapsedSeconds,
          startTime: startTime,
          status: 'Stopped',
        );
        await DatabaseHelper().insertTimerReport(report);
      } catch (e) {
        // Suppress background database logging errors
      }
    }

    service.stopSelf();
  });

  service.on('startTimer').listen((event) {
    if (event == null) return;
    
    secondsRemaining = event['duration'];
    initialDuration = event['duration'];
    intervalSeconds = event['intervalSeconds'] ?? 0;
    selectedSound = event['sound'] ?? 'Clinical Beep';
    alertMode = event['alertMode'] ?? 'Both';
    patientName = event['patientName'] ?? 'General';
    alarmDurationStr = event['alarmDuration'] ?? 'Once';

    startTime = DateTime.now().toIso8601String();
    elapsedSeconds = 0;
    isReportLogged = false;
    isPaused = false;
    
    startTicking();
  });

  service.on('pauseTimer').listen((event) {
    isPaused = true;
    periodicTimer?.cancel();
    service.invoke('update', {
      'secondsRemaining': secondsRemaining,
      'isRunning': false,
      'isPaused': true,
      'initialDuration': initialDuration,
    });
    if (service is AndroidServiceInstance) {
      int hours = secondsRemaining ~/ 3600;
      int minutes = (secondsRemaining % 3600) ~/ 60;
      int secs = secondsRemaining % 60;
      String timeStr = '${hours > 0 ? '${hours.toString().padLeft(2, '0')}:' : ''}${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
      service.setForegroundNotificationInfo(
        title: "Hora Timer Paused",
        content: "Time remaining: $timeStr",
      );
    }
  });

  service.on('resumeTimer').listen((event) {
    if (isPaused) {
      startTicking();
    }
  });
}

Future<void> _triggerAlert(AudioPlayer player, String path, String mode, String alarmDurationStr, {bool isCompletion = false}) async {
  if (mode == 'Vibration' || mode == 'Both') {
      if (isCompletion) {
        for (int i = 0; i < 3; i++) {
          Vibration.vibrate(duration: 500, amplitude: 255);
          await Future.delayed(const Duration(milliseconds: 700));
        }
      } else {
        Vibration.vibrate(duration: 150, amplitude: 128);
      }
  }

  if (mode == 'Sound' || mode == 'Both') {
      await player.stop();
      if (isCompletion && alarmDurationStr != 'Once') {
        await player.setReleaseMode(ReleaseMode.loop);
      } else {
        await player.setReleaseMode(ReleaseMode.release);
      }

      if (path.startsWith('/')) {
        await player.play(DeviceFileSource(path));
      } else {
        await player.play(AssetSource(path));
      }

      if (isCompletion && alarmDurationStr != 'Once' && alarmDurationStr != 'Continuous') {
        int durationSecs = 5;
        if (alarmDurationStr == '15s') durationSecs = 15;
        if (alarmDurationStr == '30s') durationSecs = 30;
        Timer(Duration(seconds: durationSecs), () async {
          await player.stop();
          await player.setReleaseMode(ReleaseMode.release);
        });
      }
  }
}
