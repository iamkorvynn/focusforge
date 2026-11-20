import 'package:material_ui/material_ui.dart';

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
