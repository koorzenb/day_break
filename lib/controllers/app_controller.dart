import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/notification_service.dart';
import '../services/settings_service.dart';

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

  // Getters for UI binding
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
        await _scheduleBackgroundTasks();
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
      _showSnackBar('Setup Complete ✅', 'Your daily weather announcements are now configured!', Colors.green);
    }
  }

  /// Refresh settings status (call after returning from settings)
  Future<void> refreshSettingsStatus() async {
    checkSettingsStatus();

    // If settings are now complete, schedule background tasks
    if (_hasSettings.value) {
      await _scheduleBackgroundTasks();
    }
  }

  /// Schedule daily background tasks
  Future<void> _scheduleBackgroundTasks() async {
    _currentStatus.value = 'Scheduling daily notifications...';

    await _notificationService.scheduleDailyWeatherNotification();

    _currentStatus.value = 'Daily notifications scheduled';
  }

  /// Schedule a test notification with specified delay
  Future<void> scheduleTestNotification(int delaySeconds) async {
    try {
      if (_isTestNotificationCountdown.value) {
        _showSnackBar('Already Scheduled', 'A test notification is already counting down.', Colors.orange);
        return;
      }

      // Start countdown
      _isTestNotificationCountdown.value = true;
      _testNotificationCountdown.value = delaySeconds;

      // Schedule the test notification
      await _notificationService.scheduleTestNotification(delaySeconds);

      _showSnackBar('Test Scheduled ⏰', 'Test notification scheduled for $delaySeconds seconds with speech!', Colors.blue);

      // Start countdown timer
      _startCountdownTimer();
    } catch (e) {
      Get.log('Error in scheduleTestNotification: $e', isError: true);
      _showSnackBar('Error ❌', 'Failed to schedule test notification: $e', Colors.red);
      _isTestNotificationCountdown.value = false;
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
        _showSnackBar('Test Delivered 🔔', 'Test notification should appear with speech announcement!', Colors.green);

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

  /// Manual trigger for testing - fetch current weather and show notification
  Future<void> triggerWeatherUpdate() async {
    if (!_hasSettings.value) {
      _showSnackBar('Settings Required', 'Please configure your location and time first.', Colors.orange);
      return;
    }

    try {
      _currentStatus.value = 'Fetching weather...';

      // Use the location saved in settings instead of fetching GPS position
      final savedLocation = _settingsService.location;
      if (savedLocation == null || savedLocation.isEmpty) {
        _showSnackBar('Error', 'No location configured in settings.', Colors.red);
        return;
      }

      _currentStatus.value = 'Sending weather notification...';

      // NotificationService will fetch weather using the saved location
      await _notificationService.showWeatherNotificationByLocation(savedLocation);

      _currentStatus.value = 'Weather notification sent';
      _showSnackBar('Success', 'Weather notification sent!', Colors.green);
    } catch (e) {
      _currentStatus.value = 'Failed to fetch weather';
      print(e);
      _showSnackBar('Error', 'Failed to fetch weather: $e', Colors.red);
    }
  }

  /// Show snackbar message
  void _showSnackBar(String title, String message, Color backgroundColor) {
    if (Get.context != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: backgroundColor.withAlpha((0.8 * 255).toInt()),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Clean up resources
  @override
  void onClose() {
    super.onClose();
  }
}
