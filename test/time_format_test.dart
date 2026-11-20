import 'package:flutter_test/flutter_test.dart';
import 'package:focusforge/utils/time_format.dart';

void main() {
  group('formatDuration', () {
    test('zero seconds', () {
      expect(formatDuration(Duration.zero), '00:00');
    });

    test('seconds only', () {
      expect(formatDuration(const Duration(seconds: 45)), '00:45');
    });

    test('minutes and seconds', () {
      expect(formatDuration(const Duration(minutes: 25)), '25:00');
      expect(formatDuration(const Duration(seconds: 65)), '01:05');
    });

    test('hours use H:MM:SS', () {
      expect(formatDuration(const Duration(seconds: 3661)), '1:01:01');
    });

    test('negative clamps to zero', () {
      expect(formatDuration(const Duration(seconds: -5)), '00:00');
    });
  });

  group('formatSecondsShort', () {
    test('seconds', () {
      expect(formatSecondsShort(30), '30s');
    });

    test('minutes', () {
      expect(formatSecondsShort(90), '1m');
      expect(formatSecondsShort(3599), '59m');
    });

    test('hours', () {
      expect(formatSecondsShort(3600), '1h');
      expect(formatSecondsShort(3900), '1h 5m');
      expect(formatSecondsShort(7200), '2h');
    });
  });

  group('isSameDay', () {
    test('same day, different times', () {
      expect(
        isSameDay(DateTime(2026, 11, 20, 8), DateTime(2026, 11, 20, 23)),
        isTrue,
      );
    });

    test('different days', () {
      expect(
        isSameDay(DateTime(2026, 11, 20), DateTime(2026, 11, 21)),
        isFalse,
      );
    });
  });

  test('formatDayLabel', () {
    // 2026-11-20 is a Friday.
    expect(formatDayLabel(DateTime(2026, 11, 20)), 'Fri 20 Nov');
  });
}
