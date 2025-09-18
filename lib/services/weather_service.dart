import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../http_client_wrapper.dart';
import '../models/weather_exceptions.dart';
import '../models/weather_summary.dart';

class WeatherService extends GetxService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  static String get _apiKey {
    // Prefer compile-time define via --dart-define=OPENWEATHER_API_KEY=... so the key
    // is baked into the build for production. Fallback to runtime dotenv for dev.
    const fromDefine = String.fromEnvironment('OPENWEATHER_API_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;

    final fromDotEnv = dotenv.env['OPENWEATHER_API_KEY'];
    if (fromDotEnv != null && fromDotEnv.isNotEmpty) return fromDotEnv;

    throw const WeatherApiException('OpenWeatherMap API key not found. Provide it via --dart-define or .env (OPENWEATHER_API_KEY).', 0);
  }

  final HttpClientWrapper _httpClient;

  WeatherService([HttpClientWrapper? httpClient]) : _httpClient = httpClient ?? HttpClientWrapper();

  /// Fetches weather data for the given position
  Future<WeatherSummary> getWeather(Position position) async {
    final url = Uri.parse('$_baseUrl?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric');

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
        // TODO: Should announce default message that request failed
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

  /// Fetches weather data for the given location name
  Future<WeatherSummary> getWeatherByLocation(String locationName) async {
    final url = Uri.parse('$_baseUrl?q=${Uri.encodeComponent(locationName.trim())}&appid=$_apiKey&units=metric');

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

    final url = Uri.parse('$_baseUrl?q=${Uri.encodeComponent(locationName.trim())}&appid=$_apiKey&units=metric');

    try {
      final response = await _httpClient.get(url);

      if (response.statusCode != 200) {
        Get.snackbar('Error', 'Failed to validate location');
      } else {
        debugPrint('Weather API response: ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      // show snackbar if status is not 200
      Get.snackbar('Error', 'Failed to validate location');
      return false;
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
