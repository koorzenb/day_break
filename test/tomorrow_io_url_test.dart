import 'package:day_break/services/weather_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tomorrow.io URL Builders', () {
    setUp(() {
      dotenv.testLoad(fileInput: 'TOMORROWIO_API_KEY=test_api_key_12345');
    });

    test('realtime URL contains required query parameters', () {
      final service = WeatherService();
      final uri = service.buildTomorrowRealtimeUrlForTesting(44.65, -63.57);
      expect(uri.host, equals('api.tomorrow.io'), reason: 'Host should match Tomorrow.io domain');
      expect(uri.path, contains('realtime'), reason: 'Path should target realtime endpoint');
      expect(uri.queryParameters['location'], equals('44.65,-63.57'), reason: 'Location should be latitude,longitude');
      expect(uri.queryParameters['apikey'], isNotEmpty, reason: 'API key must be present');
      expect(uri.queryParameters['units'], equals('metric'), reason: 'Units should be metric');
      expect(uri.queryParameters['fields'], contains('temperature'), reason: 'Fields should include temperature');
    });

    test('forecast URL includes timesteps and fields', () {
      final service = WeatherService();
      final uri = service.buildTomorrowForecastUrlForTesting(44.65, -63.57, timesteps: '1h');
      expect(uri.path, contains('forecast'), reason: 'Path should target forecast endpoint');
      expect(uri.queryParameters['timesteps'], equals('1h'), reason: 'Timesteps should be forwarded');
      expect(uri.queryParameters['fields']!.split(',').length, greaterThan(3), reason: 'Fields list should contain multiple entries');
    });
  });
}
