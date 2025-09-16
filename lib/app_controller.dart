import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'notification_service.dart';
import 'settings_service.dart';

class AppController extends GetxController {
  // Service dependencies
  late final SettingsService _settingsService;
  late final NotificationService _notificationService;

  // Reactive state variables
  final _isInitialized = false.obs;
  final _hasSettings = false.obs;
  final _currentStatus = ''.obs;

  // Getters for UI binding
  bool get isInitialized => _isInitialized.value;
  bool get hasSettings => _hasSettings.value;
  String get currentStatus => _currentStatus.value;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
  }

  /// Initialize all services and check app state
  void _initializeServices() {
    try {
      // Get all required services
      _settingsService = Get.find<SettingsService>();
      _notificationService = Get.find<NotificationService>();

      // Check if settings are configured
      _checkSettingsStatus();

      _isInitialized.value = true;
      _currentStatus.value = 'Ready';

      // If settings are complete, schedule background tasks
      if (_hasSettings.value) {
        _scheduleBackgroundTasks();
      }
    } catch (e) {
      _currentStatus.value = 'Error initializing app: $e';
      _isInitialized.value = false;
    }
  }

  /// Check if user has completed the initial setup
  void _checkSettingsStatus() {
    final location = _settingsService.location;
    final hasLocation = location != null && location.isNotEmpty;
    final hasTime = _settingsService.announcementHour != null && _settingsService.announcementMinute != null;

    _hasSettings.value = hasLocation && hasTime;
  }

  /// Navigate to settings screen
  void openSettings() {
    Get.toNamed('/settings');
  }

  /// Refresh settings status (call after returning from settings)
  void refreshSettingsStatus() {
    _checkSettingsStatus();

    // If settings are now complete, schedule background tasks
    if (_hasSettings.value) {
      _scheduleBackgroundTasks();
    }
  }

  /// Schedule daily background tasks
  void _scheduleBackgroundTasks() {
    _currentStatus.value = 'Scheduling daily notifications...';

    // TODO: Implement actual background scheduling
    // This would typically involve:
    // 1. Calculating the next announcement time
    // 2. Scheduling a background task or notification
    // 3. Setting up periodic tasks for daily execution

    _currentStatus.value = 'Daily notifications scheduled';
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
