import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  /// Manual trigger for testing - fetch current weather and show notification
  Future<void> triggerWeatherUpdate() async {
    if (!_hasSettings.value) {
      SnackBarHelper.showWarning('Settings Required', 'Please configure your location and time first.');
      return;
    }

    try {
      _currentStatus.value = 'Fetching weather...';

      // Use the location saved in settings instead of fetching GPS position
      final savedLocation = _settingsService.location;
      if (savedLocation == null || savedLocation.isEmpty) {
        SnackBarHelper.showError('Error', 'No location configured in settings.');
        return;
      }

      _currentStatus.value = 'Sending weather notification...';

      // NotificationService will fetch weather using the saved location
      await _notificationService.showWeatherNotificationByLocation(savedLocation);

      _currentStatus.value = 'Weather notification sent';
    } catch (e) {
      _currentStatus.value = 'Failed to fetch weather';
      print(e);
      SnackBarHelper.showError('Error', 'Failed to fetch weather: $e');
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
    _currentStatus.value = 'Daily notifications scheduled for ${_settingsService.announcementHour}:${_settingsService.announcementMinute?.toString().padLeft(2, '0')}';
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


}
