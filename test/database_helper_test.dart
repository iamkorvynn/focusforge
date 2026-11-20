import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:focusforge/db/database_helper.dart';
import 'package:focusforge/models/app_settings.dart';
import 'package:focusforge/models/focus_task.dart';
import 'package:focusforge/models/session_record.dart';
import 'package:focusforge/models/timer_phase.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // In-memory database: this file never touches the real database file,
    // so it cannot disturb other test files running in parallel.
    DatabaseHelper.useInMemory = true;
  });

  setUp(() async {
    // Fresh empty database for every test (closing drops the in-memory DB).
    await DatabaseHelper.instance.close();
  });

  group('tasks', () {
    test('insert and read back a task', () async {
      final db = DatabaseHelper.instance;
      final id = await db.insertTask(
        FocusTask(title: 'Study Flutter', notes: 'chapter 3'),
      );
      expect(id, greaterThan(0));
      final tasks = await db.getAllTasks();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Study Flutter');
      expect(tasks.first.notes, 'chapter 3');
      expect(tasks.first.isCompleted, isFalse);
    });

    test('starts empty: no demo tasks', () async {
      expect(await DatabaseHelper.instance.getAllTasks(), isEmpty);
    });

    test('update and complete a task', () async {
      final db = DatabaseHelper.instance;
      final id = await db.insertTask(FocusTask(title: 'Revise notes'));
      final task = (await db.getTaskById(id))!;
      await db.updateTask(task.copyWith(isCompleted: true));
      final updated = (await db.getTaskById(id))!;
      expect(updated.isCompleted, isTrue);
    });

    test('delete removes the task', () async {
      final db = DatabaseHelper.instance;
      final id = await db.insertTask(FocusTask(title: 'Temp'));
      await db.deleteTask(id);
      expect(await db.getTaskById(id), isNull);
    });

    test('addFocusTimeToTask accumulates time and sessions', () async {
      final db = DatabaseHelper.instance;
      final id = await db.insertTask(FocusTask(title: 'Deep work'));
      await db.addFocusTimeToTask(id, 1500);
      await db.addFocusTimeToTask(id, 900);
      final task = (await db.getTaskById(id))!;
      expect(task.totalFocusSeconds, 2400);
      expect(task.completedSessions, 2);
    });
  });

  group('sessions', () {
    test('insert and list sessions newest first', () async {
      final db = DatabaseHelper.instance;
      final now = DateTime(2026, 11, 20, 12);
      await db.insertSession(
        SessionRecord(
          phase: TimerPhase.focus,
          startedAt: now.subtract(const Duration(minutes: 25)),
          endedAt: now,
          plannedSeconds: 1500,
          actualSeconds: 1500,
        ),
      );
      await db.insertSession(
        SessionRecord(
          phase: TimerPhase.focus,
          startedAt: now.subtract(const Duration(hours: 2)),
          endedAt: now.subtract(const Duration(hours: 1)),
          plannedSeconds: 1500,
          actualSeconds: 1500,
        ),
      );
      final recent = await db.getRecentSessions();
      expect(recent.length, 2);
      expect(recent.first.endedAt, now);
      expect(await db.getTotalCompletedSessions(), 2);
      expect(await db.getTotalFocusSeconds(), 3000);
    });

    test('range query only returns completed focus in range', () async {
      final db = DatabaseHelper.instance;
      final day = DateTime(2026, 11, 20);
      await db.insertSession(
        SessionRecord(
          phase: TimerPhase.focus,
          startedAt: day.add(const Duration(hours: 9)),
          endedAt: day.add(const Duration(hours: 9, minutes: 25)),
          plannedSeconds: 1500,
          actualSeconds: 1500,
        ),
      );
      await db.insertSession(
        SessionRecord(
          phase: TimerPhase.shortBreak,
          startedAt: day.add(const Duration(hours: 10)),
          endedAt: day.add(const Duration(hours: 10, minutes: 5)),
          plannedSeconds: 300,
          actualSeconds: 300,
        ),
      );
      final inRange = await db.getFocusSessionsBetween(
        day,
        day.add(const Duration(hours: 23)),
      );
      expect(inRange.length, 1);
      expect(inRange.first.phase, TimerPhase.focus);
    });

    test('clearAllSessions empties history', () async {
      final db = DatabaseHelper.instance;
      final now = DateTime.now();
      await db.insertSession(
        SessionRecord(
          phase: TimerPhase.focus,
          startedAt: now,
          endedAt: now,
          plannedSeconds: 1500,
          actualSeconds: 1500,
        ),
      );
      await db.clearAllSessions();
      expect(await db.getRecentSessions(), isEmpty);
      expect(await db.getTotalFocusSeconds(), 0);
    });
  });

  group('settings and timer state', () {
    test('settings default when nothing saved, then round-trip', () async {
      final db = DatabaseHelper.instance;
      expect((await db.getSettings()).focusMinutes, 25);
      await db.saveSettings(AppSettings(focusMinutes: 50));
      expect((await db.getSettings()).focusMinutes, 50);
    });

    test('timer state round-trip', () async {
      final db = DatabaseHelper.instance;
      expect(await db.getTimerState(), isNull);
      final startedAt = DateTime(2026, 11, 20, 10);
      await db.saveTimerState(
        phase: TimerPhase.focus,
        remainingSeconds: 1200,
        totalSeconds: 1500,
        endsAt: startedAt.add(const Duration(seconds: 1200)),
        isRunning: true,
        taskId: 3,
        startedAt: startedAt,
        completedInCycle: 1,
      );
      final saved = (await db.getTimerState())!;
      expect(saved['phase'], 'focus');
      expect(saved['remaining_seconds'], 1200);
      expect(saved['is_running'], 1);
      expect(saved['task_id'], 3);
      await db.clearTimerState();
      expect(await db.getTimerState(), isNull);
    });
  });
}
