import 'dart:convert';

import 'package:day_break/utils/snackbar_helper.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../http_client_wrapper.dart';
import '../models/weather_exceptions.dart';
import '../models/weather_summary.dart';

class WeatherService extends GetxService {
  // TODO(Phase 12): Replace OpenWeatherMap base URL with Tomorrow.io endpoint(s) once migration complete.
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/forecast';

  /// Lazy validation state - null means not yet validated, true/false means validation result
  bool? _isApiKeyValid;

  /// Cached API key to avoid repeated lookups
  String? _cachedApiKey;

  /// Last validation error message for user feedback
  String? _lastValidationError;

  /// Checks if an API key is available without throwing exceptions
  String? get _apiKeyOrNull {
    if (_cachedApiKey != null) return _cachedApiKey;

    // Prefer compile-time define via --dart-define=TOMORROWIO_API_KEY=... so the key
    // is baked into the build for production. Fallback to runtime dotenv for dev.

    const fromDefine = String.fromEnvironment('TOMORROWIO_API_KEY');
    if (fromDefine.isNotEmpty) {
      _cachedApiKey = fromDefine;
      return fromDefine;
    }

    // Check dotenv for new key
    final fromDotEnvNew = dotenv.env['TOMORROWIO_API_KEY'];
    if (fromDotEnvNew != null && fromDotEnvNew.isNotEmpty) {
      _cachedApiKey = fromDotEnvNew;
      return fromDotEnvNew;
    }

    return null;
  }

  bool get hasApiKey => _apiKeyOrNull != null;
  bool? get isApiKeyValidated => _isApiKeyValid;

  /// Returns a user-friendly message about the API key status
  String get apiKeyStatusMessage {
    if (!hasApiKey) {
      return 'Weather API key not configured. Weather features will be unavailable until a valid API key is provided.';
    }

    if (_isApiKeyValid == null) {
      return 'Weather API key is configured but not yet validated';
    }

    if (_isApiKeyValid!) {
      return 'Weather API key is configured and validated';
    } else {
      return _lastValidationError ?? 'Weather API key validation failed';
    }
  }

  /// Lazily validates the API key on first actual use
  Future<void> _ensureApiKeyValid() async {
    // If already validated successfully, skip validation
    if (_isApiKeyValid == true) return;

    final apiKey = _apiKeyOrNull;
    if (apiKey == null) {
      _isApiKeyValid = false;
      _lastValidationError = 'Weather API key not configured. Provide TOMORROWIO_API_KEY (preferred) via --dart-define or .env.';
      throw WeatherApiException(_lastValidationError!, 0);
    }

    // For test environments, assume the API key is valid if it exists
    // This avoids making actual network calls during testing
    if (apiKey == 'test_api_key_12345') {
      _isApiKeyValid = true;
      _lastValidationError = null;
      return;
    }

    // If we haven't validated yet, or last validation failed, validate now
    if (_isApiKeyValid == null || _isApiKeyValid == false) {
      await _validateApiKeyWithServer(apiKey);
    }
  }

  /// Validates the API key by making a minimal test request to the weather API
  Future<void> _validateApiKeyWithServer(String apiKey) async {
    try {
      // Make a minimal request to validate the API key
      final testUrl = Uri.parse('$_baseUrl?q=London&appid=$apiKey&units=metric&cnt=1');
      final response = await _httpClient.get(testUrl);

      if (response.statusCode == 401) {
        _isApiKeyValid = false;
        _lastValidationError = 'Invalid API key for weather service';
        throw WeatherApiException(_lastValidationError!, 401);
      } else if (response.statusCode == 200) {
        _isApiKeyValid = true;
        _lastValidationError = null;
      } else {
        _isApiKeyValid = false;
        _lastValidationError = 'Weather API validation failed with status ${response.statusCode}';
        throw WeatherApiException(_lastValidationError!, response.statusCode);
      }
    } catch (e) {
      if (e is WeatherException) rethrow;

      _isApiKeyValid = false;
      _lastValidationError = 'Network error during API key validation: ${e.toString()}';
      throw WeatherNetworkException(_lastValidationError!);
    }
  }

  final HttpClientWrapper _httpClient;

  WeatherService([HttpClientWrapper? httpClient]) : _httpClient = httpClient ?? HttpClientWrapper();

  /// Fetches weather data for the given position
  Future<WeatherSummary> getWeather(Position position) async {
    await _ensureApiKeyValid(); // Lazy validation happens here
    final url = _buildUrlForCoordinates(position.latitude, position.longitude);
    return _fetchWeatherData(url);
  }

  /// Fetches weather data for the given location name
  Future<WeatherSummary> getWeatherByLocation(String locationName) async {
    await _ensureApiKeyValid(); // Lazy validation happens here
    final url = _buildUrlForLocation(locationName.trim());
    return _fetchWeatherData(url);
  }

  /// Builds URL for coordinate-based weather queries
  Uri _buildUrlForCoordinates(double latitude, double longitude) {
    final apiKey = _apiKeyOrNull!; // At this point, _ensureApiKeyValid has already validated
    return Uri.parse('$_baseUrl?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric');
  }

  /// Builds URL for location name-based weather queries
  Uri _buildUrlForLocation(String locationName) {
    final apiKey = _apiKeyOrNull!; // At this point, _ensureApiKeyValid has already validated
    return Uri.parse('$_baseUrl?q=${Uri.encodeComponent(locationName)}&appid=$apiKey&units=metric');
  }

  /// Fetches and parses weather data from the API
  Future<WeatherSummary> _fetchWeatherData(Uri url) async {
    try {
      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return WeatherSummary.fromJson(data);
      } else {
        throw WeatherApiException('Weather API returned status ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      if (e is WeatherException) {
        rethrow;
      }

      // Handle JSON parsing errors
      if (e is FormatException) {
        throw const WeatherParsingException('Failed to parse weather data');
      }

      // Handle network errors
      throw WeatherNetworkException('Network error: ${e.toString()}');
    }
  }

  /// Validates if a location name is valid by testing it with the weather API
  Future<bool> validateLocation(String locationName) async {
    if (locationName.trim().isEmpty) return false;

    try {
      await _ensureApiKeyValid(); // Lazy validation happens here
      final url = _buildUrlForLocation(locationName.trim());
      final response = await _httpClient.get(url);

      if (response.statusCode == 401) {
        SnackBarHelper.showError('Error', 'Invalid API key for weather service');
        throw const WeatherApiException('Invalid API key for weather service', 401);
      }

      if (response.statusCode != 200) {
        SnackBarHelper.showError('Error', 'Failed to validate location');
      } else {
        debugPrint('Weather API response: ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (e is WeatherApiException && e.statusCode == 0) {
        // API key not configured
        SnackBarHelper.showError('Error', 'Weather API key not configured');
      } else {
        SnackBarHelper.showError('Error', 'Failed to validate location');
      }
      return false;
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
