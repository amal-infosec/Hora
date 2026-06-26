import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_themes.dart';
import '../../widgets/glass_container.dart';
import '../timer/timer_screen.dart';
import '../tasks/task_list_screen.dart';
import '../clinical/patient_list_screen.dart';
import 'dashboard_screen.dart';
import '../../core/settings_provider.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(onNavigateToTimer: () {
        setState(() => _currentIndex = 2);
      }),
      const TaskListScreen(),
      const TimerScreen(),
      const PatientListScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDark = themeProvider.themeMode == ThemeModeType.dark;

    if (!settingsProvider.isLoaded) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFFBFBFB),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (settingsProvider.isFirstTime) {
      return _buildTermsScreen(themeProvider, settingsProvider);
    }

    if (settingsProvider.doctorName.isEmpty) {
      return _buildNameSetupScreen(themeProvider);
    }

    return Scaffold(
      body: Stack(
        children: [
          // Removed hardcoded gradient since it's now in main.dart
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(themeProvider),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
    final themeMode = themeProvider.themeMode;
    final isDark = themeMode == ThemeModeType.dark;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: settingsProvider.profilePhotoPath.isNotEmpty && File(settingsProvider.profilePhotoPath).existsSync()
                      ? Image.file(
                          File(settingsProvider.profilePhotoPath),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark 
                                ? Colors.white.withOpacity(0.08) 
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              settingsProvider.doctorName.isNotEmpty ? settingsProvider.doctorName[0].toUpperCase() : 'H',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark 
                                    ? const Color(0xFF60A5FA) 
                                    : const Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hora',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark 
                          ? Colors.white60 
                          : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Hello, Dr. ${settingsProvider.doctorName}',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 24,
                      letterSpacing: -0.5,
                      color: isDark 
                          ? Colors.white 
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.notifications_outlined,
                  color: isDark 
                      ? Colors.white 
                      : Colors.black,
                ),
              ),
              IconButton(
                onPressed: () => themeProvider.toggleTheme(),
                icon: Icon(
                  themeMode == ThemeModeType.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  color: isDark 
                      ? Colors.white 
                      : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 10,
          top: 10,
        ),
        child: GlassContainer(
          borderRadius: 30,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(0, Icons.home_outlined, 'Home'),
              _navItem(1, Icons.calendar_today_outlined, 'Schedule'),
              _buildCenterAddButton(),
              _navItem(3, Icons.people_outline, 'Patients'),
              _navItem(4, Icons.settings_outlined, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterAddButton() {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF3B82F6),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeMode = themeProvider.themeMode;
    final isDark = themeMode == ThemeModeType.dark;
    final isSelected = _currentIndex == index;
    
    final color = isSelected 
        ? (isDark ? const Color(0xFF60A5FA) : Colors.black)
        : (isDark ? Colors.white38 : Colors.black38);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameSetupScreen(ThemeProvider themeProvider) {
    final isDark = themeProvider.themeMode == ThemeModeType.dark;
    final nameController = TextEditingController();
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : null,
      body: Container(
        decoration: isDark ? const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF020617)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ) : null,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: GlassContainer(
              borderRadius: 32,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withAlpha(20)
                          : Colors.black.withAlpha(12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.medical_services_outlined,
                      size: 48,
                      color: isDark 
                          ? const Color(0xFF60A5FA) 
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to Hora',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark 
                          ? Colors.white 
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please enter your name to personalize your dashboard.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark 
                          ? Colors.white60 
                          : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: nameController,
                    style: TextStyle(
                      color: isDark 
                          ? Colors.white 
                          : Colors.black
                    ),
                    decoration: InputDecoration(
                      labelText: 'Doctor Name',
                      labelStyle: TextStyle(color: isDark ? Colors.white60 : null),
                      hintText: 'e.g. Letcon',
                      hintStyle: TextStyle(color: isDark ? Colors.white30 : null),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      prefixIcon: Icon(Icons.person_outline, color: isDark ? Colors.white60 : null),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          final settings = Provider.of<SettingsProvider>(context, listen: false);
                          settings.setDoctorName(nameController.text.trim());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark 
                            ? const Color(0xFF3B82F6) 
                            : Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsScreen(ThemeProvider themeProvider, SettingsProvider settings) {
    final isDark = themeProvider.themeMode == ThemeModeType.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white60 : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : null,
      body: Container(
        decoration: isDark ? const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF020617)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ) : null,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: GlassContainer(
              borderRadius: 32,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.gavel_outlined,
                        size: 44,
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Warning Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withOpacity(isDark ? 0.3 : 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Warning: This app can make mistakes, so be aware. It is a support utility for clinicians and does not replace medical judgment.',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.red.shade200 : Colors.red.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Text(
                    'Application Features:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Features Bullet Points
                  _buildFeatureItem(Icons.timer_outlined, 'Clinical Timer', 'Custom interval sound alerts & haptic alarms to monitor patient status.', isDark, textColor, subtitleColor),
                  _buildFeatureItem(Icons.calendar_today_outlined, 'Shift Scheduler', 'Manage doctor shifts and custom tasks on the calendar.', isDark, textColor, subtitleColor),
                  _buildFeatureItem(Icons.analytics_outlined, 'Clinical Metrics & Logs', 'Track timer logs, active clinical hours, and full patient vitals history.', isDark, textColor, subtitleColor),
                  _buildFeatureItem(Icons.security_outlined, 'Offline Database', 'Encrypted local SQLite storage with timezone-agnostic notifications.', isDark, textColor, subtitleColor),
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  // Checkbox Row
                  Row(
                    children: [
                      Checkbox(
                        value: _termsAccepted,
                        activeColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
                        onChanged: (val) {
                          setState(() {
                            _termsAccepted = val ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _termsAccepted = !_termsAccepted;
                            });
                          },
                          child: Text(
                            'I accept the warning, terms, and conditions to start using the app.',
                            style: TextStyle(color: textColor, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _termsAccepted ? () {
                        settings.setCompletedFirstTime();
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF3B82F6) : Colors.black,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: isDark ? Colors.white12 : Colors.black12,
                        disabledForegroundColor: isDark ? Colors.white30 : Colors.black26,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Accept & Continue',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description, bool isDark, Color textColor, Color subtitleColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(color: subtitleColor, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
