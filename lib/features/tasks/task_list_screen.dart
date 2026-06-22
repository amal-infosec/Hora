import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../widgets/glass_container.dart';
import '../../core/app_themes.dart';
import 'task_service.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskService>(context, listen: false).loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskService = Provider.of<TaskService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeModeType.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: taskService.tasks.isEmpty
          ? _buildEmptyState(isDark)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: taskService.tasks.length,
              itemBuilder: (context, index) {
                final task = taskService.tasks[index];
                return _buildTaskItem(task, isDark);
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_tasks_screen',
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: isDark ? const Color(0xFF3B82F6) : Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 16),
          Text(
            'No tasks scheduled',
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(TaskModel task, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Checkbox(
              value: task.isCompleted,
              onChanged: (_) {
                Provider.of<TaskService>(context, listen: false).toggleTaskCompletion(task);
              },
              activeColor: isDark ? const Color(0xFF3B82F6) : Colors.black,
              checkColor: Colors.white,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      color: isDark ? (task.isCompleted ? Colors.white38 : Colors.white) : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: isDark ? Colors.white38 : Colors.black54),
                      const SizedBox(width: 4),
                      Text(
                        '${task.durationMinutes} min',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                      const SizedBox(width: 12),
                      if (task.type == TaskType.temporary)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(51),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('TEMPORARY', style: TextStyle(fontSize: 8, color: Colors.orange)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.withAlpha(128)),
              onPressed: () {
                Provider.of<TaskService>(context, listen: false).deleteTask(task.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final nameController = TextEditingController();
    final durationController = TextEditingController();
    TaskType selectedType = TaskType.normal;

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
              const Text('New Task', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Task Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duration (min)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Task Type: '),
                  ChoiceChip(
                    label: const Text('Normal'),
                    selected: selectedType == TaskType.normal,
                    onSelected: (val) { if (val) setModalState(() => selectedType = TaskType.normal); },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Temporary (7d)'),
                    selected: selectedType == TaskType.temporary,
                    onSelected: (val) { if (val) setModalState(() => selectedType = TaskType.temporary); },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      final task = TaskModel(
                        name: nameController.text,
                        durationMinutes: int.tryParse(durationController.text) ?? 30,
                        type: selectedType,
                      );
                      Provider.of<TaskService>(context, listen: false).addTask(task);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Add Task', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
