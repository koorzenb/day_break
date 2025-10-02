import 'dart:convert';

import 'package:day_break/http_client_wrapper.dart';
import 'package:day_break/services/weather_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'forecast_minmax_test.mocks.dart';

@GenerateMocks([HttpClientWrapper])
void main() {
  group('Forecast min/max integration', () {
    late WeatherService service;
    late MockHttpClientWrapper mockHttp;
    late Position testPosition;

    setUpAll(() async {
      dotenv.testLoad(fileInput: 'TOMORROWIO_API_KEY=test_api_key_12345');
    });

    setUp(() {
      mockHttp = MockHttpClientWrapper();
      service = WeatherService(mockHttp);
      testPosition = Position(
        latitude: 44.65,
        longitude: -63.57,
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

    test('min/max from forecast overrides realtime', () async {
      // Arrange: realtime returns 10.0, forecast returns [7.0, 10.0, 13.0]
      final realtimePayload = {
        'data': {
          'time': '2025-10-02T12:00:00Z',
          'values': {'temperature': 10.0, 'temperatureApparent': 10.0, 'humidity': 60, 'weatherCode': 1000},
        },
      };
      final forecastPayload = {
        'data': {
          'timelines': [
            {
              'intervals': [
                {
                  'values': {'temperature': 7.0},
                },
                {
                  'values': {'temperature': 10.0},
                },
                {
                  'values': {'temperature': 13.0},
                },
              ],
            },
          ],
        },
      };
      when(mockHttp.get(any)).thenAnswer((invocation) async {
        final uri = invocation.positionalArguments[0].toString();
        if (uri.contains('realtime')) {
          return http.Response(json.encode(realtimePayload), 200);
        } else if (uri.contains('forecast')) {
          return http.Response(json.encode(forecastPayload), 200);
        }
        return http.Response('not found', 404);
      });

      // Act
      final summary = await service.getWeather(testPosition);

      // Assert
      expect(summary.temperature, equals(10.0), reason: 'Realtime temp should be used');
      expect(summary.tempMin, equals(7.0), reason: 'Min from forecast should override');
      expect(summary.tempMax, equals(13.0), reason: 'Max from forecast should override');
    });

    test('fallback to realtime temp if forecast fails', () async {
      final realtimePayload = {
        'data': {
          'time': '2025-10-02T12:00:00Z',
          'values': {'temperature': 8.0, 'temperatureApparent': 8.0, 'humidity': 60, 'weatherCode': 1000},
        },
      };
      when(mockHttp.get(any)).thenAnswer((invocation) async {
        final uri = invocation.positionalArguments[0].toString();
        if (uri.contains('realtime')) {
          return http.Response(json.encode(realtimePayload), 200);
        } else if (uri.contains('forecast')) {
          return http.Response('error', 500);
        }
        return http.Response('not found', 404);
      });

      final summary = await service.getWeather(testPosition);
      expect(summary.tempMin, equals(8.0), reason: 'Should fallback to realtime temp for min');
      expect(summary.tempMax, equals(8.0), reason: 'Should fallback to realtime temp for max');
    });
  });
}
