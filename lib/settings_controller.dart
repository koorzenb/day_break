import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'settings_service.dart';
import 'weather_service.dart';

class SettingsController extends GetxController {
  final SettingsService _settingsService = Get.find<SettingsService>();
  WeatherService? _weatherService;

  // Reactive variables for UI state
  final _selectedTime = Rxn<TimeOfDay>();
  final _location = ''.obs;
  final _isLoading = false.obs;

  // Getters for UI binding
  TimeOfDay? get selectedTime => _selectedTime.value;
  String get location => _location.value;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();

    // Try to get WeatherService if available (optional for testing)
    try {
      _weatherService = Get.find<WeatherService>();
    } catch (e) {
      // WeatherService not available - this is fine for testing
      _weatherService = null;
    }

    _loadSettings();
  }

  void _showSnackBar(String title, String message, Color backgroundColor) {
    if (Get.context != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: backgroundColor.withAlpha((0.8 * 255).toInt()),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Show success snackbar with green background
  void _showSuccessSnackbar(String title, String message) {
    _showSnackBar(title, message, Colors.green);
  }

  /// Show error snackbar with red background
  void _showErrorSnackbar(String title, String message) {
    _showSnackBar(title, message, Colors.red);
  }

  /// Show warning snackbar with orange background
  void _showWarningSnackbar(String title, String message) {
    _showSnackBar(title, message, Colors.orange);
  }

  /// Show info snackbar with blue background
  void _showInfoSnackbar(String title, String message) {
    _showSnackBar(title, message, Colors.blue);
  }

  /// Load existing settings from storage
  void _loadSettings() {
    // Load announcement time
    final hour = _settingsService.announcementHour;
    final minute = _settingsService.announcementMinute;
    if (hour != null && minute != null) {
      _selectedTime.value = TimeOfDay(hour: hour, minute: minute);
    }

    // Load location
    final savedLocation = _settingsService.location;
    if (savedLocation != null) {
      _location.value = savedLocation;
    }
  }

  /// Update the selected announcement time
  Future<void> updateAnnouncementTime(TimeOfDay time) async {
    _isLoading.value = true;
    try {
      await _settingsService.setAnnouncementTime(time.hour, time.minute);
      _selectedTime.value = time;

      // Show success message
      _showSuccessSnackbar('Time Updated ⏰', 'Announcement time set to ${time.format(Get.context!)}');
    } catch (e) {
      // Show error message
      _showErrorSnackbar('Error ❌', 'Failed to update announcement time');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update the location with optional validation
  Future<void> updateLocation(String newLocation) async {
    if (newLocation.trim().isEmpty) {
      _showWarningSnackbar('Invalid Input ⚠️', 'Please enter a valid location');
      return;
    }

    _isLoading.value = true;
    try {
      // Validate location with weather API if available
      if (hasWeatherValidation) {
        final isValid = await _weatherService!.validateLocation(newLocation.trim());

        if (!isValid) {
          _showErrorSnackbar(
            'Invalid Location ❌',
            'Location "$newLocation" not found. Please check spelling or try a different format (e.g., "City, Country")',
          );
          return;
        }
      }

      // Save location (validated or not, depending on service availability)
      await _settingsService.setLocation(newLocation.trim());
      _location.value = newLocation.trim();

      // Show success message with appropriate context
      if (hasWeatherValidation) {
        _showSuccessSnackbar('Location Updated 📍', 'Location set to $newLocation');
      } else {
        _showSuccessSnackbar('Location Saved 📍', 'Location set to $newLocation (validation unavailable)');
      }
    } catch (e) {
      // Show error message for network/API issues
      _showErrorSnackbar('Validation Error ❌', 'Unable to validate location. Please check your internet connection and try again.');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Show time picker dialog
  Future<void> showTimePicker() async {
    final TimeOfDay? picked = await Get.dialog<TimeOfDay>(TimePickerDialog(initialTime: _selectedTime.value ?? const TimeOfDay(hour: 8, minute: 0)));

    if (picked != null) {
      await updateAnnouncementTime(picked);
    }
  }

  /// Check if settings are complete
  bool get isSettingsComplete {
    return _selectedTime.value != null && _location.value.isNotEmpty;
  }

  /// Get formatted time string for display
  String get formattedTime {
    if (_selectedTime.value == null) return 'Not set';
    final context = Get.context;
    if (context == null) return '${_selectedTime.value!.hour}:${_selectedTime.value!.minute.toString().padLeft(2, '0')}';
    return _selectedTime.value!.format(context);
  }

  /// Reset all settings (for testing or fresh start)
  Future<void> resetSettings() async {
    _isLoading.value = true;
    try {
      await _settingsService.clearSettings();
      _selectedTime.value = null;
      _location.value = '';

      _showInfoSnackbar('Settings Reset 🔄', 'All settings have been cleared');
    } catch (e) {
      _showErrorSnackbar('Error ❌', 'Failed to reset settings');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Check if weather validation is available
  bool get hasWeatherValidation => _weatherService != null;
}
