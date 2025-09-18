import 'dart:convert';

import 'package:day_break/http_client_wrapper.dart';
import 'package:day_break/models/weather_exceptions.dart';
import 'package:day_break/services/weather_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'weather_service_test.mocks.dart';

@GenerateMocks([HttpClientWrapper])
void main() {
  group('WeatherService', () {
    late WeatherService weatherService;
    late MockHttpClientWrapper mockHttpClient;
    late Position testPosition;

    setUpAll(() async {
      // Initialize dotenv for tests
      dotenv.testLoad(fileInput: 'OPENWEATHER_API_KEY=test_api_key_12345');
    });

    setUp(() {
      mockHttpClient = MockHttpClientWrapper();
      weatherService = WeatherService(mockHttpClient);
      testPosition = Position(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    });

    group('getWeather', () {
      test('should return WeatherSummary when API call succeeds', () async {
        // Arrange
        const mockResponse = {
          'weather': [
            {'description': 'clear sky'},
          ],
          'main': {'temp': 22.5, 'feels_like': 24.0, 'temp_min': 18.0, 'temp_max': 25.0, 'humidity': 65},
          'name': 'San Francisco',
        };

        when(mockHttpClient.get(any)).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await weatherService.getWeather(testPosition);

        // Assert
        expect(result.description, equals('clear sky'), reason: 'Weather description should match API response');
        expect(result.temperature, equals(22.5), reason: 'Temperature should match API response');
        expect(result.feelsLike, equals(24.0), reason: 'Feels like temperature should match API response');
        expect(result.tempMin, equals(18.0), reason: 'Temperature minimum should match API response');
        expect(result.tempMax, equals(25.0), reason: 'Temperature maximum should match API response');
        expect(result.humidity, equals(65), reason: 'Humidity should match API response');
        expect(result.location, equals('San Francisco'), reason: 'Location should match API response');
      });

      test('should include lat/lon in API request URL', () async {
        // Arrange
        const mockResponse = {
          'weather': [
            {'description': 'clear sky'},
          ],
          'main': {'temp': 22.5, 'feels_like': 24.0, 'temp_min': 18.0, 'temp_max': 25.0, 'humidity': 65},
          'name': 'Test City',
        };

        when(mockHttpClient.get(any)).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        await weatherService.getWeather(testPosition);

        // Assert
        final captured = verify(mockHttpClient.get(captureAny)).captured;
        final capturedUri = captured.first as Uri;

        expect(capturedUri.queryParameters['lat'], equals('37.7749'), reason: 'Latitude should be included in API request');
        expect(capturedUri.queryParameters['lon'], equals('-122.4194'), reason: 'Longitude should be included in API request');
        expect(capturedUri.queryParameters['units'], equals('metric'), reason: 'Metric units should be specified');
      });

      test('should throw WeatherApiException when API returns error status', () async {
        // Arrange
        when(mockHttpClient.get(any)).thenAnswer((_) async => http.Response('{"message": "city not found"}', 404));

        // Act & Assert
        expect(
          () => weatherService.getWeather(testPosition),
          throwsA(isA<WeatherApiException>().having((e) => e.statusCode, 'status code', equals(404))),
          reason: 'Should throw WeatherApiException for 404 status',
        );
      });

      test('should throw WeatherParsingException when JSON is malformed', () async {
        // Arrange
        when(mockHttpClient.get(any)).thenAnswer((_) async => http.Response('invalid json', 200));

        // Act & Assert
        expect(
          () => weatherService.getWeather(testPosition),
          throwsA(isA<WeatherParsingException>()),
          reason: 'Should throw WeatherParsingException for malformed JSON',
        );
      });

      test('should throw WeatherNetworkException when network error occurs', () async {
        // Arrange
        when(mockHttpClient.get(any)).thenThrow(Exception('Network timeout'));

        // Act & Assert
        expect(
          () => weatherService.getWeather(testPosition),
          throwsA(isA<WeatherNetworkException>()),
          reason: 'Should throw WeatherNetworkException for network errors',
        );
      });

      test('should rethrow WeatherException types without wrapping', () async {
        // Arrange
        const testException = WeatherParsingException('Test parsing error');
        when(mockHttpClient.get(any)).thenThrow(testException);

        // Act & Assert
        expect(() => weatherService.getWeather(testPosition), throwsA(same(testException)), reason: 'Should rethrow WeatherException without wrapping');
      });
    });

    group('environment variable', () {
      test('should throw WeatherApiException when API key is not set in dotenv', () {
        // Arrange - create a new dotenv instance without the API key
        dotenv.testLoad(fileInput: '');
        final testWeatherService = WeatherService(mockHttpClient);

        // Act & Assert
        expect(
          () => testWeatherService.getWeather(testPosition),
          throwsA(isA<WeatherApiException>().having((e) => e.message, 'message', contains('OpenWeatherMap API key not found'))),
          reason: 'Should throw WeatherApiException when API key is missing',
        );

        // Cleanup - restore the API key
        dotenv.testLoad(fileInput: 'OPENWEATHER_API_KEY=test_api_key_12345');
      });
    });

    group('dispose', () {
      test('should call close on http client', () {
        // Act
        weatherService.dispose();

        // Assert
        verify(mockHttpClient.close()).called(1);
      });
    });
  });
}
