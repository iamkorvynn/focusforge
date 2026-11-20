import 'package:material_ui/material_ui.dart';

import '../models/focus_task.dart';
import '../services/timer_controller.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_tile.dart';
import 'add_task_sheet.dart';

/// The task list: active tasks first, completed below. Tap a task to link
/// it to the next focus session; the checkbox marks it done.
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key, required this.controller});

  final TimerController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final tasks = controller.tasks;
        return Scaffold(
          appBar: AppBar(title: const Text('Tasks')),
          body: tasks.isEmpty
              ? EmptyState(
                  icon: Icons.checklist,
                  title: 'No tasks yet',
                  message:
                      'Add what you want to focus on, then tap it to link '
                      'your next session to it.',
                  actionLabel: 'Add your first task',
                  onAction: () => _showAddSheet(context),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return TaskTile(
                      task: task,
                      selected: controller.currentTask?.id == task.id,
                      onTap: () => controller.selectTask(
                        controller.currentTask?.id == task.id
                            ? null
                            : task,
                      ),
                      onToggleComplete: () =>
                          controller.toggleTaskComplete(task),
                      onDelete: () => _confirmDelete(context, task),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddSheet(context),
            tooltip: 'Add task',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddTaskSheet(
        onSave: (title, notes) => controller.addTask(title, notes: notes),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, FocusTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text(
          '"${task.title}" will be removed. Past sessions stay in history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteTask(task);
    }
  }
}
