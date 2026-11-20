/// The three phases of a Pomodoro cycle.
enum TimerPhase { focus, shortBreak, longBreak }

extension TimerPhaseLabel on TimerPhase {
  /// Short label shown on the phase chips.
  String get label {
    switch (this) {
      case TimerPhase.focus:
        return 'Focus';
      case TimerPhase.shortBreak:
        return 'Short Break';
      case TimerPhase.longBreak:
        return 'Long Break';
    }
  }

  /// Longer description shown under the timer.
  String get description {
    switch (this) {
      case TimerPhase.focus:
        return 'Time to focus. One thing at a time.';
      case TimerPhase.shortBreak:
        return 'Quick breather. Stretch, drink water.';
      case TimerPhase.longBreak:
        return 'Well earned. Take a proper break.';
    }
  }

  /// Storage key used in the database.
  String get storageKey {
    switch (this) {
      case TimerPhase.focus:
        return 'focus';
      case TimerPhase.shortBreak:
        return 'short_break';
      case TimerPhase.longBreak:
        return 'long_break';
    }
  }

  static TimerPhase fromStorageKey(String key) {
    switch (key) {
      case 'short_break':
        return TimerPhase.shortBreak;
      case 'long_break':
        return TimerPhase.longBreak;
      case 'focus':
      default:
        return TimerPhase.focus;
    }
  }
}
