import 'package:day_break/models/recurrence_pattern.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecurrencePattern', () {
    test('displayName returns correct human-readable names', () {
      expect(
        RecurrencePattern.daily.displayName,
        'Daily',
        reason: 'Daily pattern should have correct display name',
      );
      expect(
        RecurrencePattern.weekdays.displayName,
        'Weekdays',
        reason: 'Weekdays pattern should have correct display name',
      );
      expect(
        RecurrencePattern.weekends.displayName,
        'Weekends',
        reason: 'Weekends pattern should have correct display name',
      );
      expect(
        RecurrencePattern.custom.displayName,
        'Custom',
        reason: 'Custom pattern should have correct display name',
      );
    });

    test('defaultDays returns correct day lists', () {
      expect(
        RecurrencePattern.daily.defaultDays,
        [1, 2, 3, 4, 5, 6, 7],
        reason: 'Daily should include all days of the week',
      );
      expect(
        RecurrencePattern.weekdays.defaultDays,
        [1, 2, 3, 4, 5],
        reason: 'Weekdays should include Monday through Friday',
      );
      expect(
        RecurrencePattern.weekends.defaultDays,
        [6, 7],
        reason: 'Weekends should include Saturday and Sunday',
      );
      expect(
        RecurrencePattern.custom.defaultDays,
        [],
        reason: 'Custom pattern should have no default days',
      );
    });

    test('enum values are correctly ordered', () {
      expect(
        RecurrencePattern.values.length,
        4,
        reason: 'Should have exactly 4 recurrence patterns',
      );
      expect(RecurrencePattern.values[0], RecurrencePattern.daily);
      expect(RecurrencePattern.values[1], RecurrencePattern.weekdays);
      expect(RecurrencePattern.values[2], RecurrencePattern.weekends);
      expect(RecurrencePattern.values[3], RecurrencePattern.custom);
    });

    test('enum indexes are consistent for serialization', () {
      expect(RecurrencePattern.daily.index, 0);
      expect(RecurrencePattern.weekdays.index, 1);
      expect(RecurrencePattern.weekends.index, 2);
      expect(RecurrencePattern.custom.index, 3);
    });
  });
}
