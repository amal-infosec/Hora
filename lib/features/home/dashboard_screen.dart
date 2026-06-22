import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/glass_container.dart';
import '../../core/app_themes.dart';
import '../timer/timer_provider.dart';
import '../schedule/schedule_provider.dart';
import '../../models/schedule_model.dart';
import '../reports/reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToTimer;
  const DashboardScreen({super.key, this.onNavigateToTimer});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedDateFilter = 'Today';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ScheduleProvider>(context, listen: false).loadSchedule();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final timerProvider = Provider.of<TimerProvider>(context);
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    
    final isDark = themeProvider.themeMode == ThemeModeType.dark;

    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    // Filter shifts based on selected pill
    final filteredShifts = scheduleProvider.shifts.where((shift) {
      if (_selectedDateFilter == 'All') return true;
      return shift.date.trim().toLowerCase() == _selectedDateFilter.trim().toLowerCase();
    }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        // Date Selector Pills
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildDatePill('Today', _selectedDateFilter == 'Today', isDark),
              _buildDatePill('Tomorrow', _selectedDateFilter == 'Tomorrow', isDark),
              _buildDatePill('All', _selectedDateFilter == 'All', isDark),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Permanent Active/Idle Clinical Timer Widget Card
        _buildTimerWidget(context, timerProvider, isDark, textColor, subtitleColor),
        const SizedBox(height: 24),
        
        // Primary Action Button (Add Shift)
        GestureDetector(
          onTap: () => _showAddShiftDialog(context, isDark),
          child: GlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Container(
              width: double.infinity,
              decoration: null,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month, 
                      color: isDark ? Colors.white : Colors.black
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Shift',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        // Upcoming Schedule Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Schedule',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            IconButton(
              icon: Icon(Icons.assignment_outlined, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6)),
              tooltip: 'View Reports',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportsScreen()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (filteredShifts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No shifts scheduled for $_selectedDateFilter.',
              style: TextStyle(color: subtitleColor),
            ),
          )
        else
          ...filteredShifts.map((shift) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildScheduleCard(
              shift.title, 
              '${shift.time} (${shift.date})', 
              Icons.local_hospital_outlined, 
              isDark,
              textColor,
              subtitleColor,
              onDelete: () => scheduleProvider.deleteShift(shift.id),
            ),
          )),
        
        const SizedBox(height: 32),
        
        // Reminders Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reminders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6)),
              onPressed: () => _showAddReminderDialog(context, isDark),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (scheduleProvider.reminders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No active reminders.',
              style: TextStyle(color: subtitleColor),
            ),
          )
        else
          ...scheduleProvider.reminders.map((reminder) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildScheduleCard(
              reminder.title, 
              reminder.time, 
              Icons.notifications_active_outlined, 
              isDark,
              textColor,
              subtitleColor,
              isReminder: true,
              isActive: reminder.isActive,
              onToggle: () => scheduleProvider.toggleReminderActive(reminder),
              onDelete: () => scheduleProvider.deleteReminder(reminder.id),
            ),
          )),
        
        const SizedBox(height: 80), // Padding for bottom nav
      ],
    );
  }

  Widget _buildDatePill(String text, bool isSelected, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedDateFilter = text;
          });
        },
        child: GlassContainer(
          borderRadius: 20,
          opacity: isSelected ? 0.25 : 0.05,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected 
                    ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6)) 
                    : (isDark ? Colors.white38 : Colors.black54),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(
    String title, 
    String time, 
    IconData icon, 
    bool isDark,
    Color textColor,
    Color subtitleColor,
    {
      bool isReminder = false, 
      bool isActive = false, 
      VoidCallback? onToggle, 
      required VoidCallback onDelete
    }
  ) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
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
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          if (isReminder) ...[
            IconButton(
              icon: Icon(
                isActive ? Icons.notifications_active : Icons.notifications_off_outlined,
                color: isActive 
                    ? (isDark ? const Color(0xFF60A5FA) : Colors.black)
                    : subtitleColor,
                size: 20,
              ),
              onPressed: onToggle,
            ),
          ],
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.withOpacity(isDark ? 0.7 : 0.5), size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildTimerWidget(
    BuildContext context, 
    TimerProvider timerProvider, 
    bool isDark,
    Color textColor,
    Color subtitleColor
  ) {
    if (timerProvider.isRunning) {
      final double progress = timerProvider.initialDuration > 0
          ? (timerProvider.initialDuration - timerProvider.secondsRemaining) / timerProvider.initialDuration
          : 0.0;

      int totalSeconds = timerProvider.secondsRemaining;
      int hours = totalSeconds ~/ 3600;
      int minutes = (totalSeconds % 3600) ~/ 60;
      int seconds = totalSeconds % 60;
      String timeStr = '${hours > 0 ? '${hours.toString().padLeft(2, '0')}:' : ''}${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      return GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Active Clinical Timer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
                  onPressed: () {
                    timerProvider.stopTimer();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% Done',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF60A5FA) : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark ? Colors.white12 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? const Color(0xFF60A5FA) : Colors.black,
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      );
    } else {
      return GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: isDark ? Colors.white38 : Colors.black38,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Active Timer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Clinical timer is currently idle',
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                widget.onNavigateToTimer?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF3B82F6) : Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: const Text('Start Timer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  void _showAddShiftDialog(BuildContext context, bool isDark) {
    final titleController = TextEditingController();
    final timeController = TextEditingController();
    String selectedDate = 'Today';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => GlassContainer(
          borderRadius: 30,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Upcoming Shift', 
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black
                )
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Shift Title (e.g. Morning Rounds)',
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  labelText: 'Shift Time (e.g. 08:00 AM – 10:00 AM)',
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Shift Date: ', 
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 16)
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Today'),
                    selected: selectedDate == 'Today',
                    onSelected: (val) { if (val) setModalState(() => selectedDate = 'Today'); },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Tomorrow'),
                    selected: selectedDate == 'Tomorrow',
                    onSelected: (val) { if (val) setModalState(() => selectedDate = 'Tomorrow'); },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty && timeController.text.isNotEmpty) {
                      final shift = ShiftModel(
                        title: titleController.text,
                        time: timeController.text,
                        date: selectedDate,
                      );
                      Provider.of<ScheduleProvider>(context, listen: false).addShift(shift);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark 
                        ? const Color(0xFF3B82F6) 
                        : Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Shift', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context, bool isDark) {
    final titleController = TextEditingController();
    final timeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: 30,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Shift Reminder', 
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black
              )
            ),
            const SizedBox(height: 20),
            TextField(
              controller: titleController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'Reminder Description (e.g. Check IV)',
                labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: timeController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'Alert Time (e.g. 03:00 PM)',
                labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty && timeController.text.isNotEmpty) {
                    final reminder = ReminderModel(
                      title: titleController.text,
                      time: timeController.text,
                    );
                    Provider.of<ScheduleProvider>(context, listen: false).addReminder(reminder);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark 
                      ? const Color(0xFF3B82F6) 
                      : Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Reminder', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
