import 'package:material_ui/material_ui.dart';

import '../services/stats_service.dart' as stats;
import '../services/timer_controller.dart';
import '../utils/time_format.dart';
import '../widgets/empty_state.dart';
import '../widgets/session_list_tile.dart';
import '../widgets/stat_card.dart';
import '../widgets/week_chart.dart';

/// History and stats: totals, streak, the last 7 days as bars, focus
/// time per task, and the full session history.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.controller});

  final TimerController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final sessions = controller.recentSessions;
        final now = DateTime.now();
        final perDay = stats.focusSecondsPerDay(
          sessions,
          endDay: now,
          days: 7,
        );
        final streak = stats.currentStreakDays(sessions, today: now);
        final byTask = stats.focusSecondsByTask(sessions);
        final dayLabels = _lastSevenDayLabels(now);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Stats & History'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Clear history',
                onPressed: sessions.isEmpty
                    ? null
                    : () => _confirmClear(context),
              ),
            ],
          ),
          body: sessions.isEmpty
              ? const EmptyState(
                  icon: Icons.bar_chart,
                  title: 'No sessions yet',
                  message:
                      'Finish your first focus session and your stats, '
                      'chart and history will show up here.',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTotalsRow(context, streak),
                      const SizedBox(height: 16),
                      _buildWeekCard(context, perDay, dayLabels),
                      const SizedBox(height: 16),
                      if (byTask.isNotEmpty) ...[
                        _buildByTaskCard(context, byTask),
                        const SizedBox(height: 16),
                      ],
                      _buildHistoryCard(context),
                    ],
                  ),
                ),
        );
      },
    );
  }

  List<String> _lastSevenDayLabels(DateTime now) {
    const short = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      return short[day.weekday - 1];
    });
  }

  Widget _buildTotalsRow(BuildContext context, int streak) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        StatCard(
          label: 'Total focus time',
          value: formatSecondsShort(controller.allTimeFocusSeconds),
          icon: Icons.timer,
          subtext: 'all time',
        ),
        StatCard(
          label: 'Focus sessions',
          value: '${controller.allTimeSessions}',
          icon: Icons.check_circle,
          subtext: 'completed',
        ),
        StatCard(
          label: 'Day streak',
          value: '$streak',
          icon: Icons.local_fire_department,
          subtext: streak == 1 ? 'day in a row' : 'days in a row',
        ),
        StatCard(
          label: 'Today',
          value: formatSecondsShort(controller.todayFocusSeconds),
          icon: Icons.today,
          subtext: '${controller.todaySessions} sessions',
        ),
      ],
    );
  }

  Widget _buildWeekCard(
    BuildContext context,
    List<int> perDay,
    List<String> dayLabels,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 7 days',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            WeekChart(secondsPerDay: perDay, dayLabels: dayLabels),
          ],
        ),
      ),
    );
  }

  Widget _buildByTaskCard(BuildContext context, Map<int, int> byTask) {
    final entries = byTask.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();
    final max = top.isEmpty ? 0 : top.first.value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Focus by task',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...top.map((entry) {
              final task = controller.tasks
                  .where((t) => t.id == entry.key)
                  .firstOrNull;
              final title = task?.title ?? 'Deleted task';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(title)),
                        Text(formatSecondsShort(entry.value)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: max == 0 ? 0 : entry.value / max,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context) {
    final sessions = controller.recentSessions;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'History',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...sessions.map((session) {
              final task = session.taskId == null
                  ? null
                  : controller.tasks
                      .where((t) => t.id == session.taskId)
                      .firstOrNull;
              return SessionListTile(
                session: session,
                taskTitle: task?.title,
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
          'All recorded sessions will be deleted. Tasks and settings '
          'are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.clearHistory();
    }
  }
}
