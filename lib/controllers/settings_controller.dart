import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/app_constants.dart';
import '../models/location_exceptions.dart';
import '../services/location_service.dart';
import '../services/settings_service.dart';
import '../services/weather_service.dart';
import '../utils/snackbar_helper.dart';
import 'app_controller.dart';

class SettingsController extends GetxController {
  final SettingsService _settingsService = Get.find<SettingsService>();
  WeatherService? _weatherService;
  LocationService? _locationService;

  // Reactive variables for UI state
  final _selectedTime = Rxn<TimeOfDay>();
  final _location = ''.obs;
  final _isLoading = false.obs;

  // Location detection state management
  final _isDetectingLocation = false.obs;
  final _detectedLocationSuggestion = Rxn<String>();
  final _locationDetectionError = Rxn<String>();

  // Getters for UI binding
  TimeOfDay? get selectedTime => _selectedTime.value;
  String get location => _location.value;
  bool get isLoading => _isLoading.value;

  // Location detection getters
  bool get isDetectingLocation => _isDetectingLocation.value;
  String? get detectedLocationSuggestion => _detectedLocationSuggestion.value;
  String? get locationDetectionError => _locationDetectionError.value;
  bool get hasLocationSuggestion => _detectedLocationSuggestion.value != null;

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

    // Try to get LocationService if available (optional for testing)
    try {
      _locationService = Get.find<LocationService>();
    } catch (e) {
      // LocationService not available - this is fine for testing
      _locationService = null;
    }

    _loadSettings();
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

      // Check if all settings are now complete
      _checkAndNavigateIfComplete();
    } catch (e) {
      // Show error message
      SnackBarHelper.showError('Error ❌', 'Failed to update announcement time');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update the location with optional validation
  Future<void> updateLocation(String newLocation) async {
    // Allow clearing the location
    if (newLocation.trim().isEmpty) {
      _isLoading.value = true;
      try {
        await _settingsService.setLocation('');
        _location.value = '';
      } catch (e) {
        SnackBarHelper.showError('Error ❌', 'Failed to clear location');
      } finally {
        _isLoading.value = false;
      }
      return;
    }

    _isLoading.value = true;
    try {
      // Validate location with weather API if available
      if (hasWeatherValidation) {
        final isValid = await _weatherService!.validateLocation(newLocation.trim());

        if (!isValid) {
          SnackBarHelper.showError(
            'Invalid Location ❌',
            'Location "$newLocation" not found. Please check spelling or try a different format (e.g., "City, Country")',
          );
          return;
        }
      }

      // Save location (validated or not, depending on service availability)
      await _settingsService.setLocation(newLocation.trim());
      _location.value = newLocation.trim();

      // Check if all settings are now complete
      _checkAndNavigateIfComplete();
    } catch (e) {
      // Show error message for network/API issues
      SnackBarHelper.showError('Validation Error ❌', 'Unable to validate location. Please check your internet connection and try again.');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Check if settings are complete and navigate back to main screen
  void _checkAndNavigateIfComplete() {
    if (isSettingsComplete) {
      // Use a post-frame callback to ensure the build cycle is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.find<AppController>().checkSettingsStatus();

        if (Get.isSnackbarOpen) {
          // wait until snackbar is closed. This is a bit hacky but works for now
          final delay = AppConstants.snackbarDuration + 1; // add 1 second buffer
          Future.delayed(Duration(seconds: delay), () {
            // Return to previous route and signal completion
            Get.back(result: true);
          });
        } else {
          // Return to previous route and signal completion
          Get.back(result: true);
        }
      });
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
    } catch (e) {
      SnackBarHelper.showError('Error ❌', 'Failed to reset settings');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Check if weather validation is available
  bool get hasWeatherValidation => _weatherService != null;

  /// Check if location detection is available
  bool get hasLocationDetection => _locationService != null;

  /// Detect current GPS location and provide suggestion
  Future<void> detectCurrentLocation() async {
    if (_locationService == null) {
      _locationDetectionError.value = 'Location detection not available';
      return;
    }

    // Clear any previous state
    _detectedLocationSuggestion.value = null;
    _locationDetectionError.value = null;
    _isDetectingLocation.value = true;

    try {
      final suggestion = await _locationService!.getCurrentLocationSuggestion();
      _detectedLocationSuggestion.value = suggestion;
    } catch (e) {
      String errorMessage;
      if (e is LocationServicesDisabledException) {
        errorMessage = 'Please enable location services in your device settings';
      } else if (e is LocationPermissionDeniedException) {
        errorMessage = 'Location permission denied. Please allow location access in app settings';
      } else if (e is LocationPermissionPermanentlyDeniedException) {
        errorMessage = 'Location permission permanently denied. Please enable in device settings';
      } else if (e is LocationUnknownException) {
        errorMessage = 'Could not determine location name from GPS coordinates';
      } else {
        errorMessage = 'Failed to detect location. Please try again or enter manually';
      }

      _locationDetectionError.value = errorMessage;
      SnackBarHelper.showError('Location Detection Failed ❌', errorMessage);
    } finally {
      _isDetectingLocation.value = false;
    }
  }

  /// Accept the detected location suggestion
  Future<void> acceptLocationSuggestion() async {
    final suggestion = _detectedLocationSuggestion.value;
    if (suggestion != null) {
      await updateLocation(suggestion);
      // Clear the suggestion after accepting
      _detectedLocationSuggestion.value = null;
      _locationDetectionError.value = null;
    }
  }

  /// Decline the detected location suggestion and clear it
  void declineLocationSuggestion() {
    _detectedLocationSuggestion.value = null;
    _locationDetectionError.value = null;
    SnackBarHelper.showInfo('Suggestion Declined 👎', 'You can enter your location manually');
  }

  /// Clear any location detection state
  void clearLocationDetectionState() {
    _detectedLocationSuggestion.value = null;
    _locationDetectionError.value = null;
    _isDetectingLocation.value = false;
  }
}
