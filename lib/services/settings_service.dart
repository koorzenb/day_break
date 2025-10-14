import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/recurrence_pattern.dart';

class SettingsService extends GetxService {
  Box? _settingsBox;

  // Allow a box to be injected for testing
  SettingsService([this._settingsBox]);

  Future<SettingsService> init() async {
    // Don't re-initialize if a box was already injected
    if (_settingsBox == null) {
      await Hive.initFlutter();
      _settingsBox = await Hive.openBox('settings');
    }
    return this;
  }

  String? get location => _settingsBox?.get('location');
  Future<void> setLocation(String location) =>
      _settingsBox!.put('location', location);

  int? get announcementHour => _settingsBox?.get('announcementHour');
  Future<void> setAnnouncementHour(int hour) =>
      _settingsBox!.put('announcementHour', hour);

  int? get announcementMinute => _settingsBox?.get('announcementMinute');
  Future<void> setAnnouncementMinute(int minute) =>
      _settingsBox!.put('announcementMinute', minute);

  Future<void> setAnnouncementTime(int hour, int minute) async {
    await setAnnouncementHour(hour);
    await setAnnouncementMinute(minute);
  }

  // Recurring announcement settings
  bool get isRecurring => _settingsBox?.get('isRecurring') ?? false;
  Future<void> setIsRecurring(bool isRecurring) =>
      _settingsBox!.put('isRecurring', isRecurring);

  /// Pause/resume recurring without losing configuration
  bool get isRecurringPaused => _settingsBox?.get('isRecurringPaused') ?? false;
  Future<void> setIsRecurringPaused(bool isPaused) =>
      _settingsBox!.put('isRecurringPaused', isPaused);

  /// Check if recurring is enabled and not paused
  bool get isRecurringActive => isRecurring && !isRecurringPaused;

  RecurrencePattern get recurrencePattern {
    final patternIndex = _settingsBox?.get('recurrencePattern') as int?;
    if (patternIndex == null ||
        patternIndex >= RecurrencePattern.values.length) {
      return RecurrencePattern.daily; // Default pattern
    }
    return RecurrencePattern.values[patternIndex];
  }

  Future<void> setRecurrencePattern(RecurrencePattern pattern) =>
      _settingsBox!.put('recurrencePattern', pattern.index);

  List<int> get recurrenceDays {
    final days = _settingsBox?.get('recurrenceDays') as List<dynamic>?;
    if (days == null) {
      // Return default days for the current pattern
      return recurrencePattern.defaultDays;
    }
    return days.cast<int>();
  }

  Future<void> setRecurrenceDays(List<int> days) =>
      _settingsBox!.put('recurrenceDays', days);

  /// Set complete recurring configuration at once
  Future<void> setRecurringConfig({
    required bool isRecurring,
    RecurrencePattern pattern = RecurrencePattern.daily,
    List<int>? customDays,
  }) async {
    await setIsRecurring(isRecurring);
    await setRecurrencePattern(pattern);

    // Set custom days if provided, otherwise use pattern defaults
    final daysToSet = customDays ?? pattern.defaultDays;
    await setRecurrenceDays(daysToSet);
  }

  Future<void> clearSettings() async {
    await _settingsBox!.clear();
  }
}
