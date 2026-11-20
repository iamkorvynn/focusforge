import 'package:material_ui/material_ui.dart';

import '../models/timer_phase.dart';

/// Three chips to pick the phase (Focus / Short Break / Long Break).
/// Disabled while the timer is running — pick a phase before you start.
class PhaseSelector extends StatelessWidget {
  const PhaseSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.enabled,
  });

  final TimerPhase selected;
  final ValueChanged<TimerPhase> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final phases = TimerPhase.values;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: phases.map((phase) {
        final isSelected = phase == selected;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(phase.label),
            selected: isSelected,
            onSelected: enabled ? (_) => onSelected(phase) : null,
          ),
        );
      }).toList(),
    );
  }
}
