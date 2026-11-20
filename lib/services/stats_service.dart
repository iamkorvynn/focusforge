import '../models/session_record.dart';
import '../models/timer_phase.dart';
import '../utils/time_format.dart';

/// Pure statistics over recorded sessions. No database or Flutter imports,
/// so every function here is directly unit-testable.

/// Completed focus seconds per day, oldest first, ending on [endDay].
/// [days] controls how many days are included (7 = last week).
List<int> focusSecondsPerDay(
  List<SessionRecord> sessions, {
  required DateTime endDay,
  int days = 7,
}) {
  final result = List<int>.filled(days, 0);
  final start = DateTime(endDay.year, endDay.month, endDay.day)
      .subtract(Duration(days: days - 1));
  for (final session in sessions) {
    if (!session.completed || session.phase != TimerPhase.focus) continue;
    final day = DateTime(
      session.endedAt.year,
      session.endedAt.month,
      session.endedAt.day,
    );
    final index = day.difference(start).inDays;
    if (index >= 0 && index < days) {
      result[index] += session.actualSeconds;
    }
  }
  return result;
}

/// Total completed focus seconds in the list.
int totalFocusSeconds(List<SessionRecord> sessions) {
  var total = 0;
  for (final session in sessions) {
    if (session.completed && session.phase == TimerPhase.focus) {
      total += session.actualSeconds;
    }
  }
  return total;
}

/// Number of completed focus sessions in the list.
int completedFocusSessionCount(List<SessionRecord> sessions) {
  var count = 0;
  for (final session in sessions) {
    if (session.completed && session.phase == TimerPhase.focus) count++;
  }
  return count;
}

/// Consecutive days with at least one completed focus session, counting
/// back from [today]. If today has no session yet, the streak counts back
/// from yesterday (a streak is not broken by the current day being young).
int currentStreakDays(List<SessionRecord> sessions, {DateTime? today}) {
  final now = today ?? DateTime.now();
  final daysWithFocus = <DateTime>{};
  for (final session in sessions) {
    if (!session.completed || session.phase != TimerPhase.focus) continue;
    daysWithFocus.add(
      DateTime(session.endedAt.year, session.endedAt.month, session.endedAt.day),
    );
  }
  var cursor = DateTime(now.year, now.month, now.day);
  if (!daysWithFocus.contains(cursor)) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  var streak = 0;
  while (daysWithFocus.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

/// Completed focus seconds per task id. Sessions without a task are skipped.
Map<int, int> focusSecondsByTask(List<SessionRecord> sessions) {
  final result = <int, int>{};
  for (final session in sessions) {
    final taskId = session.taskId;
    if (!session.completed || session.phase != TimerPhase.focus || taskId == null) {
      continue;
    }
    result[taskId] = (result[taskId] ?? 0) + session.actualSeconds;
  }
  return result;
}

/// Average completed focus minutes per day over the last [days] days.
double averageFocusMinutesPerDay(
  List<SessionRecord> sessions, {
  required DateTime endDay,
  int days = 7,
}) {
  final perDay = focusSecondsPerDay(sessions, endDay: endDay, days: days);
  final total = perDay.fold<int>(0, (sum, value) => sum + value);
  return total / 60 / days;
}

/// Human label for a per-day bar, e.g. `2h 5m` or `45m`.
String dayTotalLabel(int seconds) => formatSecondsShort(seconds);
