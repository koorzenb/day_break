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
      dotenv.testLoad(fileInput: 'TOMORROWIO_API_KEY=test_api_key_12345');
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
          'cod': '200',
          'message': 0,
          'cnt': 2,
          'list': [
            {
              'dt': 1759330800,
              'main': {'temp': 22.5, 'feels_like': 24.0, 'temp_min': 18.0, 'temp_max': 25.0, 'humidity': 65},
              'weather': [
                {'description': 'clear sky'},
              ],
            },
            {
              'dt': 1759341600,
              'main': {'temp': 20.0, 'feels_like': 22.0, 'temp_min': 16.0, 'temp_max': 24.0, 'humidity': 70},
              'weather': [
                {'description': 'few clouds'},
              ],
            },
          ],
          'city': {
            'id': 5391959,
            'name': 'San Francisco',
            'coord': {'lat': 37.7749, 'lon': -122.4194},
            'country': 'US',
          },
        };

        when(mockHttpClient.get(any)).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await weatherService.getWeather(testPosition);

        // Assert
        expect(result.description, equals('clear sky'), reason: 'Weather description should match first forecast');
        expect(result.temperature, equals(22.5), reason: 'Temperature should match first forecast');
        expect(result.feelsLike, equals(24.0), reason: 'Feels like temperature should match first forecast');
        expect(result.tempMin, equals(16.0), reason: 'Temperature minimum should be calculated from daily forecasts');
        expect(result.tempMax, equals(25.0), reason: 'Temperature maximum should be calculated from daily forecasts');
        expect(result.humidity, equals(65), reason: 'Humidity should match first forecast');
        expect(result.location, equals('San Francisco'), reason: 'Location should match city name');
      });

      test('should include lat/lon in API request URL', () async {
        // Arrange
        const mockResponse = {
          'cod': '200',
          'message': 0,
          'cnt': 1,
          'list': [
            {
              'dt': 1759330800,
              'main': {'temp': 22.5, 'feels_like': 24.0, 'temp_min': 18.0, 'temp_max': 25.0, 'humidity': 65},
              'weather': [
                {'description': 'clear sky'},
              ],
            },
          ],
          'city': {
            'id': 12345,
            'name': 'Test City',
            'coord': {'lat': 37.7749, 'lon': -122.4194},
            'country': 'US',
          },
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
      test('should throw WeatherApiException when no supported API key is set', () {
        dotenv.testLoad(fileInput: '');
        final testWeatherService = WeatherService(mockHttpClient);
        expect(
          () => testWeatherService.getWeather(testPosition),
          throwsA(isA<WeatherApiException>().having((e) => e.message, 'message', contains('Weather API key not configured'))),
          reason: 'Should throw WeatherApiException with generic message when key missing',
        );
        dotenv.testLoad(fileInput: 'TOMORROWIO_API_KEY=test_api_key_12345');
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

    group('Lazy API Key Validation', () {
      late WeatherService serviceWithoutKey;
      late MockHttpClientWrapper mockHttpWithoutKey;

      setUp(() {
        mockHttpWithoutKey = MockHttpClientWrapper();
        serviceWithoutKey = WeatherService(mockHttpWithoutKey);
      });

      test('should initialize service without API key without throwing', () {
        // Clear any existing API key
        dotenv.testLoad(fileInput: '');

        // Act & Assert - should not throw
        expect(() => WeatherService(mockHttpWithoutKey), returnsNormally, reason: 'Service should initialize successfully without API key');
      });

      test('hasApiKey should return false when no API key is configured', () {
        // Clear any existing API key
        dotenv.testLoad(fileInput: '');

        // Act & Assert
        expect(serviceWithoutKey.hasApiKey, isFalse, reason: 'hasApiKey should return false when no API key is configured');
      });

      test('hasApiKey should return true when Tomorrow.io API key is configured', () {
        dotenv.testLoad(fileInput: 'TOMORROWIO_API_KEY=test_key_123');
        final serviceWithKey = WeatherService(mockHttpWithoutKey);
        expect(serviceWithKey.hasApiKey, isTrue, reason: 'hasApiKey should return true when new Tomorrow.io API key is configured');
      });

      test('apiKeyStatusMessage should return appropriate message when no API key', () {
        // Clear any existing API key
        dotenv.testLoad(fileInput: '');

        // Act
        final message = serviceWithoutKey.apiKeyStatusMessage;

        // Assert
        expect(message, contains('not configured'), reason: 'Status message should indicate API key is not configured');
        expect(message, contains('unavailable'), reason: 'Status message should mention weather features will be unavailable');
      });

      test('apiKeyStatusMessage should return success message when Tomorrow.io key configured', () {
        dotenv.testLoad(fileInput: 'TOMORROWIO_API_KEY=test_key_123');
        final serviceWithKey = WeatherService(mockHttpWithoutKey);
        final message = serviceWithKey.apiKeyStatusMessage;
        expect(message, contains('configured'), reason: 'Status should indicate configured key');
        expect(message, isNot(contains('unavailable')), reason: 'Configured message should not mention unavailability');
      });

      test('getWeather should throw WeatherApiException when no API key configured', () async {
        // Clear any existing API key
        dotenv.testLoad(fileInput: '');

        // Act & Assert
        await expectLater(
          serviceWithoutKey.getWeather(testPosition),
          throwsA(
            isA<WeatherApiException>().having((e) => e.message, 'message', contains('not configured')).having((e) => e.statusCode, 'statusCode', equals(0)),
          ),
          reason: 'Should throw WeatherApiException when API key is not configured',
        );
      });

      test('getWeatherByLocation should throw WeatherApiException when no API key configured', () async {
        // Clear any existing API key
        dotenv.testLoad(fileInput: '');

        // Act & Assert
        await expectLater(
          serviceWithoutKey.getWeatherByLocation('San Francisco'),
          throwsA(
            isA<WeatherApiException>().having((e) => e.message, 'message', contains('not configured')).having((e) => e.statusCode, 'statusCode', equals(0)),
          ),
          reason: 'Should throw WeatherApiException when API key is not configured',
        );
      });

      test('validateLocation should return false when no API key configured', () async {
        // Initialize binding for this test since it uses SnackBarHelper
        TestWidgetsFlutterBinding.ensureInitialized();

        // Clear any existing API key
        dotenv.testLoad(fileInput: '');

        // Act
        final result = await serviceWithoutKey.validateLocation('San Francisco');

        // Assert
        expect(result, isFalse, reason: 'validateLocation should return false when API key is not configured');
      });

      test('getWeather should work normally when Tomorrow.io API key is configured', () async {
        dotenv.testLoad(fileInput: 'TOMORROWIO_API_KEY=test_key_123');

        // Arrange
        const mockResponse = {
          'cod': '200',
          'message': 0,
          'cnt': 2,
          'list': [
            {
              'dt': 1609459200,
              'main': {'temp': 15.5, 'feels_like': 14.2, 'temp_min': 12.0, 'temp_max': 18.0, 'humidity': 65},
              'weather': [
                {'description': 'clear sky'},
              ],
            },
            {
              'dt': 1609462800,
              'main': {'temp': 16.8, 'feels_like': 15.5, 'temp_min': 14.0, 'temp_max': 19.0, 'humidity': 70},
              'weather': [
                {'description': 'few clouds'},
              ],
            },
          ],
          'city': {
            'id': 5391959,
            'name': 'San Francisco',
            'coord': {'lat': 37.7749, 'lon': -122.4194},
            'country': 'US',
          },
        };

        when(mockHttpWithoutKey.get(any)).thenAnswer((_) async => http.Response(json.encode(mockResponse), 200));

        // Act
        final result = await serviceWithoutKey.getWeather(testPosition);

        // Assert
        expect(result, isNotNull, reason: 'Should return WeatherSummary when API key is configured');
        expect(result.temperature, equals(15.5), reason: 'Should parse temperature correctly');
      });

     

      tearDown(() {
        dotenv.testLoad(fileInput: 'TOMORROWIO_API_KEY=test_api_key_12345');
      });
    });
  });
}
