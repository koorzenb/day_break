import 'package:day_break/controllers/settings_controller.dart';
import 'package:day_break/models/recurrence_pattern.dart';
import 'package:day_break/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'settings_controller_recurring_test.mocks.dart';

@GenerateMocks([Box])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsController Recurring Functionality', () {
    late SettingsController controller;
    late SettingsService mockSettingsService;
    late MockBox mockBox;

    setUp(() {
      mockBox = MockBox();
      mockSettingsService = SettingsService(mockBox);

      // Set up default mock returns for all settings
      when(mockBox.get('announcementHour')).thenReturn(null);
      when(mockBox.get('announcementMinute')).thenReturn(null);
      when(mockBox.get('location')).thenReturn(null);
      when(mockBox.get('isRecurring')).thenReturn(false);
      when(mockBox.get('isRecurringPaused')).thenReturn(false);
      when(mockBox.get('recurrencePattern')).thenReturn(null);
      when(mockBox.get('recurrenceDays')).thenReturn(null);

      // Register the mock settings service
      Get.reset();
      Get.put<SettingsService>(mockSettingsService);

      controller = SettingsController();
    });

    tearDown(() {
      Get.reset();
    });

    test('loads recurring settings from service on init', () {
      // Arrange
      when(mockBox.get('isRecurring')).thenReturn(true);
      when(mockBox.get('isRecurringPaused')).thenReturn(false);
      when(mockBox.get('recurrencePattern')).thenReturn(RecurrencePattern.weekdays.index);
      when(mockBox.get('recurrenceDays')).thenReturn([1, 2, 3, 4, 5]);
      when(mockBox.get('announcementHour')).thenReturn(null);
      when(mockBox.get('announcementMinute')).thenReturn(null);
      when(mockBox.get('location')).thenReturn(null);

      // Act
      controller.onInit();

      // Assert
      expect(controller.isRecurring, true, reason: 'Should load recurring flag from settings service');
      expect(controller.recurrencePattern, RecurrencePattern.weekdays, reason: 'Should load recurrence pattern from settings service');
      expect(controller.recurrenceDays, [1, 2, 3, 4, 5], reason: 'Should load recurrence days from settings service');
    });

    test('toggleRecurring updates settings service and reactive state', () async {
      // Arrange
      when(mockBox.put('isRecurring', true)).thenAnswer((_) async => Future.value());
      when(mockBox.get('recurrencePattern')).thenReturn(RecurrencePattern.daily.index);
      when(mockBox.get('recurrenceDays')).thenReturn([1, 2, 3, 4, 5, 6, 7]);

      // Act
      await controller.toggleRecurring(true);

      // Assert
      verify(mockBox.put('isRecurring', true));
      expect(controller.isRecurring, true, reason: 'Reactive state should update after toggle');
    });

    test('updateRecurrencePattern updates pattern and days for non-custom patterns', () async {
      // Arrange
      const pattern = RecurrencePattern.weekends;
      when(mockBox.put('recurrencePattern', pattern.index)).thenAnswer((_) async => Future.value());
      when(mockBox.put('recurrenceDays', pattern.defaultDays)).thenAnswer((_) async => Future.value());

      // Act
      await controller.updateRecurrencePattern(pattern);

      // Assert
      verify(mockBox.put('recurrencePattern', pattern.index));
      verify(mockBox.put('recurrenceDays', pattern.defaultDays));
      expect(controller.recurrencePattern, pattern, reason: 'Pattern should be updated');
      expect(controller.recurrenceDays, [6, 7], reason: 'Days should be updated to pattern defaults for weekends');
    });

    test('updateRecurrencePattern does not auto-update days for custom pattern', () async {
      // Arrange
      const pattern = RecurrencePattern.custom;
      when(mockBox.put('recurrencePattern', pattern.index)).thenAnswer((_) async => Future.value());

      // Act
      await controller.updateRecurrencePattern(pattern);

      // Assert
      verify(mockBox.put('recurrencePattern', pattern.index));
      verifyNever(mockBox.put('recurrenceDays', any));
      expect(controller.recurrencePattern, pattern, reason: 'Pattern should be updated to custom');
    });

    test('toggleRecurrenceDay adds day when not present', () async {
      // Arrange - start with weekdays
      when(mockBox.get('recurrenceDays')).thenReturn([1, 2, 3, 4, 5]);
      controller.onInit();
      when(mockBox.put('recurrenceDays', [1, 2, 3, 4, 5, 6])).thenAnswer((_) async => Future.value());

      // Act - add Saturday (6)
      await controller.toggleRecurrenceDay(6);

      // Assert
      verify(mockBox.put('recurrenceDays', [1, 2, 3, 4, 5, 6]));
      expect(controller.recurrenceDays, contains(6), reason: 'Should add Saturday to the list');
    });

    test('toggleRecurrenceDay removes day when present', () async {
      // Arrange - start with all days
      when(mockBox.get('recurrenceDays')).thenReturn([1, 2, 3, 4, 5, 6, 7]);
      controller.onInit();
      when(mockBox.put('recurrenceDays', [1, 2, 3, 4, 5, 7])).thenAnswer((_) async => Future.value());

      // Act - remove Saturday (6)
      await controller.toggleRecurrenceDay(6);

      // Assert
      verify(mockBox.put('recurrenceDays', [1, 2, 3, 4, 5, 7]));
      expect(controller.recurrenceDays, isNot(contains(6)), reason: 'Should remove Saturday from the list');
    });

    test('getDayName returns correct short day names', () {
      expect(controller.getDayName(1), 'Mon', reason: '1 should map to Mon');
      expect(controller.getDayName(2), 'Tue', reason: '2 should map to Tue');
      expect(controller.getDayName(3), 'Wed', reason: '3 should map to Wed');
      expect(controller.getDayName(4), 'Thu', reason: '4 should map to Thu');
      expect(controller.getDayName(5), 'Fri', reason: '5 should map to Fri');
      expect(controller.getDayName(6), 'Sat', reason: '6 should map to Sat');
      expect(controller.getDayName(7), 'Sun', reason: '7 should map to Sun');
    });

    test('getFullDayName returns correct full day names', () {
      expect(controller.getFullDayName(1), 'Monday', reason: '1 should map to Monday');
      expect(controller.getFullDayName(2), 'Tuesday', reason: '2 should map to Tuesday');
      expect(controller.getFullDayName(3), 'Wednesday', reason: '3 should map to Wednesday');
      expect(controller.getFullDayName(4), 'Thursday', reason: '4 should map to Thursday');
      expect(controller.getFullDayName(5), 'Friday', reason: '5 should map to Friday');
      expect(controller.getFullDayName(6), 'Saturday', reason: '6 should map to Saturday');
      expect(controller.getFullDayName(7), 'Sunday', reason: '7 should map to Sunday');
    });
  });
}
