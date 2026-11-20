import 'package:flutter_test/flutter_test.dart';
import 'package:focusforge/models/session_record.dart';
import 'package:focusforge/models/timer_phase.dart';
import 'package:focusforge/services/stats_service.dart';

SessionRecord focusSession({
  required DateTime endedAt,
  int actualSeconds = 1500,
  int? taskId,
  bool completed = true,
}) {
  return SessionRecord(
    taskId: taskId,
    phase: TimerPhase.focus,
    startedAt: endedAt.subtract(Duration(seconds: actualSeconds)),
    endedAt: endedAt,
    plannedSeconds: 1500,
    actualSeconds: actualSeconds,
    completed: completed,
  );
}

SessionRecord breakSession({required DateTime endedAt}) {
  return SessionRecord(
    phase: TimerPhase.shortBreak,
    startedAt: endedAt.subtract(const Duration(seconds: 300)),
    endedAt: endedAt,
    plannedSeconds: 300,
    actualSeconds: 300,
  );
}

void main() {
  // Reference week: Fri 2026-11-20 is "today".
  final today = DateTime(2026, 11, 20, 12);
  final sessions = <SessionRecord>[
    focusSession(endedAt: DateTime(2026, 11, 20, 10), taskId: 1),
    focusSession(
      endedAt: DateTime(2026, 11, 20, 11),
      actualSeconds: 1500,
      taskId: 1,
    ),
    focusSession(endedAt: DateTime(2026, 11, 19, 10), taskId: 2),
    focusSession(endedAt: DateTime(2026, 11, 18, 10), taskId: 1),
    focusSession(
      endedAt: DateTime(2026, 11, 15, 10),
      actualSeconds: 900,
      taskId: 2,
    ),
    // Breaks and incomplete sessions must not count as focus time.
    breakSession(endedAt: DateTime(2026, 11, 20, 9)),
    focusSession(
      endedAt: DateTime(2026, 11, 20, 8),
      completed: false,
    ),
  ];

  group('focusSecondsPerDay', () {
    test('buckets sessions by end day, oldest first', () {
      final perDay = focusSecondsPerDay(sessions, endDay: today, days: 7);
      expect(perDay.length, 7);
      // Days: 14, 15, 16, 17, 18, 19, 20 Nov.
      expect(perDay[0], 0); // Nov 14
      expect(perDay[1], 900); // Nov 15
      expect(perDay[2], 0); // Nov 16
      expect(perDay[3], 0); // Nov 17
      expect(perDay[4], 1500); // Nov 18
      expect(perDay[5], 1500); // Nov 19
      expect(perDay[6], 3000); // Nov 20
    });
  });

  group('totals', () {
    test('totalFocusSeconds ignores breaks and incomplete sessions', () {
      expect(totalFocusSeconds(sessions), 1500 + 1500 + 1500 + 1500 + 900);
    });

    test('completedFocusSessionCount counts only completed focus', () {
      expect(completedFocusSessionCount(sessions), 5);
    });
  });

  group('currentStreakDays', () {
    test('counts consecutive days back from today', () {
      // Nov 18, 19, 20 all have sessions -> streak 3 (Nov 17 breaks it).
      expect(currentStreakDays(sessions, today: today), 3);
    });

    test('today with no session yet still counts from yesterday', () {
      final onlyYesterday = [
        focusSession(endedAt: DateTime(2026, 11, 19, 10)),
        focusSession(endedAt: DateTime(2026, 11, 18, 10)),
      ];
      expect(currentStreakDays(onlyYesterday, today: today), 2);
    });

    test('empty history means no streak', () {
      expect(currentStreakDays([], today: today), 0);
    });

    test('a gap breaks the streak', () {
      final gapped = [
        focusSession(endedAt: DateTime(2026, 11, 20, 10)),
        focusSession(endedAt: DateTime(2026, 11, 18, 10)),
      ];
      expect(currentStreakDays(gapped, today: today), 1);
    });
  });

  group('focusSecondsByTask', () {
    test('sums per task, skips untracked sessions', () {
      final byTask = focusSecondsByTask(sessions);
      expect(byTask[1], 1500 + 1500 + 1500);
      expect(byTask[2], 1500 + 900);
      expect(byTask.length, 2);
    });
  });

  test('averageFocusMinutesPerDay over the last 7 days', () {
    final avg = averageFocusMinutesPerDay(
      sessions,
      endDay: today,
      days: 7,
    );
    // Total 6900s = 115 min over 7 days.
    expect(avg, closeTo(115 / 7, 0.001));
  });
}
