import 'package:flutter_test/flutter_test.dart';
import 'package:focusforge/models/app_settings.dart';
import 'package:focusforge/models/timer_phase.dart';
import 'package:focusforge/services/focus_timer.dart';

/// Short settings so a full phase completes after 60 ticks.
AppSettings shortSettings() {
  return AppSettings(
    focusMinutes: 1,
    shortBreakMinutes: 1,
    longBreakMinutes: 1,
    sessionsBeforeLongBreak: 2,
  );
}

void _tickTimes(FocusTimer timer, int times) {
  for (var i = 0; i < times; i++) {
    timer.tick();
  }
}

void main() {
  group('FocusTimer initial state', () {
    test('starts idle on focus with the configured duration', () {
      final timer = FocusTimer(settings: AppSettings());
      expect(timer.phase, TimerPhase.focus);
      expect(timer.status, TimerStatus.idle);
      expect(timer.totalSeconds, 25 * 60);
      expect(timer.remainingSeconds, 25 * 60);
      expect(timer.progress, 0);
    });
  });

  group('FocusTimer start / pause / resume / reset', () {
    test('start runs, tick counts down', () {
      final timer = FocusTimer(settings: shortSettings());
      timer.start();
      expect(timer.status, TimerStatus.running);
      _tickTimes(timer, 10);
      expect(timer.remainingSeconds, 50);
      expect(timer.progress, closeTo(10 / 60, 0.001));
    });

    test('pause freezes the countdown, resume continues', () {
      final timer = FocusTimer(settings: shortSettings());
      timer.start();
      _tickTimes(timer, 10);
      timer.pause();
      expect(timer.status, TimerStatus.paused);
      _tickTimes(timer, 10);
      expect(timer.remainingSeconds, 50);
      timer.start();
      expect(timer.status, TimerStatus.running);
      _tickTimes(timer, 10);
      expect(timer.remainingSeconds, 40);
    });

    test('reset returns to the full phase length', () {
      final timer = FocusTimer(settings: shortSettings());
      timer.start();
      _tickTimes(timer, 30);
      timer.reset();
      expect(timer.status, TimerStatus.idle);
      expect(timer.remainingSeconds, 60);
    });

    test('starting twice does not restart the countdown', () {
      final timer = FocusTimer(settings: shortSettings());
      timer.start();
      _tickTimes(timer, 10);
      timer.start();
      expect(timer.remainingSeconds, 50);
    });
  });

  group('FocusTimer phase completion', () {
    test('focus completes into a short break', () {
      TimerPhase? finished;
      var completed = false;
      final timer = FocusTimer(
        settings: shortSettings(),
        onPhaseFinished: (phase, done) {
          finished = phase;
          completed = done;
        },
      );
      timer.start();
      _tickTimes(timer, 60);
      expect(finished, TimerPhase.focus);
      expect(completed, isTrue);
      expect(timer.phase, TimerPhase.shortBreak);
      expect(timer.status, TimerStatus.idle);
      expect(timer.completedInCycle, 1);
    });

    test('long break after the configured number of focus sessions', () {
      final timer = FocusTimer(settings: shortSettings());
      // Focus 1 -> short break.
      timer.start();
      _tickTimes(timer, 60);
      expect(timer.phase, TimerPhase.shortBreak);
      // Break -> focus.
      timer.start();
      _tickTimes(timer, 60);
      expect(timer.phase, TimerPhase.focus);
      // Focus 2 -> long break, cycle resets.
      timer.start();
      _tickTimes(timer, 60);
      expect(timer.phase, TimerPhase.longBreak);
      expect(timer.completedInCycle, 0);
    });

    test('skip ends the phase as incomplete and keeps the phase', () {
      TimerPhase? finished;
      var completed = true;
      final timer = FocusTimer(
        settings: shortSettings(),
        onPhaseFinished: (phase, done) {
          finished = phase;
          completed = done;
        },
      );
      timer.start();
      _tickTimes(timer, 20);
      timer.skip();
      expect(finished, TimerPhase.focus);
      expect(completed, isFalse);
      expect(timer.phase, TimerPhase.focus);
      expect(timer.remainingSeconds, 60);
    });

    test('selectPhase is ignored while running', () {
      final timer = FocusTimer(settings: shortSettings());
      timer.start();
      timer.selectPhase(TimerPhase.longBreak);
      expect(timer.phase, TimerPhase.focus);
    });

    test('selectPhase while idle switches and resets', () {
      final timer = FocusTimer(settings: shortSettings());
      timer.selectPhase(TimerPhase.longBreak);
      expect(timer.phase, TimerPhase.longBreak);
      expect(timer.totalSeconds, 60);
    });
  });

  group('FocusTimer restore', () {
    test('running timer restores with remaining time from endsAt', () {
      final now = DateTime(2026, 11, 20, 10, 0, 0);
      final timer = FocusTimer(settings: shortSettings());
      final restored = timer.restore(
        savedPhase: TimerPhase.focus,
        savedRemainingSeconds: 45,
        savedTotalSeconds: 60,
        savedIsRunning: true,
        savedEndsAt: now.add(const Duration(seconds: 45)),
        savedTaskId: 7,
        savedStartedAt: now.subtract(const Duration(seconds: 15)),
        savedCompletedInCycle: 1,
        now: now,
      );
      expect(restored, isTrue);
      expect(timer.status, TimerStatus.running);
      expect(timer.remainingSeconds, 45);
      expect(timer.taskId, 7);
      expect(timer.completedInCycle, 1);
    });

    test('timer whose end passed while the app was dead finishes at once',
        () {
      var finished = false;
      final now = DateTime(2026, 11, 20, 10, 0, 0);
      final timer = FocusTimer(
        settings: shortSettings(),
        onPhaseFinished: (_, _) => finished = true,
      );
      timer.restore(
        savedPhase: TimerPhase.focus,
        savedRemainingSeconds: 45,
        savedTotalSeconds: 60,
        savedIsRunning: true,
        savedEndsAt: now.subtract(const Duration(seconds: 5)),
        savedCompletedInCycle: 0,
        now: now,
      );
      expect(finished, isTrue);
      expect(timer.phase, TimerPhase.shortBreak);
    });

    test('paused timer restores as idle with its remaining time', () {
      final timer = FocusTimer(settings: shortSettings());
      final restored = timer.restore(
        savedPhase: TimerPhase.focus,
        savedRemainingSeconds: 30,
        savedTotalSeconds: 60,
        savedIsRunning: false,
        savedCompletedInCycle: 0,
      );
      expect(restored, isFalse);
      expect(timer.status, TimerStatus.idle);
      expect(timer.remainingSeconds, 30);
    });
  });
}
