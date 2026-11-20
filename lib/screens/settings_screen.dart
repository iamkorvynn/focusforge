import 'package:material_ui/material_ui.dart';

import '../models/app_settings.dart';
import '../services/timer_controller.dart';

/// Timer durations, daily goal, alerts and auto-start behaviour.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final TimerController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final settings = controller.settings;
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionTitle(context, 'Timer lengths'),
              _durationTile(
                context,
                label: 'Focus session',
                value: settings.focusMinutes,
                min: 5,
                max: 120,
                step: 5,
                suffix: 'min',
                onChanged: (v) => controller.updateSettings(
                  settings.copyWith(focusMinutes: v),
                ),
              ),
              _durationTile(
                context,
                label: 'Short break',
                value: settings.shortBreakMinutes,
                min: 1,
                max: 30,
                step: 1,
                suffix: 'min',
                onChanged: (v) => controller.updateSettings(
                  settings.copyWith(shortBreakMinutes: v),
                ),
              ),
              _durationTile(
                context,
                label: 'Long break',
                value: settings.longBreakMinutes,
                min: 5,
                max: 60,
                step: 5,
                suffix: 'min',
                onChanged: (v) => controller.updateSettings(
                  settings.copyWith(longBreakMinutes: v),
                ),
              ),
              _durationTile(
                context,
                label: 'Focus sessions before a long break',
                value: settings.sessionsBeforeLongBreak,
                min: 2,
                max: 8,
                step: 1,
                suffix: 'sessions',
                onChanged: (v) => controller.updateSettings(
                  settings.copyWith(sessionsBeforeLongBreak: v),
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle(context, 'Daily goal'),
              _durationTile(
                context,
                label: 'Focus goal',
                value: settings.dailyGoalMinutes,
                min: 30,
                max: 480,
                step: 30,
                suffix: 'min / day',
                onChanged: (v) => controller.updateSettings(
                  settings.copyWith(dailyGoalMinutes: v),
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle(context, 'Alerts'),
              SwitchListTile(
                title: const Text('Sound on session end'),
                value: settings.soundEnabled,
                onChanged: (v) => controller.updateSettings(
                  settings.copyWith(soundEnabled: v),
                ),
              ),
              SwitchListTile(
                title: const Text('Vibration on session end'),
                value: settings.vibrationEnabled,
                onChanged: (v) => controller.updateSettings(
                  settings.copyWith(vibrationEnabled: v),
                ),
              ),
              ListTile(
                title: const Text('Notification permission'),
                subtitle: const Text(
                  'Needed to alert you when a session ends.',
                ),
                trailing: TextButton(
                  onPressed: () =>
                      controller.requestNotificationPermission(),
                  child: const Text('Allow'),
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle(context, 'Automation'),
              SwitchListTile(
                title: const Text('Start breaks automatically'),
                subtitle: const Text('Begin the break right after a focus.'),
                value: settings.autoStartBreaks,
                onChanged: (v) => controller.updateSettings(
                  settings.copyWith(autoStartBreaks: v),
                ),
              ),
              SwitchListTile(
                title: const Text('Start focus automatically'),
                subtitle: const Text(
                  'Begin the next focus right after a break.',
                ),
                value: settings.autoStartFocus,
                onChanged: (v) => controller.updateSettings(
                  settings.copyWith(autoStartFocus: v),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'FocusForge 1.0.0 · Local-first: your data never leaves '
                  'this phone.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  /// A row with - / value / + steppers for a numeric setting.
  Widget _durationTile(
    BuildContext context, {
    required String label,
    required int value,
    required int min,
    required int max,
    required int step,
    required String suffix,
    required ValueChanged<int> onChanged,
  }) {
    return ListTile(
      title: Text(label),
      subtitle: Text('$value $suffix'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: 'Decrease',
            onPressed: value > min
                ? () => onChanged((value - step).clamp(min, max))
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Increase',
            onPressed: value < max
                ? () => onChanged((value + step).clamp(min, max))
                : null,
          ),
        ],
      ),
    );
  }
}
