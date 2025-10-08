import 'package:day_break/models/recurrence_pattern.dart';
import 'package:day_break/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'settings_service_test.mocks.dart';

@GenerateMocks([Box])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsService', () {
    late SettingsService settingsService;
    late MockBox mockBox;

    setUp(() {
      mockBox = MockBox();
      settingsService = SettingsService(mockBox);
    });

    test('setLocation saves location to the box', () async {
      const location = 'New York';
      when(mockBox.put('location', location)).thenAnswer((_) async => Future.value());
      await settingsService.setLocation(location);
      verify(mockBox.put('location', location));

      when(mockBox.get('location')).thenReturn(location);
      expect(settingsService.location, location);
    });

    test('location getter retrieves location from the box', () {});

    test('setAnnouncementHour saves hour to the box', () async {
      const hour = 7;
      when(mockBox.put('announcementHour', hour)).thenAnswer((_) async => Future.value());
      await settingsService.setAnnouncementHour(hour);
      verify(mockBox.put('announcementHour', hour));

      when(mockBox.get('announcementHour')).thenReturn(hour);
      expect(settingsService.announcementHour, hour);
    });

    test('setAnnouncementMinute saves minute to the box', () async {
      const minute = 30;
      when(mockBox.put('announcementMinute', minute)).thenAnswer((_) async => Future.value());
      await settingsService.setAnnouncementMinute(minute);
      verify(mockBox.put('announcementMinute', minute));

      when(mockBox.get('announcementMinute')).thenReturn(minute);
      expect(settingsService.announcementMinute, minute);
    });

    group('Recurring Settings', () {
      test('isRecurring defaults to false when not set', () {
        when(mockBox.get('isRecurring')).thenReturn(null);
        expect(settingsService.isRecurring, false, reason: 'isRecurring should default to false when not set');
      });

      test('setIsRecurring saves recurring flag to the box', () async {
        const isRecurring = true;
        when(mockBox.put('isRecurring', isRecurring)).thenAnswer((_) async => Future.value());
        await settingsService.setIsRecurring(isRecurring);
        verify(mockBox.put('isRecurring', isRecurring));

        when(mockBox.get('isRecurring')).thenReturn(isRecurring);
        expect(settingsService.isRecurring, isRecurring, reason: 'isRecurring should return the saved value');
      });

      test('recurrencePattern defaults to daily when not set', () {
        when(mockBox.get('recurrencePattern')).thenReturn(null);
        expect(settingsService.recurrencePattern, RecurrencePattern.daily, reason: 'recurrencePattern should default to daily when not set');
      });

      test('setRecurrencePattern saves pattern index to the box', () async {
        const pattern = RecurrencePattern.weekdays;
        when(mockBox.put('recurrencePattern', pattern.index)).thenAnswer((_) async => Future.value());
        await settingsService.setRecurrencePattern(pattern);
        verify(mockBox.put('recurrencePattern', pattern.index));

        when(mockBox.get('recurrencePattern')).thenReturn(pattern.index);
        expect(settingsService.recurrencePattern, pattern, reason: 'recurrencePattern should return the saved pattern');
      });

      test('recurrencePattern handles invalid index gracefully', () {
        when(mockBox.get('recurrencePattern')).thenReturn(999); // Invalid index
        expect(settingsService.recurrencePattern, RecurrencePattern.daily, reason: 'Invalid pattern index should fallback to daily');
      });

      test('recurrenceDays returns pattern defaults when not set', () {
        when(mockBox.get('recurrenceDays')).thenReturn(null);
        when(mockBox.get('recurrencePattern')).thenReturn(RecurrencePattern.weekdays.index);

        expect(settingsService.recurrenceDays, [1, 2, 3, 4, 5], reason: 'recurrenceDays should return weekdays default when not set');
      });

      test('setRecurrenceDays saves custom days to the box', () async {
        const customDays = [1, 3, 5]; // Monday, Wednesday, Friday
        when(mockBox.put('recurrenceDays', customDays)).thenAnswer((_) async => Future.value());
        await settingsService.setRecurrenceDays(customDays);
        verify(mockBox.put('recurrenceDays', customDays));

        when(mockBox.get('recurrenceDays')).thenReturn(customDays);
        expect(settingsService.recurrenceDays, customDays, reason: 'recurrenceDays should return the saved custom days');
      });

      test('setRecurringConfig sets all recurring settings at once', () async {
        const isRecurring = true;
        const pattern = RecurrencePattern.custom;
        const customDays = [2, 4, 6]; // Tuesday, Thursday, Saturday

        when(mockBox.put('isRecurring', isRecurring)).thenAnswer((_) async => Future.value());
        when(mockBox.put('recurrencePattern', pattern.index)).thenAnswer((_) async => Future.value());
        when(mockBox.put('recurrenceDays', customDays)).thenAnswer((_) async => Future.value());

        await settingsService.setRecurringConfig(isRecurring: isRecurring, pattern: pattern, customDays: customDays);

        verify(mockBox.put('isRecurring', isRecurring));
        verify(mockBox.put('recurrencePattern', pattern.index));
        verify(mockBox.put('recurrenceDays', customDays));
      });

      test('setRecurringConfig uses pattern defaults when no custom days provided', () async {
        const isRecurring = true;
        const pattern = RecurrencePattern.weekends;

        when(mockBox.put('isRecurring', isRecurring)).thenAnswer((_) async => Future.value());
        when(mockBox.put('recurrencePattern', pattern.index)).thenAnswer((_) async => Future.value());
        when(mockBox.put('recurrenceDays', pattern.defaultDays)).thenAnswer((_) async => Future.value());

        await settingsService.setRecurringConfig(isRecurring: isRecurring, pattern: pattern);

        verify(mockBox.put('isRecurring', isRecurring));
        verify(mockBox.put('recurrencePattern', pattern.index));
        verify(mockBox.put('recurrenceDays', pattern.defaultDays)); // Should use [6, 7] for weekends
      });
    });
  });
}
