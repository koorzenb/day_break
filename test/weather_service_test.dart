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
      test(
        'should return WeatherSummary when realtime API call succeeds (Tomorrow.io)',
        () async {
          // Arrange - Tomorrow.io realtime shape
          final mockResponse = {
            'data': {
              'time': DateTime.now().toUtc().toIso8601String(),
              'values': {
                'temperature': 22.5,
                'temperatureApparent': 24.0,
                'humidity': 65,
                'weatherCode': 1000,
              },
            },
          };

          when(mockHttpClient.get(any)).thenAnswer(
            (_) async => http.Response(json.encode(mockResponse), 200),
          );

          // Act
          final result = await weatherService.getWeather(testPosition);

          // Assert
          expect(
            result.description,
            equals('Clear'),
            reason: 'Weather description should map from weatherCode 1000',
          );
          expect(
            result.temperature,
            equals(22.5),
            reason: 'Temperature should match realtime temperature',
          );
          expect(
            result.feelsLike,
            equals(24.0),
            reason: 'Feels like temperature should use temperatureApparent',
          );
          expect(
            result.tempMin,
            equals(22.5),
            reason: 'Temp min equals current until forecast integration added',
          );
          expect(
            result.tempMax,
            equals(22.5),
            reason: 'Temp max equals current until forecast integration added',
          );
          expect(
            result.humidity,
            equals(65),
            reason: 'Humidity should be parsed from realtime values',
          );
          expect(
            result.location,
            equals('37.7749,-122.4194'),
            reason: 'Location should fallback to lat,lon string',
          );
        },
      );

      test(
        'should include location parameter in realtime API request URL',
        () async {
          // Arrange
          final mockResponse = {
            'data': {
              'time': DateTime.now().toUtc().toIso8601String(),
              'values': {
                'temperature': 22.5,
                'temperatureApparent': 24.0,
                'humidity': 65,
                'weatherCode': 1000,
              },
            },
          };

          when(mockHttpClient.get(any)).thenAnswer(
            (_) async => http.Response(json.encode(mockResponse), 200),
          );

          // Act
          await weatherService.getWeather(testPosition);

          // Assert
          final captured = verify(mockHttpClient.get(captureAny)).captured;
          final capturedUri = captured.first as Uri;

          expect(
            capturedUri.queryParameters['location'],
            equals('37.7749,-122.4194'),
            reason: 'Combined lat,lon should be used as location parameter',
          );
          expect(
            capturedUri.queryParameters['units'],
            equals('metric'),
            reason: 'Metric units should be specified',
          );
          expect(
            capturedUri.queryParameters['fields'],
            contains('temperature'),
            reason: 'Temperature field should be requested',
          );
        },
      );

      test(
        'should throw WeatherApiException when API returns error status',
        () async {
          // Arrange
          when(mockHttpClient.get(any)).thenAnswer(
            (_) async => http.Response('{"message": "city not found"}', 404),
          );

          // Act & Assert
          expect(
            () => weatherService.getWeather(testPosition),
            throwsA(
              isA<WeatherApiException>().having(
                (e) => e.statusCode,
                'status code',
                equals(404),
              ),
            ),
            reason: 'Should throw WeatherApiException for 404 status',
          );
        },
      );

      test(
        'should throw WeatherParsingException when JSON is malformed',
        () async {
          // Arrange
          when(
            mockHttpClient.get(any),
          ).thenAnswer((_) async => http.Response('invalid json', 200));

          // Act & Assert
          expect(
            () => weatherService.getWeather(testPosition),
            throwsA(isA<WeatherParsingException>()),
            reason: 'Should throw WeatherParsingException for malformed JSON',
          );
        },
      );

      test(
        'should throw WeatherNetworkException when network error occurs',
        () async {
          // Arrange
          when(mockHttpClient.get(any)).thenThrow(Exception('Network timeout'));

          // Act & Assert
          expect(
            () => weatherService.getWeather(testPosition),
            throwsA(isA<WeatherNetworkException>()),
            reason: 'Should throw WeatherNetworkException for network errors',
          );
        },
      );

      test('should rethrow WeatherException types without wrapping', () async {
        // Arrange
        const testException = WeatherParsingException('Test parsing error');
        when(mockHttpClient.get(any)).thenThrow(testException);

        // Act & Assert
        expect(
          () => weatherService.getWeather(testPosition),
          throwsA(same(testException)),
          reason: 'Should rethrow WeatherException without wrapping',
        );
      });

      test(
        'should throw WeatherBadRequestException for 400 status code',
        () async {
          // Arrange
          when(mockHttpClient.get(any)).thenAnswer(
            (_) async => http.Response('{"message": "Bad request"}', 400),
          );

          // Act & Assert
          expect(
            () => weatherService.getWeather(testPosition),
            throwsA(
              isA<WeatherBadRequestException>()
                  .having((e) => e.statusCode, 'status code', equals(400))
                  .having(
                    (e) => e.message,
                    'message',
                    contains('Invalid request parameters'),
                  ),
            ),
            reason:
                'Should throw WeatherBadRequestException for 400 status with specific message',
          );
        },
      );

      test('should throw WeatherAuthException for 401 status code', () async {
        // Arrange
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response('{"message": "Unauthorized"}', 401),
        );

        // Act & Assert
        expect(
          () => weatherService.getWeather(testPosition),
          throwsA(
            isA<WeatherAuthException>()
                .having((e) => e.statusCode, 'status code', equals(401))
                .having(
                  (e) => e.message,
                  'message',
                  contains('Invalid or missing API key'),
                ),
          ),
          reason:
              'Should throw WeatherAuthException for 401 status with specific message',
        );
      });

      test(
        'should throw WeatherQuotaExceededException for 403 status code',
        () async {
          // Arrange
          when(mockHttpClient.get(any)).thenAnswer(
            (_) async => http.Response('{"message": "Forbidden"}', 403),
          );

          // Act & Assert
          expect(
            () => weatherService.getWeather(testPosition),
            throwsA(
              isA<WeatherQuotaExceededException>()
                  .having((e) => e.statusCode, 'status code', equals(403))
                  .having(
                    (e) => e.message,
                    'message',
                    contains('API quota exceeded'),
                  ),
            ),
            reason:
                'Should throw WeatherQuotaExceededException for 403 status with specific message',
          );
        },
      );

      test(
        'should throw WeatherRateLimitException for 429 status code without retry-after',
        () async {
          // Arrange
          when(mockHttpClient.get(any)).thenAnswer(
            (_) async => http.Response(
              '{"message": "Too many requests"}',
              429,
              headers: {},
            ),
          );

          // Act & Assert
          expect(
            () => weatherService.getWeather(testPosition),
            throwsA(
              isA<WeatherRateLimitException>()
                  .having((e) => e.statusCode, 'status code', equals(429))
                  .having(
                    (e) => e.message,
                    'message',
                    contains('Rate limit exceeded'),
                  )
                  .having(
                    (e) => e.retryAfterSeconds,
                    'retry after seconds',
                    isNull,
                  ),
            ),
            reason:
                'Should throw WeatherRateLimitException for 429 status without retry-after header',
          );
        },
      );

      test(
        'should throw WeatherRateLimitException for 429 status code with retry-after header',
        () async {
          // Arrange - Use a shorter retry-after to avoid test timeout
          when(mockHttpClient.get(any)).thenAnswer(
            (_) async => http.Response(
              '{"message": "Too many requests"}',
              429,
              headers: {'retry-after': '1'},
            ),
          );

          // Act & Assert
          expect(
            () => weatherService.getWeather(testPosition),
            throwsA(
              isA<WeatherRateLimitException>()
                  .having((e) => e.statusCode, 'status code', equals(429))
                  .having(
                    (e) => e.message,
                    'message',
                    contains('Rate limit exceeded'),
                  )
                  .having(
                    (e) => e.retryAfterSeconds,
                    'retry after seconds',
                    equals(1),
                  ),
            ),
            reason:
                'Should throw WeatherRateLimitException for 429 status with parsed retry-after header',
          );
        },
      );
    });

    group('retry logic', () {
      test('should fail after max retries exceeded', () async {
        // Arrange - All calls return 429
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response('{"message": "Too many requests"}', 429),
        );

        // Act & Assert
        expect(
          () => weatherService.getWeather(testPosition),
          throwsA(isA<WeatherRateLimitException>()),
          reason: 'Should throw after max retries exceeded',
        );
      });
    });

    group('environment variable', () {
      test(
        'should throw WeatherApiException when no supported API key is set',
        () {
          dotenv.testLoad(fileInput: '');
          final testWeatherService = WeatherService(mockHttpClient);
          expect(
            () => testWeatherService.getWeather(testPosition),
            throwsA(
              isA<WeatherApiException>().having(
                (e) => e.message,
                'message',
                contains('Weather API key not configured'),
              ),
            ),
            reason:
                'Should throw WeatherApiException with generic message when key missing',
          );
          dotenv.testLoad(fileInput: 'TOMORROWIO_API_KEY=test_api_key_12345');
        },
      );
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
        expect(
          () => WeatherService(mockHttpWithoutKey),
          returnsNormally,
          reason: 'Service should initialize successfully without API key',
        );
      });

      test('hasApiKey should return false when no API key is configured', () {
        // Clear any existing API key
        dotenv.testLoad(fileInput: '');

        // Act & Assert
        expect(
          serviceWithoutKey.hasApiKey,
          isFalse,
          reason: 'hasApiKey should return false when no API key is configured',
        );
      });

      test(
        'hasApiKey should return true when Tomorrow.io API key is configured',
        () {
          dotenv.testLoad(fileInput: 'TOMORROWIO_API_KEY=test_key_123');
          final serviceWithKey = WeatherService(mockHttpWithoutKey);
          expect(
            serviceWithKey.hasApiKey,
            isTrue,
            reason:
                'hasApiKey should return true when new Tomorrow.io API key is configured',
          );
        },
      );

      test(
        'apiKeyStatusMessage should return appropriate message when no API key',
        () {
          // Clear any existing API key
          dotenv.testLoad(fileInput: '');

          // Act
          final message = serviceWithoutKey.apiKeyStatusMessage;

          // Assert
          expect(
            message,
            contains('not configured'),
            reason: 'Status message should indicate API key is not configured',
          );
          expect(
            message,
            contains('unavailable'),
            reason:
                'Status message should mention weather features will be unavailable',
          );
        },
      );

      test(
        'apiKeyStatusMessage should return success message when Tomorrow.io key configured',
        () {
          dotenv.testLoad(fileInput: 'TOMORROWIO_API_KEY=test_key_123');
          final serviceWithKey = WeatherService(mockHttpWithoutKey);
          final message = serviceWithKey.apiKeyStatusMessage;
          expect(
            message,
            contains('configured'),
            reason: 'Status should indicate configured key',
          );
          expect(
            message,
            isNot(contains('unavailable')),
            reason: 'Configured message should not mention unavailability',
          );
        },
      );

      test(
        'getWeather should throw WeatherApiException when no API key configured',
        () async {
          // Clear any existing API key
          dotenv.testLoad(fileInput: '');

          // Act & Assert
          await expectLater(
            serviceWithoutKey.getWeather(testPosition),
            throwsA(
              isA<WeatherApiException>()
                  .having(
                    (e) => e.message,
                    'message',
                    contains('not configured'),
                  )
                  .having((e) => e.statusCode, 'statusCode', equals(0)),
            ),
            reason:
                'Should throw WeatherApiException when API key is not configured',
          );
        },
      );

      test(
        'getWeatherByLocation should throw WeatherApiException when no API key configured',
        () async {
          // Clear any existing API key
          dotenv.testLoad(fileInput: '');

          // Act & Assert
          await expectLater(
            serviceWithoutKey.getWeatherByLocation('San Francisco'),
            throwsA(
              isA<WeatherApiException>()
                  .having(
                    (e) => e.message,
                    'message',
                    contains('not configured'),
                  )
                  .having((e) => e.statusCode, 'statusCode', equals(0)),
            ),
            reason:
                'Should throw WeatherApiException when API key is not configured',
          );
        },
      );

      test(
        'validateLocation should return false when no API key configured',
        () async {
          // Initialize binding for this test since it uses SnackBarHelper
          TestWidgetsFlutterBinding.ensureInitialized();

          // Clear any existing API key
          dotenv.testLoad(fileInput: '');

          // Act
          final result = await serviceWithoutKey.validateLocation(
            'San Francisco',
          );

          // Assert
          expect(
            result,
            isFalse,
            reason:
                'validateLocation should return false when API key is not configured',
          );
        },
      );

      test(
        'getWeather should work normally when Tomorrow.io API key is configured',
        () async {
          dotenv.testLoad(fileInput: 'TOMORROWIO_API_KEY=test_key_123');

          // Arrange - Tomorrow.io realtime
          final mockResponse = {
            'data': {
              'time': DateTime.now().toUtc().toIso8601String(),
              'values': {
                'temperature': 15.5,
                'temperatureApparent': 14.2,
                'humidity': 65,
                'weatherCode': 1000,
              },
            },
          };

          when(mockHttpWithoutKey.get(any)).thenAnswer(
            (_) async => http.Response(json.encode(mockResponse), 200),
          );

          // Act
          final result = await serviceWithoutKey.getWeather(testPosition);

          // Assert
          expect(
            result,
            isNotNull,
            reason: 'Should return WeatherSummary when API key is configured',
          );
          expect(
            result.temperature,
            equals(15.5),
            reason: 'Should parse realtime temperature correctly',
          );
          expect(
            result.description,
            equals('Clear'),
            reason: 'Should map weatherCode to description',
          );
        },
      );

      test(
        'should throw WeatherBadRequestException when validation returns 400',
        () async {
          dotenv.testLoad(fileInput: 'TOMORROWIO_API_KEY=bad_request_key');
          when(mockHttpWithoutKey.get(any)).thenAnswer(
            (_) async => http.Response('{"message": "Bad request"}', 400),
          );

          expect(
            () => serviceWithoutKey.getWeather(testPosition),
            throwsA(
              isA<WeatherBadRequestException>()
                  .having((e) => e.statusCode, 'status code', equals(400))
                  .having(
                    (e) => e.message,
                    'message',
                    contains('Invalid request parameters'),
                  ),
            ),
            reason:
                'Should throw WeatherBadRequestException for validation 400 error',
          );
        },
      );

      test(
        'should throw WeatherAuthException when validation returns 401',
        () async {
          dotenv.testLoad(fileInput: 'TOMORROWIO_API_KEY=invalid_key');
          when(mockHttpWithoutKey.get(any)).thenAnswer(
            (_) async => http.Response('{"message": "Unauthorized"}', 401),
          );

          expect(
            () => serviceWithoutKey.getWeather(testPosition),
            throwsA(
              isA<WeatherAuthException>()
                  .having((e) => e.statusCode, 'status code', equals(401))
                  .having(
                    (e) => e.message,
                    'message',
                    contains('Invalid or missing API key'),
                  ),
            ),
            reason:
                'Should throw WeatherAuthException for validation 401 error',
          );
        },
      );

      test(
        'should throw WeatherQuotaExceededException when validation returns 403',
        () async {
          dotenv.testLoad(fileInput: 'TOMORROWIO_API_KEY=quota_exceeded_key');
          when(mockHttpWithoutKey.get(any)).thenAnswer(
            (_) async => http.Response('{"message": "Forbidden"}', 403),
          );

          expect(
            () => serviceWithoutKey.getWeather(testPosition),
            throwsA(
              isA<WeatherQuotaExceededException>()
                  .having((e) => e.statusCode, 'status code', equals(403))
                  .having(
                    (e) => e.message,
                    'message',
                    contains('API quota exceeded'),
                  ),
            ),
            reason:
                'Should throw WeatherQuotaExceededException for validation 403 error',
          );
        },
      );

      test(
        'should throw WeatherRateLimitException when validation returns 429',
        () async {
          dotenv.testLoad(fileInput: 'TOMORROWIO_API_KEY=rate_limited_key');
          when(mockHttpWithoutKey.get(any)).thenAnswer(
            (_) async => http.Response(
              '{"message": "Too many requests"}',
              429,
              headers: {'retry-after': '120'},
            ),
          );

          expect(
            () => serviceWithoutKey.getWeather(testPosition),
            throwsA(
              isA<WeatherRateLimitException>()
                  .having((e) => e.statusCode, 'status code', equals(429))
                  .having(
                    (e) => e.message,
                    'message',
                    contains('Rate limit exceeded'),
                  )
                  .having(
                    (e) => e.retryAfterSeconds,
                    'retry after seconds',
                    equals(120),
                  ),
            ),
            reason:
                'Should throw WeatherRateLimitException for validation 429 error with retry-after',
          );
        },
      );

      tearDown(() {
        dotenv.testLoad(fileInput: 'TOMORROWIO_API_KEY=test_api_key_12345');
      });
    });
  });
}
