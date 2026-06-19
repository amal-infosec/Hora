import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_themes.dart';
import 'features/home/home_screen.dart';
import 'features/tasks/task_service.dart';
import 'features/clinical/clinical_service.dart';
import 'features/notifications/notification_service.dart';
import 'core/db_helper.dart';
import 'features/timer/timer_background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await NotificationService().init();
  await initializeBackgroundService();
  
  // Cleanup expired tasks on startup
  final dbHelper = DatabaseHelper();
  await dbHelper.deleteExpiredTasks();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TaskService()),
        ChangeNotifierProvider(create: (_) => ClinicalService()),
      ],
      child: const HoraApp(),
    ),
  );
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
      builder: (context, child) {
        if (themeProvider.themeMode == ThemeModeType.liquidGlass) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF1F5FD), Color(0xFFE2EAFB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: child,
          );
        }
        return child!;
      },
      home: const HomeScreen(),
    );
  }
}
