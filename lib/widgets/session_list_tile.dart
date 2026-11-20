import 'package:material_ui/material_ui.dart';

import '../models/session_record.dart';
import '../utils/time_format.dart';

/// One row in the session history list.
class SessionListTile extends StatelessWidget {
  const SessionListTile({
    super.key,
    required this.session,
    this.taskTitle,
    this.onDelete,
  });

  final SessionRecord session;
  final String? taskTitle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFocus = session.phase.name == 'focus';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isFocus
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.secondaryContainer,
        child: Icon(
          isFocus ? Icons.timer : Icons.coffee,
          color: isFocus
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text(
        isFocus
            ? (taskTitle == null || taskTitle!.isEmpty
                ? 'Focus session'
                : taskTitle!)
            : '${session.phase.label} break',
      ),
      subtitle: Text(
        '${formatDayLabel(session.endedAt)} · '
        '${formatSecondsShort(session.actualSeconds)}'
        '${session.completed ? '' : ' · ended early'}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatDuration(Duration(seconds: session.actualSeconds)),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Delete entry',
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
