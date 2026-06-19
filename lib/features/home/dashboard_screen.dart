import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/glass_container.dart';
import '../../core/app_themes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isGlass = themeProvider.themeMode == ThemeModeType.liquidGlass;
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        // Date Selector
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildDatePill('Today', true, isGlass),
              _buildDatePill('Tue 12', false, isGlass),
              _buildDatePill('Wed 13', false, isGlass),
              _buildDatePill('Thu 14', false, isGlass),
              _buildDatePill('Fri 15', false, isGlass),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Primary Action Button
        GestureDetector(
          onTap: () {},
          child: GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Container(
              width: double.infinity,
              decoration: isGlass ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF3B82F6).withOpacity(0.8), const Color(0xFF60A5FA).withOpacity(0.5)],
                ),
                borderRadius: BorderRadius.circular(24),
              ) : null,
              child: Center(
                child: Text(
                  'Add Shift',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isGlass ? const Color(0xFF1E293B) : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        // Upcoming Schedule Section
        Text(
          'Upcoming Schedule',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isGlass ? const Color(0xFF1E293B) : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildScheduleCard('Morning Rounds', '08:00 AM – 10:00 AM', Icons.local_hospital_outlined, isGlass),
        const SizedBox(height: 12),
        _buildScheduleCard('Surgery Prep', '11:00 AM – 12:30 PM', Icons.personal_injury_outlined, isGlass),
        
        const SizedBox(height: 32),
        
        // Reminders Section
        Text(
          'Reminders',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isGlass ? const Color(0xFF1E293B) : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildScheduleCard('Medication Check', '3:00 PM', Icons.medication_outlined, isGlass, isReminder: true),
        const SizedBox(height: 12),
        _buildScheduleCard('Team Meeting', '4:30 PM', Icons.groups_outlined, isGlass, isReminder: true),
        
        const SizedBox(height: 80), // Padding for bottom nav
      ],
    );
  }

  Widget _buildDatePill(String text, bool isSelected, bool isGlass) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: GlassContainer(
        borderRadius: 20,
        opacity: isSelected ? 0.2 : 0.05,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected 
                  ? (isGlass ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6)) 
                  : (isGlass ? const Color(0xFF64748B) : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(String title, String time, IconData icon, bool isGlass, {bool isReminder = false}) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGlass ? const Color(0xFF3B82F6).withOpacity(0.15) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isGlass ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isGlass ? const Color(0xFF1E293B) : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14,
                    color: isGlass ? const Color(0xFF64748B) : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isReminder ? Icons.notifications_active_outlined : Icons.notifications_none_outlined,
            color: isGlass ? const Color(0xFF64748B) : Colors.black38,
            size: 20,
          ),
        ],
      ),
    );
  }
}
