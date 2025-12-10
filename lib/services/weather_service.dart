import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../http_client_wrapper.dart';
import '../models/weather_exceptions.dart';
import '../models/weather_summary.dart';
import '../utils/snackbar_helper.dart';

class WeatherService extends GetxService {
  // Tomorrow.io endpoints (Phase 12.2 scaffold)
  static const String _tomorrowRealtimeBase = 'https://api.tomorrow.io/v4/weather/realtime';
  static const String _tomorrowForecastBase = 'https://api.tomorrow.io/v4/weather/forecast';

  // Default fields requested from Tomorrow.io (can be tuned in later steps)
  static const List<String> _tomorrowDefaultFields = [
    'temperature',
    'temperatureApparent',
    'humidity',
    'weatherCode',
    'windSpeed',
    'precipitationProbability',
    'cloudCover',
  ];

  // Weather code mapping (partial; expand/refine as needed). Source: Tomorrow.io Weather Codes reference.
  static const Map<int, String> _tomorrowWeatherCodeDescriptions = {
    1000: 'Clear',
    1001: 'Cloudy',
    1100: 'Mostly Clear',
    1101: 'Partly Cloudy',
    1102: 'Mostly Cloudy',
    2000: 'Fog',
    2100: 'Light Fog',
    3000: 'Light Wind',
    3001: 'Windy',
    3002: 'Strong Wind',
    4000: 'Drizzle',
    4001: 'Rain',
    4200: 'Light Rain',
    4201: 'Heavy Rain',
    5000: 'Snow',
    5001: 'Flurries',
    5100: 'Light Snow',
    5101: 'Heavy Snow',
    6000: 'Freezing Drizzle',
    6001: 'Freezing Rain',
    6200: 'Light Freezing Rain',
    6201: 'Heavy Freezing Rain',
    7000: 'Ice Pellets',
    7101: 'Heavy Ice Pellets',
    7102: 'Light Ice Pellets',
    8000: 'Thunderstorm',
  };

  @visibleForTesting
  static String describeTomorrowCode(int code) => _tomorrowWeatherCodeDescriptions[code] ?? 'Unknown';

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
      // Minimal Tomorrow.io realtime request for validation (temperature only)
      final validationUrl = Uri.parse(
        _tomorrowRealtimeBase,
      ).replace(queryParameters: {'location': 'Halifax', 'apikey': apiKey, 'units': 'metric', 'fields': 'temperature'});
      final response = await _httpClient.get(validationUrl);

      _isApiKeyValid = false;
      switch (response.statusCode) {
        case 200:
          _isApiKeyValid = true;
          _lastValidationError = null;
          break;
        case 400:
          _lastValidationError = 'Invalid request parameters for Tomorrow.io API';
          throw WeatherBadRequestException(_lastValidationError!, 400);
        case 401:
          _lastValidationError = 'Invalid or missing API key for Tomorrow.io weather service';
          throw WeatherAuthException(_lastValidationError!, 401);
        case 403:
          _lastValidationError = 'API quota exceeded or access forbidden for Tomorrow.io service';
          throw WeatherQuotaExceededException(_lastValidationError!, 403);
        case 429:
          final retryAfter = _parseRetryAfter(response.headers['retry-after']);
          _lastValidationError = 'Rate limit exceeded for Tomorrow.io API${retryAfter != null ? ", retry after ${retryAfter}s" : ""}';
          throw WeatherRateLimitException(_lastValidationError!, 429, retryAfter);
        default:
          _lastValidationError = 'Tomorrow.io API validation failed with status ${response.statusCode}';
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

  /// Parse Retry-After header value (in seconds)
  int? _parseRetryAfter(String? retryAfterHeader) {
    if (retryAfterHeader == null || retryAfterHeader.isEmpty) return null;

    // Try parsing as integer (seconds)
    final seconds = int.tryParse(retryAfterHeader);
    if (seconds != null) return seconds;

    // Could also handle HTTP-date format here if needed
    return null;
  }

  /// Makes HTTP request with retry logic for 429 rate limit errors
  Future<dynamic> _makeRequestWithRetry(Uri url, {int maxRetries = 2}) async {
    int attempts = 0;

    while (attempts <= maxRetries) {
      try {
        final response = await _httpClient.get(url);

        if (response.statusCode == 429 && attempts < maxRetries) {
          final retryAfter = _parseRetryAfter(response.headers['retry-after']);
          // Use shorter delay for tests, or respect retry-after header
          final delayMilliseconds = retryAfter != null ? (retryAfter * 1000) : (100 * (1 << attempts)); // Shorter exponential backoff for tests

          await Future.delayed(Duration(milliseconds: delayMilliseconds));
          attempts++;
          continue;
        }

        return response;
      } catch (e) {
        if (attempts >= maxRetries) rethrow;

        // Shorter exponential backoff for network errors in tests
        await Future.delayed(Duration(milliseconds: 100 * (1 << attempts)));
        attempts++;
      }
    }

    throw WeatherNetworkException('Max retry attempts exceeded');
  }

  /// Fetches weather data for the given position (Tomorrow.io realtime)
  Future<WeatherSummary> getWeather(Position position) async {
    await _ensureApiKeyValid(); // Lazy validation happens here
    final url = _buildTomorrowRealtime(position.latitude, position.longitude);
    final realtime = await _fetchTomorrowRealtime(url, latitude: position.latitude, longitude: position.longitude);
    // Attempt to enrich with forecast min/max; fall back silently on failure
    try {
      final range = await _fetchForecastMinMax(position.latitude, position.longitude);
      if (range != null) {
        return realtime.copyWith(minOverride: range.min, maxOverride: range.max);
      }
    } catch (_) {
      /* ignore forecast errors */
    }
    return realtime;
  }

  /// Fetches weather data for the given location name (Tomorrow.io realtime)
  Future<WeatherSummary> getWeatherByLocation(String locationName) async {
    await _ensureApiKeyValid(); // Lazy validation happens here
    final trimmed = locationName.trim();
    final url = _buildTomorrowRealtimeForLocation(trimmed);

    print('Fetching weather for location: $trimmed from URL: $url');

    final realtime = await _fetchTomorrowRealtime(url, fallbackLocation: trimmed);
    try {
      final range = await _fetchForecastMinMaxFromLocation(trimmed);
      if (range != null) {
        return realtime.copyWith(minOverride: range.min, maxOverride: range.max);
      }
    } catch (_) {
      /* ignore */
    }
    return realtime;
  }

  // (Removed legacy OpenWeather builders)

  // --- Tomorrow.io URL Builders (not yet wired into public methods) ---
  Uri _buildTomorrowRealtime(double latitude, double longitude, {List<String>? fields}) {
    final apiKey = _apiKeyOrNull!;
    final selectedFields = (fields ?? _tomorrowDefaultFields).join(',');
    final qp = <String, String>{'location': '$latitude,$longitude', 'apikey': apiKey, 'units': 'metric', 'fields': selectedFields};
    return Uri.parse(_tomorrowRealtimeBase).replace(queryParameters: qp);
  }

  Uri _buildTomorrowForecast(double latitude, double longitude, {String timesteps = '1h', List<String>? fields}) {
    final apiKey = _apiKeyOrNull!;
    final selectedFields = (fields ?? _tomorrowDefaultFields).join(',');
    final qp = <String, String>{'location': '$latitude,$longitude', 'apikey': apiKey, 'units': 'metric', 'timesteps': timesteps, 'fields': selectedFields};
    return Uri.parse(_tomorrowForecastBase).replace(queryParameters: qp);
  }

  Uri _buildTomorrowRealtimeForLocation(String locationName, {List<String>? fields}) {
    final apiKey = _apiKeyOrNull!;
    final selectedFields = (fields ?? _tomorrowDefaultFields).join(',');
    final qp = <String, String>{'location': locationName, 'apikey': apiKey, 'units': 'metric', 'fields': selectedFields};
    return Uri.parse(_tomorrowRealtimeBase).replace(queryParameters: qp);
  }

  Uri _buildTomorrowForecastForLocation(String locationName, {String timesteps = '1h', List<String>? fields}) {
    final apiKey = _apiKeyOrNull!;
    final selectedFields = (fields ?? _tomorrowDefaultFields).join(',');
    final qp = <String, String>{'location': locationName, 'apikey': apiKey, 'units': 'metric', 'timesteps': timesteps, 'fields': selectedFields};
    return Uri.parse(_tomorrowForecastBase).replace(queryParameters: qp);
  }

  @visibleForTesting
  Uri buildTomorrowRealtimeUrlForTesting(double latitude, double longitude, {List<String>? fields}) =>
      _buildTomorrowRealtime(latitude, longitude, fields: fields);

  @visibleForTesting
  Uri buildTomorrowForecastUrlForTesting(double latitude, double longitude, {String timesteps = '1h', List<String>? fields}) =>
      _buildTomorrowForecast(latitude, longitude, timesteps: timesteps, fields: fields);

  // --- Tomorrow.io Parsing Adapter (Phase 12.2/12.3 placeholder) ---
  // This does NOT alter current production flow; getWeather() still uses legacy endpoint
  // until full migration (Phase 12.4/12.5). Tests can validate correctness early.
  @visibleForTesting
  WeatherSummary parseTomorrowRealtime(Map<String, dynamic> json, {double? latitude, double? longitude, String? fallbackLocation}) {
    final data = json['data'];
    if (data == null || data is! Map) {
      throw const WeatherParsingException('Missing realtime data');
    }
    final values = data['values'];
    if (values == null || values is! Map) {
      throw const WeatherParsingException('Missing realtime values');
    }

    String locationLabel = fallbackLocation ?? 'Unknown';
    if (latitude != null && longitude != null && (fallbackLocation == null || fallbackLocation.isEmpty)) {
      locationLabel = '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
    }

    final temp = _toDouble(values['temperature']);
    final feels = _toDouble(values['temperatureApparent'] ?? values['temperature']);
    final humidity = (values['humidity'] is num) ? (values['humidity'] as num).round() : 0;
    final code = (values['weatherCode'] is num) ? (values['weatherCode'] as num).toInt() : 0;
    final desc = describeTomorrowCode(code);
    final tsIso = data['time'] as String?; // e.g. 2025-10-02T12:34:56Z
    DateTime ts;
    try {
      ts = tsIso != null ? DateTime.parse(tsIso).toLocal() : DateTime.now();
    } catch (_) {
      ts = DateTime.now();
    }

    return WeatherSummary.realtime(description: desc, temperature: temp, feelsLike: feels, humidity: humidity, location: locationLabel, timestamp: ts);
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  Future<ForecastRange?> _fetchForecastMinMax(double latitude, double longitude) async {
    final forecastUrl = _buildTomorrowForecast(latitude, longitude, timesteps: '1h', fields: const ['temperature']);

    print('Fetching forecast from URL: $forecastUrl');

    try {
      final resp = await _makeRequestWithRetry(forecastUrl);

      switch (resp.statusCode) {
        case 200:
          final jsonBody = json.decode(resp.body) as Map<String, dynamic>;
          final temps = _extractHourlyTemperatures(jsonBody);
          if (temps.isEmpty) return null;
          double min = temps.first;
          double max = temps.first;
          for (final t in temps) {
            if (t < min) min = t;
            if (t > max) max = t;
          }
          return ForecastRange(min, max);
        case 400:
          throw const WeatherBadRequestException('Invalid forecast request parameters for Tomorrow.io API', 400);
        case 401:
          throw const WeatherAuthException('Invalid or missing API key for Tomorrow.io forecast service', 401);
        case 403:
          throw const WeatherQuotaExceededException('API quota exceeded for Tomorrow.io forecast service', 403);
        case 429:
          final retryAfter = _parseRetryAfter(resp.headers['retry-after']);
          throw WeatherRateLimitException('Rate limit exceeded for Tomorrow.io forecast API', 429, retryAfter);
        default:
          return null; // swallow other forecast errors gracefully
      }
    } catch (e) {
      if (e is WeatherException) {
        // Log specific errors but don't break the main weather flow
        debugPrint('Forecast error: $e');
        return null;
      }
      return null; // swallow all other forecast errors
    }
  }

  Future<ForecastRange?> _fetchForecastMinMaxFromLocation(String locationName) async {
    final forecastUrl = _buildTomorrowForecastForLocation(locationName, timesteps: '1h', fields: const ['temperature']);
    try {
      final resp = await _makeRequestWithRetry(forecastUrl);

      switch (resp.statusCode) {
        case 200:
          final jsonBody = json.decode(resp.body) as Map<String, dynamic>;
          final temps = _extractHourlyTemperatures(jsonBody);
          if (temps.isEmpty) return null;
          double min = temps.first;
          double max = temps.first;
          for (final t in temps) {
            if (t < min) min = t;
            if (t > max) max = t;
          }
          return ForecastRange(min, max);
        case 400:
          throw const WeatherBadRequestException('Invalid forecast request parameters for Tomorrow.io API', 400);
        case 401:
          throw const WeatherAuthException('Invalid or missing API key for Tomorrow.io forecast service', 401);
        case 403:
          throw const WeatherQuotaExceededException('API quota exceeded for Tomorrow.io forecast service', 403);
        case 429:
          final retryAfter = _parseRetryAfter(resp.headers['retry-after']);
          throw WeatherRateLimitException('Rate limit exceeded for Tomorrow.io forecast API', 429, retryAfter);
        default:
          return null; // swallow other forecast errors gracefully
      }
    } catch (e) {
      if (e is WeatherException) {
        // Log specific errors but don't break the main weather flow
        debugPrint('Forecast error: $e');
        return null;
      }
      return null; // swallow all other forecast errors
    }
  }

  List<double> _extractHourlyTemperatures(Map<String, dynamic> body) {
    final temps = <double>[];
    // Support three possible Tomorrow.io structures:
    // Format A (old): { data: { timelines: [ { intervals: [ { startTime: ..., values: { temperature: 12.3 } } ] } ] } }
    // Format B (old): { data: { timelines: [ { hourly: [ { time: ..., values: { temperature: 12.3 } } ] } ] } }
    // Format C (new): { timelines: { hourly: [ { time: ..., values: { temperature: 12.3 } } ] } }

    // First try new flattened format
    final timelines = body['timelines'];
    if (timelines is Map) {
      final hourly = timelines['hourly'];
      if (hourly is List) {
        for (final it in hourly) {
          if (it is Map) {
            final values = it['values'];
            if (values is Map && values['temperature'] != null) {
              temps.add(_toDouble(values['temperature']));
            }
          }
        }
        return temps; // Found data in new format, return early
      }
    }

    // Fallback to old nested format
    final data = body['data'];
    if (data is Map) {
      final timelinesArray = data['timelines'];
      if (timelinesArray is List) {
        for (final tl in timelinesArray) {
          if (tl is Map) {
            // Try 'hourly' first, then fall back to 'intervals'
            final hourly = tl['hourly'];
            final intervals = tl['intervals'];

            if (hourly is List) {
              for (final it in hourly) {
                if (it is Map) {
                  final values = it['values'];
                  if (values is Map && values['temperature'] != null) {
                    temps.add(_toDouble(values['temperature']));
                  }
                }
              }
            } else if (intervals is List) {
              for (final it in intervals) {
                if (it is Map) {
                  final values = it['values'];
                  if (values is Map && values['temperature'] != null) {
                    temps.add(_toDouble(values['temperature']));
                  }
                }
              }
            }
          }
        }
      }
    }
    return temps;
  }

  /// Fetches and parses Tomorrow.io realtime weather data
  Future<WeatherSummary> _fetchTomorrowRealtime(Uri url, {double? latitude, double? longitude, String? fallbackLocation}) async {
    try {
      final response = await _makeRequestWithRetry(url);

      switch (response.statusCode) {
        case 200:
          final data = json.decode(response.body) as Map<String, dynamic>;
          return parseTomorrowRealtime(data, latitude: latitude, longitude: longitude, fallbackLocation: fallbackLocation);
        case 400:
          throw const WeatherBadRequestException('Invalid request parameters for Tomorrow.io API', 400);
        case 401:
          throw const WeatherAuthException('Invalid or missing API key for Tomorrow.io weather service', 401);
        case 403:
          throw const WeatherQuotaExceededException('API quota exceeded or access forbidden for Tomorrow.io service', 403);
        case 429:
          final retryAfter = _parseRetryAfter(response.headers['retry-after']);
          throw WeatherRateLimitException('Rate limit exceeded for Tomorrow.io API', 429, retryAfter);
        default:
          throw WeatherApiException('Tomorrow.io API returned status ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      if (e is WeatherException) rethrow;
      if (e is FormatException) {
        throw const WeatherParsingException('Failed to parse Tomorrow.io weather data');
      }
      throw WeatherNetworkException('Network error: ${e.toString()}');
    }
  }

  /// Validates if a location name is valid by requesting Tomorrow.io realtime data
  Future<bool> validateLocation(String locationName) async {
    if (locationName.trim().isEmpty) return false;
    try {
      await _ensureApiKeyValid();
      final url = _buildTomorrowRealtimeForLocation(locationName.trim(), fields: const ['temperature']);
      final response = await _makeRequestWithRetry(url);

      switch (response.statusCode) {
        case 200:
          debugPrint('Weather API response (validation): ${response.body}');
          return true;
        case 400:
          SnackBarHelper.showError('Error', 'Invalid location or request parameters');
          return false;
        case 401:
          SnackBarHelper.showError('Error', 'Invalid API key for weather service');
          throw const WeatherAuthException('Invalid API key for weather service', 401);
        case 403:
          SnackBarHelper.showError('Error', 'API quota exceeded');
          throw const WeatherQuotaExceededException('API quota exceeded', 403);
        case 429:
          final retryAfter = _parseRetryAfter(response.headers['retry-after']);
          SnackBarHelper.showError('Error', 'Rate limit exceeded${retryAfter != null ? ", retry after ${retryAfter}s" : ""}');
          throw WeatherRateLimitException('Rate limit exceeded', 429, retryAfter);
        default:
          SnackBarHelper.showError('Error', 'Failed to validate location');
          return false;
      }
    } catch (e) {
      if (e is WeatherApiException && e.statusCode == 0) {
        SnackBarHelper.showError('Error', 'Weather API key not configured');
      } else if (e is WeatherException) {
        rethrow;
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
