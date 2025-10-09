import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/recurrence_pattern.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../utils/snackbar_helper.dart';

class AppController extends GetxController {
  // Service dependencies
  late final SettingsService _settingsService;
  late final NotificationService _notificationService;

  // Reactive state variables
  final _isInitialized = false.obs;
  final _hasSettings = false.obs;
  final _currentStatus = ''.obs;
  final _isTestNotificationCountdown = false.obs;
  final _testNotificationCountdown = 0.obs;

  bool get isInitialized => _isInitialized.value;
  bool get hasSettings => _hasSettings.value;
  String get currentStatus => _currentStatus.value;
  bool get isTestNotificationCountdown => _isTestNotificationCountdown.value;
  int get testNotificationCountdown => _testNotificationCountdown.value;
  bool get isNotificationsAllowed => _notificationService.isNotificationsAllowed;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
  }

  /// Clean up resources
  @override
  void onClose() {
    super.onClose();
  }

  /// Check if user has completed the initial setup
  void checkSettingsStatus() {
    final location = _settingsService.location;
    final hasLocation = location != null && location.isNotEmpty;
    final hasTime = _settingsService.announcementHour != null && _settingsService.announcementMinute != null;

    _hasSettings.value = hasLocation && hasTime;
  }

  /// Navigate to settings screen
  Future<void> openSettings() async {
    final result = await Get.toNamed('/settings');

    // If settings were completed, refresh the status and show snackbar
    if (result == true) {
      await refreshSettingsStatus();
      SnackBarHelper.showSuccess('Setup Complete ✅', 'Your daily weather announcements are now configured!');
    }
  }

  /// Refresh settings status (call after returning from settings)
  Future<void> refreshSettingsStatus() async {
    checkSettingsStatus();

    // If settings are now complete, schedule background tasks
    if (_hasSettings.value) {
      await _scheduleDailyNotification();
    }
  }

  /// Schedule a test notification with specified delay
  Future<void> scheduleTestNotification(int delaySeconds) async {
    try {
      if (_isTestNotificationCountdown.value) {
        SnackBarHelper.showWarning('Already Scheduled', 'A test notification is already counting down.');
        return;
      }

      // Start countdown
      _isTestNotificationCountdown.value = true;
      _testNotificationCountdown.value = delaySeconds;

      // Schedule the test notification
      await _notificationService.scheduleTestNotification(delaySeconds);

      // Start countdown timer
      _startCountdownTimer();
    } catch (e) {
      Get.log('Error in scheduleTestNotification: $e', isError: true);
      SnackBarHelper.showError('Error ❌', 'Failed to schedule test notification: $e');
      _isTestNotificationCountdown.value = false;
    }
  }

  /// Initialize all services and check app state
  Future<void> _initializeServices() async {
    try {
      // Get all required services
      _settingsService = Get.find<SettingsService>();
      _notificationService = Get.find<NotificationService>();

      // Check if settings are configured
      checkSettingsStatus();

      _isInitialized.value = true;
      _currentStatus.value = 'Ready';

      // If settings are complete, schedule background tasks
      if (_hasSettings.value) {
        await _scheduleDailyNotification();
      } else {
        // Navigate to settings if not configured
        WidgetsBinding.instance.addPostFrameCallback((_) {
          openSettings();
        });
      }
    } catch (e) {
      // Ensure the UI is released from the loading state even if initialization fails partially
      _currentStatus.value = 'Limited mode – init error: $e';
      _isInitialized.value = true; // Allow app to render so user can attempt recovery in settings
    }
  }

  /// Schedule daily notifications
  Future<void> _scheduleDailyNotification() async {
    _currentStatus.value = 'Scheduling daily notifications...';
    await _notificationService.scheduleDailyWeatherNotification();
    _currentStatus.value = _generateSchedulingStatusMessage();
  }

  /// Generate status message based on recurring settings and next announcement time
  String _generateSchedulingStatusMessage() {
    final hour = _settingsService.announcementHour;
    final minute = _settingsService.announcementMinute;

    if (hour == null || minute == null) {
      return 'Announcement time not configured';
    }

    final timeString = '${hour.toString()}:${minute.toString().padLeft(2, '0')}';
    final isRecurring = _settingsService.isRecurring;

    if (isRecurring) {
      final pattern = _settingsService.recurrencePattern;
      final nextDate = _calculateNextAnnouncementDate();

      if (nextDate != null) {
        final isToday = nextDate.day == DateTime.now().day && nextDate.month == DateTime.now().month && nextDate.year == DateTime.now().year;

        final dateString = isToday ? 'today' : 'on ${_formatDate(nextDate)}';

        return 'Next recurring announcement: $dateString at $timeString (${pattern.displayName})';
      } else {
        return 'Recurring announcements: ${pattern.displayName} at $timeString (no upcoming dates)';
      }
    } else {
      final nextDate = _calculateNextAnnouncementDate();

      if (nextDate != null) {
        final isToday = nextDate.day == DateTime.now().day && nextDate.month == DateTime.now().month && nextDate.year == DateTime.now().year;

        final dateString = isToday ? 'today' : 'on ${_formatDate(nextDate)}';

        return 'Next announcement: $dateString at $timeString';
      } else {
        return 'Announcement scheduled for $timeString';
      }
    }
  }

  /// Start the countdown timer for test notification
  void _startCountdownTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_testNotificationCountdown.value > 0) {
        _testNotificationCountdown.value--;
      } else {
        timer.cancel();
        _isTestNotificationCountdown.value = false;
        _triggerTestNotificationSpeech();
      }
    });
  }

  /// Trigger TTS for test notification (fallback if notification service timer doesn't work)
  Future<void> _triggerTestNotificationSpeech() async {
    try {
      // Trigger weather TTS announcement for the test
      await _notificationService.speakTestWeatherAnnouncement();
    } catch (e) {
      Get.log('Failed to trigger test notification speech: $e', isError: true);
    }
  }

  /// Calculates the next announcement date based on current settings
  DateTime? _calculateNextAnnouncementDate() {
    final hour = _settingsService.announcementHour;
    final minute = _settingsService.announcementMinute;

    if (hour == null || minute == null) {
      return null;
    }

    final halifaxLocation = tz.getLocation('America/Halifax');
    final now = tz.TZDateTime.now(halifaxLocation);

    // Create today's scheduled time in Halifax timezone
    var candidateDate = tz.TZDateTime(halifaxLocation, now.year, now.month, now.day, hour, minute);

    // If today's time has passed, start checking from tomorrow
    if (candidateDate.isBefore(now)) {
      candidateDate = candidateDate.add(const Duration(days: 1));
    }

    final isRecurring = _settingsService.isRecurring;

    if (!isRecurring) {
      // Single notification - return the candidate date
      return candidateDate;
    }

    // Recurring notification - find next valid day
    final activeDays = _settingsService.recurrenceDays;

    // Find the next valid day (within 14 days to match system limitations)
    for (int i = 0; i < 14; i++) {
      final dayOfWeek = candidateDate.weekday % 7; // Convert to 0-6 (Sunday-Saturday)

      if (activeDays.contains(dayOfWeek)) {
        return candidateDate;
      }

      candidateDate = candidateDate.add(const Duration(days: 1));
    }

    // No valid day found within 14 days
    return null;
  }

  /// Formats a date for display in status messages
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'today';
    } else if (dateOnly == tomorrow) {
      return 'tomorrow';
    } else {
      // Format as "Mon, Dec 16"
      const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

      final weekday = weekdays[date.weekday % 7];
      final month = months[date.month - 1];

      return '$weekday, $month ${date.day}';
    }
  }
}
