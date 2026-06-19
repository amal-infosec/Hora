import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_themes.dart';
import '../../widgets/glass_container.dart';
import '../timer/timer_screen.dart';
import '../tasks/task_list_screen.dart';
import '../clinical/patient_list_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TaskListScreen(),
    const TimerScreen(),
    const PatientListScreen(),
    const Center(child: Text('Settings')),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isGlass = themeProvider.themeMode == ThemeModeType.liquidGlass;

    return Scaffold(
      extendBody: isGlass,
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
      bottomNavigationBar: _buildBottomNav(isGlass),
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
    final isGlass = themeProvider.themeMode == ThemeModeType.liquidGlass;
    
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isGlass ? const Color(0xFF3B82F6).withOpacity(0.2) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'H',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isGlass ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
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
                      color: isGlass ? const Color(0xFF64748B) : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Hello, Dr. Letcon',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 24,
                      letterSpacing: -0.5,
                      color: isGlass ? const Color(0xFF1E293B) : Colors.black,
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
                  color: isGlass ? const Color(0xFF1E293B) : Colors.black,
                ),
              ),
              IconButton(
                onPressed: () => themeProvider.toggleTheme(),
                icon: Icon(
                  isGlass ? Icons.light_mode : Icons.dark_mode,
                  color: isGlass ? const Color(0xFF1E293B) : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isGlass) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: isGlass ? 30 : 10,
        top: 10,
      ),
      child: GlassContainer(
        borderRadius: 30,
        blur: 20,
        opacity: 0.1,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(0, Icons.home_outlined, 'Home'),
            _navItem(1, Icons.calendar_today_outlined, 'Schedule'),
            _buildCenterAddButton(isGlass),
            _navItem(3, Icons.notifications_none_outlined, 'Alerts'),
            _navItem(4, Icons.settings_outlined, 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterAddButton(bool isGlass) {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isGlass ? const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
          ) : null,
          color: isGlass ? null : const Color(0xFF3B82F6),
          boxShadow: isGlass ? [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isGlass = themeProvider.themeMode == ThemeModeType.liquidGlass;
    final isSelected = _currentIndex == index;
    final color = isSelected 
        ? (isGlass ? const Color(0xFF3B82F6) : Colors.black)
        : (isGlass ? const Color(0xFF64748B) : Colors.black38);

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
}
