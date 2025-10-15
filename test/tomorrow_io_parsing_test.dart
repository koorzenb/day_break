import 'dart:convert';

import 'package:day_break/models/weather_exceptions.dart';
import 'package:day_break/services/weather_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tomorrow.io Parsing Adapter', () {
    setUpAll(() async {
      // Initialize dotenv for testing by loading from test .env file
      await dotenv.load(fileName: 'test/.env');
    });

    test('parses valid realtime payload', () {
      final service = WeatherService();
      final payload =
          jsonDecode(
                '{"data":{"time":"2025-10-02T12:00:00Z","values":{"temperature":12.34,"temperatureApparent":11.2,"humidity":68,"weatherCode":1001}}}',
              )
              as Map<String, dynamic>;
      final summary = service.parseTomorrowRealtime(
        payload,
        latitude: 44.65,
        longitude: -63.57,
      );
      expect(
        summary.temperature,
        equals(12.34),
        reason: 'Should map temperature',
      );
      expect(
        summary.feelsLike,
        equals(11.2),
        reason: 'Should map apparent temperature',
      );
      expect(summary.humidity, equals(68), reason: 'Should map humidity');
      expect(
        summary.description,
        isNotEmpty,
        reason: 'Description should be derived from code',
      );
      expect(
        summary.location,
        contains('44.65'),
        reason: 'Fallback location should be coordinate-based',
      );
    });

    test('handles missing optional fields gracefully', () {
      final service = WeatherService();
      final payload =
          jsonDecode(
                '{"data":{"time":"2025-10-02T12:00:00Z","values":{"temperature":5}}}',
              )
              as Map<String, dynamic>;
      final summary = service.parseTomorrowRealtime(
        payload,
        latitude: 10,
        longitude: 20,
      );
      expect(
        summary.temperature,
        equals(5),
        reason: 'Temperature still parsed',
      );
      expect(
        summary.feelsLike,
        equals(5),
        reason: 'Feels like falls back to temperature',
      );
      expect(
        summary.humidity,
        equals(0),
        reason: 'Missing humidity defaults to 0',
      );
      expect(
        summary.description,
        isNotEmpty,
        reason: 'Description defaults to Unknown when code missing',
      );
    });

    test('throws parsing exception for malformed structure', () {
      final service = WeatherService();
      final badPayload = {'foo': 'bar'};
      expect(
        () => service.parseTomorrowRealtime(badPayload),
        throwsA(isA<WeatherParsingException>()),
        reason: 'Missing data/values should raise parsing exception',
      );
    });
  });
}
