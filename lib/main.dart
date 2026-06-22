import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'core/app_themes.dart';
import 'features/home/home_screen.dart';
import 'features/tasks/task_service.dart';
import 'features/clinical/clinical_service.dart';
import 'features/notifications/notification_service.dart';
import 'core/db_helper.dart';
import 'features/timer/timer_background_service.dart' as bg_service;
import 'core/settings_provider.dart';
import 'features/timer/timer_provider.dart';
import 'features/schedule/schedule_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PreInitApp());
}

class PreInitApp extends StatelessWidget {
  const PreInitApp({super.key});

  Future<SharedPreferences> _preInit() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Run background service & DB cleanups in the background asynchronously
    try {
      await NotificationService().init();
    } catch (e) {
      debugPrint("Error initializing NotificationService: $e");
    }

    try {
      await bg_service.initializeBackgroundService();
    } catch (e) {
      debugPrint("Error initializing background service: $e");
    }

    try {
      await DatabaseHelper().deleteExpiredTasks();
    } catch (e) {
      debugPrint("Error clearing expired tasks: $e");
    }
    
    return prefs;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _preInit(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final prefs = snapshot.data!;
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider(prefs: prefs)),
              ChangeNotifierProvider(create: (_) => TaskService()),
              ChangeNotifierProvider(create: (_) => ClinicalService()),
              ChangeNotifierProvider(create: (_) => SettingsProvider(prefs: prefs)),
              ChangeNotifierProvider(create: (_) => TimerProvider()),
              ChangeNotifierProvider(create: (_) => ScheduleProvider()),
            ],
            child: const HoraApp(),
          );
        }

        // Return a lightweight premium splash UI in the meantime (matches app themes)
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Color(0xFF090D16), // Sapphire Dark background
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, color: Color(0xFF3B82F6), size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Hora',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class HoraApp extends StatelessWidget {
  const HoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Hora',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.currentTheme,
      home: const HomeScreen(),
    );
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  bg_service.onStart(service);
}

@pragma('vm:entry-point')
void overlayMain() {
  bg_service.overlayMain();
}
