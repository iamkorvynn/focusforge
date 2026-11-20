import '../models/app_settings.dart';
import '../models/timer_phase.dart';

/// Whether the timer is waiting, counting down, or paused.
enum TimerStatus { idle, running, paused }

/// A pure, UI-free Pomodoro state machine.
///
/// It owns no timers and no platform code: the controller calls [tick]
/// once a second (or [syncFromEndsAt] after the app returns from the
/// background) and reacts to [onPhaseFinished]. That makes the whole cycle
/// unit-testable without a clock.
///
/// Phase flow: focus -> short break (or long break after
/// [AppSettings.sessionsBeforeLongBreak] focus sessions) -> focus ...
class FocusTimer {
  FocusTimer({
    required this.settings,
    this.onPhaseFinished,
  }) {
    _applyPhaseDuration();
  }

  AppSettings settings;

  /// Called when a phase ends. `completed` is false when the user skipped
  /// the phase early; the controller uses it to decide what to log.
  void Function(TimerPhase phase, bool completed)? onPhaseFinished;

  TimerPhase phase = TimerPhase.focus;
  TimerStatus status = TimerStatus.idle;

  /// Length of the current phase, in seconds.
  int totalSeconds = 0;

  /// Seconds left in the current phase.
  int remainingSeconds = 0;

  /// Focus sessions finished since the last long break.
  int completedInCycle = 0;

  /// When the current run started (used for session logging).
  DateTime? startedAt;

  /// Wall-clock instant the running phase should end. Persisted so the
  /// timer survives the app being killed.
  DateTime? endsAt;

  /// Task the current focus session is linked to, if any.
  int? taskId;

  /// Details of the most recently finished phase, captured before the
  /// timer advances to the next phase. The controller reads these in
  /// [onPhaseFinished] to log the session.
  TimerPhase? lastFinishedPhase;
  int lastFinishedPlannedSeconds = 0;
  int lastFinishedActualSeconds = 0;
  DateTime? lastFinishedStartedAt;
  int? lastFinishedTaskId;

  double get progress {
    if (totalSeconds <= 0) return 0;
    return 1 - (remainingSeconds / totalSeconds);
  }

  bool get isFocusPhase => phase == TimerPhase.focus;

  void _applyPhaseDuration() {
    totalSeconds = settings.secondsForPhase(phase.storageKey);
    remainingSeconds = totalSeconds;
  }

  /// Switches to [newPhase] and resets the countdown. Does not start it.
  void selectPhase(TimerPhase newPhase) {
    if (status == TimerStatus.running) return;
    phase = newPhase;
    status = TimerStatus.idle;
    startedAt = null;
    endsAt = null;
    _applyPhaseDuration();
  }

  /// Starts the current phase, or resumes it after a pause.
  void start({DateTime? now}) {
    final at = now ?? DateTime.now();
    if (status == TimerStatus.running) return;
    if (status == TimerStatus.paused) {
      status = TimerStatus.running;
      endsAt = at.add(Duration(seconds: remainingSeconds));
      return;
    }
    // Idle: fresh run of the current phase.
    _applyPhaseDuration();
    startedAt = at;
    endsAt = at.add(Duration(seconds: remainingSeconds));
    status = TimerStatus.running;
  }

  /// Pauses the countdown. The remaining time is kept.
  void pause() {
    if (status != TimerStatus.running) return;
    status = TimerStatus.paused;
    endsAt = null;
  }

  /// Stops the countdown and resets the phase to its full length.
  void reset() {
    status = TimerStatus.idle;
    startedAt = null;
    endsAt = null;
    _applyPhaseDuration();
  }

  /// One second of countdown. Called by the controller's periodic timer.
  void tick() {
    if (status != TimerStatus.running) return;
    if (remainingSeconds > 0) remainingSeconds--;
    if (remainingSeconds <= 0) _finish(completed: true);
  }

  /// Recomputes the remaining time from the persisted end instant. Used
  /// when the app comes back from the background, where the periodic
  /// ticker may have been throttled.
  void syncFromEndsAt(DateTime now) {
    if (status != TimerStatus.running || endsAt == null) return;
    final left = endsAt!.difference(now).inSeconds;
    remainingSeconds = left.clamp(0, totalSeconds);
    if (remainingSeconds <= 0) _finish(completed: true);
  }

  /// Ends the current phase early. Counts as not completed.
  void skip() {
    if (status == TimerStatus.idle) return;
    _finish(completed: false);
  }

  void _finish({required bool completed}) {
    final finishedPhase = phase;
    // Capture the finished run before advancing to the next phase.
    lastFinishedPhase = finishedPhase;
    lastFinishedPlannedSeconds = totalSeconds;
    lastFinishedActualSeconds =
        completed ? totalSeconds : totalSeconds - remainingSeconds;
    lastFinishedStartedAt = startedAt;
    lastFinishedTaskId = taskId;
    status = TimerStatus.idle;
    endsAt = null;
    if (completed && finishedPhase == TimerPhase.focus) {
      completedInCycle++;
    }
    if (completed) {
      _advancePhase();
    } else {
      // A skipped phase leaves the phase as-is; the user picks what is next.
      remainingSeconds = totalSeconds;
    }
    onPhaseFinished?.call(finishedPhase, completed);
  }

  void _advancePhase() {
    if (phase == TimerPhase.focus) {
      if (completedInCycle >= settings.sessionsBeforeLongBreak) {
        completedInCycle = 0;
        phase = TimerPhase.longBreak;
      } else {
        phase = TimerPhase.shortBreak;
      }
    } else {
      phase = TimerPhase.focus;
    }
    startedAt = null;
    _applyPhaseDuration();
  }

  /// Restores a previously persisted timer (app relaunch after a kill).
  /// Returns true when a running timer was restored.
  bool restore({
    required TimerPhase savedPhase,
    required int savedRemainingSeconds,
    required int savedTotalSeconds,
    required bool savedIsRunning,
    DateTime? savedEndsAt,
    int? savedTaskId,
    DateTime? savedStartedAt,
    required int savedCompletedInCycle,
    DateTime? now,
  }) {
    phase = savedPhase;
    totalSeconds = savedTotalSeconds;
    remainingSeconds = savedRemainingSeconds;
    completedInCycle = savedCompletedInCycle;
    taskId = savedTaskId;
    startedAt = savedStartedAt;
    final at = now ?? DateTime.now();
    if (savedIsRunning && savedEndsAt != null) {
      endsAt = savedEndsAt;
      status = TimerStatus.running;
      syncFromEndsAt(at);
      return status == TimerStatus.running;
    }
    status = TimerStatus.idle;
    endsAt = null;
    return false;
  }
}
