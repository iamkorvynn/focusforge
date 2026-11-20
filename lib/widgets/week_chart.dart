import 'package:material_ui/material_ui.dart';

import '../utils/time_format.dart';

/// Seven vertical bars for the last 7 days of focus time, oldest on the
/// left, today on the right. Drawn with plain widgets — no chart package.
class WeekChart extends StatelessWidget {
  const WeekChart({
    super.key,
    required this.secondsPerDay,
    required this.dayLabels,
    this.barColor,
    this.height = 140,
  });

  /// Exactly 7 values, oldest first.
  final List<int> secondsPerDay;

  /// Exactly 7 short labels (e.g. Mon, Tue...), oldest first.
  final List<String> dayLabels;
  final Color? barColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = barColor ?? theme.colorScheme.primary;
    final max = secondsPerDay.fold<int>(0, (m, v) => v > m ? v : m);
    return Column(
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final value = secondsPerDay[index];
              final fraction = max == 0 ? 0.0 : value / max;
              final isToday = index == 6;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        value == 0 ? '' : formatSecondsShort(value),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: (height - 34) * fraction + (value > 0 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: value == 0
                              ? theme.colorScheme.surfaceContainerHighest
                              : (isToday
                                  ? color
                                  : color.withValues(alpha: 0.55)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(7, (index) {
            final isToday = index == 6;
            return Expanded(
              child: Text(
                dayLabels[index],
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                  color: isToday
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
