/// User-tunable settings for the timer. Stored as a single row (id = 1)
/// in the `settings` table. Every field has a sensible default so a fresh
/// install works with zero configuration.
class AppSettings {
  AppSettings({
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsBeforeLongBreak = 4,
    this.dailyGoalMinutes = 120,
    this.dailyGoalSessions = 8,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.autoStartBreaks = false,
    this.autoStartFocus = false,
  });

  int focusMinutes;
  int shortBreakMinutes;
  int longBreakMinutes;
  int sessionsBeforeLongBreak;
  int dailyGoalMinutes;
  int dailyGoalSessions;
  bool soundEnabled;
  bool vibrationEnabled;
  bool autoStartBreaks;
  bool autoStartFocus;

  /// Duration in seconds for a phase, from the current settings.
  int secondsForPhase(String phaseKey) {
    switch (phaseKey) {
      case 'short_break':
        return shortBreakMinutes * 60;
      case 'long_break':
        return longBreakMinutes * 60;
      case 'focus':
      default:
        return focusMinutes * 60;
    }
  }

  Map<String, Object?> toMap() {
    return {
      'id': 1,
      'focus_minutes': focusMinutes,
      'short_break_minutes': shortBreakMinutes,
      'long_break_minutes': longBreakMinutes,
      'sessions_before_long_break': sessionsBeforeLongBreak,
      'daily_goal_minutes': dailyGoalMinutes,
      'daily_goal_sessions': dailyGoalSessions,
      'sound_enabled': soundEnabled ? 1 : 0,
      'vibration_enabled': vibrationEnabled ? 1 : 0,
      'auto_start_breaks': autoStartBreaks ? 1 : 0,
      'auto_start_focus': autoStartFocus ? 1 : 0,
    };
  }

  factory AppSettings.fromMap(Map<String, Object?> map) {
    return AppSettings(
      focusMinutes: (map['focus_minutes'] as int?) ?? 25,
      shortBreakMinutes: (map['short_break_minutes'] as int?) ?? 5,
      longBreakMinutes: (map['long_break_minutes'] as int?) ?? 15,
      sessionsBeforeLongBreak: (map['sessions_before_long_break'] as int?) ?? 4,
      dailyGoalMinutes: (map['daily_goal_minutes'] as int?) ?? 120,
      dailyGoalSessions: (map['daily_goal_sessions'] as int?) ?? 8,
      soundEnabled: ((map['sound_enabled'] as int?) ?? 1) == 1,
      vibrationEnabled: ((map['vibration_enabled'] as int?) ?? 1) == 1,
      autoStartBreaks: ((map['auto_start_breaks'] as int?) ?? 0) == 1,
      autoStartFocus: ((map['auto_start_focus'] as int?) ?? 0) == 1,
    );
  }

  AppSettings copyWith({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? sessionsBeforeLongBreak,
    int? dailyGoalMinutes,
    int? dailyGoalSessions,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? autoStartBreaks,
    bool? autoStartFocus,
  }) {
    return AppSettings(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      sessionsBeforeLongBreak:
          sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      dailyGoalSessions: dailyGoalSessions ?? this.dailyGoalSessions,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartFocus: autoStartFocus ?? this.autoStartFocus,
    );
  }
}
