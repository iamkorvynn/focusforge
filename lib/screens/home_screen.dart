import 'package:material_ui/material_ui.dart';

import '../models/focus_task.dart';
import '../models/timer_phase.dart';
import '../services/timer_controller.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/phase_selector.dart';
import '../widgets/timer_ring.dart';

/// The main screen: the countdown ring, phase picker and timer controls.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final TimerController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final isFocus = controller.phase == TimerPhase.focus;
        final color = AppTheme.phaseColor(
          isFocus,
          theme.brightness,
        );
        return Scaffold(
          appBar: AppBar(title: const Text('FocusForge')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                PhaseSelector(
                  selected: controller.phase,
                  enabled: !controller.isRunning,
                  onSelected: (phase) => controller.selectPhase(phase),
                ),
                const SizedBox(height: 28),
                TimerRing(
                  progress: controller.progress,
                  timeText: formatDuration(
                    Duration(seconds: controller.remainingSeconds),
                  ),
                  phaseLabel: controller.phase.label,
                  phaseDescription: controller.phase.description,
                  color: color,
                ),
                const SizedBox(height: 28),
                _buildControls(context, color),
                const SizedBox(height: 24),
                _buildCycleDots(context),
                const SizedBox(height: 16),
                _buildTaskPicker(context),
                const SizedBox(height: 16),
                _buildDailyGoal(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls(BuildContext context, Color color) {
    final isRunning = controller.isRunning;
    final isPaused = controller.isPaused;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: controller.isIdle ? null : () => controller.reset(),
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset'),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: () {
            if (isRunning) {
              controller.pause();
            } else {
              controller.start();
            }
          },
          icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
          label: Text(
            isRunning ? 'Pause' : (isPaused ? 'Resume' : 'Start'),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: controller.isIdle ? null : () => controller.skip(),
          icon: const Icon(Icons.skip_next),
          label: const Text('Skip'),
        ),
      ],
    );
  }

  /// Picks which task the next focus session counts toward.
  Widget _buildTaskPicker(BuildContext context) {
    final activeTasks =
        controller.tasks.where((t) => !t.isCompleted).toList();
    final current = controller.currentTask;
    final value = current != null &&
            activeTasks.any((t) => t.id == current.id)
        ? current
        : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DropdownButtonFormField<FocusTask?>(
          initialValue: value,
          decoration: const InputDecoration(
            labelText: 'Focusing on',
            border: InputBorder.none,
          ),
          items: [
            const DropdownMenuItem<FocusTask?>(
              value: null,
              child: Text('No task — just focus'),
            ),
            ...activeTasks.map(
              (task) => DropdownMenuItem<FocusTask?>(
                value: task,
                child: Text(task.title),
              ),
            ),
          ],
          onChanged: (task) => controller.selectTask(task),
        ),
      ),
    );
  }

  /// Today's progress against the daily focus goal.
  Widget _buildDailyGoal(BuildContext context) {
    final theme = Theme.of(context);
    final goalSeconds = controller.settings.dailyGoalMinutes * 60;
    final doneSeconds = controller.todayFocusSeconds;
    final fraction = goalSeconds == 0
        ? 0.0
        : (doneSeconds / goalSeconds).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Today: ${formatSecondsShort(doneSeconds)} of '
                  '${formatSecondsShort(goalSeconds)} goal',
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                Text(
                  '${controller.todaySessions} sessions',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: fraction),
          ],
        ),
      ),
    );
  }

  /// Dots showing progress toward the long break.
  Widget _buildCycleDots(BuildContext context) {
    final total = controller.settings.sessionsBeforeLongBreak;
    final done = controller.completedInCycle;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.local_fire_department, size: 18),
        const SizedBox(width: 6),
        Text('$done of $total focus sessions to a long break'),
        const SizedBox(width: 8),
        ...List.generate(total, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              index < done ? Icons.circle : Icons.circle_outlined,
              size: 12,
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }),
      ],
    );
  }
}
