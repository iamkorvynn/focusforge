import 'package:material_ui/material_ui.dart';

import '../models/focus_task.dart';
import '../utils/time_format.dart';

/// One row in the task list: color dot, title, notes, focus totals, a
/// checkbox to mark done, and a delete button. Tapping selects the task
/// for the next focus session.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.selected,
    required this.onTap,
    required this.onToggleComplete,
    required this.onDelete,
  });

  final FocusTask task;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(task.colorValue);
    return Card(
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
          : null,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 12,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration:
                task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          task.notes.isEmpty
              ? '${formatSecondsShort(task.totalFocusSeconds)} focused · '
                  '${task.completedSessions} sessions'
              : task.notes,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
            Checkbox(
              value: task.isCompleted,
              onChanged: (_) => onToggleComplete(),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete task',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
