import 'package:flutter_test/flutter_test.dart';
import 'package:focusforge/models/app_settings.dart';

void main() {
  group('AppSettings defaults', () {
    test('classic Pomodoro defaults', () {
      final settings = AppSettings();
      expect(settings.focusMinutes, 25);
      expect(settings.shortBreakMinutes, 5);
      expect(settings.longBreakMinutes, 15);
      expect(settings.sessionsBeforeLongBreak, 4);
      expect(settings.dailyGoalMinutes, 120);
      expect(settings.dailyGoalSessions, 8);
      expect(settings.soundEnabled, isTrue);
      expect(settings.vibrationEnabled, isTrue);
      expect(settings.autoStartBreaks, isFalse);
      expect(settings.autoStartFocus, isFalse);
    });

    test('secondsForPhase uses the configured minutes', () {
      final settings = AppSettings();
      expect(settings.secondsForPhase('focus'), 25 * 60);
      expect(settings.secondsForPhase('short_break'), 5 * 60);
      expect(settings.secondsForPhase('long_break'), 15 * 60);
    });
  });

  group('AppSettings map round-trip', () {
    test('toMap/fromMap preserves every field', () {
      final original = AppSettings(
        focusMinutes: 50,
        shortBreakMinutes: 10,
        longBreakMinutes: 30,
        sessionsBeforeLongBreak: 3,
        dailyGoalMinutes: 240,
        dailyGoalSessions: 6,
        soundEnabled: false,
        vibrationEnabled: false,
        autoStartBreaks: true,
        autoStartFocus: true,
      );
      final restored = AppSettings.fromMap(original.toMap());
      expect(restored.focusMinutes, 50);
      expect(restored.shortBreakMinutes, 10);
      expect(restored.longBreakMinutes, 30);
      expect(restored.sessionsBeforeLongBreak, 3);
      expect(restored.dailyGoalMinutes, 240);
      expect(restored.dailyGoalSessions, 6);
      expect(restored.soundEnabled, isFalse);
      expect(restored.vibrationEnabled, isFalse);
      expect(restored.autoStartBreaks, isTrue);
      expect(restored.autoStartFocus, isTrue);
    });

    test('fromMap falls back to defaults on missing keys', () {
      final restored = AppSettings.fromMap({});
      expect(restored.focusMinutes, 25);
      expect(restored.soundEnabled, isTrue);
    });
  });

  test('copyWith changes only the given fields', () {
    final settings = AppSettings().copyWith(focusMinutes: 45);
    expect(settings.focusMinutes, 45);
    expect(settings.shortBreakMinutes, 5);
  });
}
