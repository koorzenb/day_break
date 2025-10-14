import 'package:day_break/models/weather_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeatherSummary', () {
    late DateTime testTimestamp;
    late WeatherSummary testWeatherSummary;

    setUp(() {
      testTimestamp = DateTime(2023, 9, 15, 12, 0, 0);
      testWeatherSummary = WeatherSummary(
        description: 'clear sky',
        temperature: 22.5,
        feelsLike: 24.0,
        tempMin: 18.0,
        tempMax: 25.0,
        humidity: 65,
        location: 'San Francisco',
        timestamp: testTimestamp,
      );
    });

    group('formattedAnnouncement', () {
      test('should format announcement with rounded temperatures', () {
        // Act
        final announcement = testWeatherSummary.formattedAnnouncement;

        // Assert
        expect(
          announcement,
          equals(
            'It is clear sky today, with a current temperature of 23°C. '
            'Today\'s high is 25°C and low is 18°C. ',
          ),
          reason:
              'Announcement should include rounded temperatures and all weather details',
        );
      });

      test('should handle negative temperatures', () {
        // Arrange
        final coldWeather = WeatherSummary(
          description: 'snow',
          temperature: -5.7,
          feelsLike: -8.2,
          tempMin: -10.0,
          tempMax: -2.0,
          humidity: 90,
          location: 'Minneapolis',
          timestamp: testTimestamp,
        );

        // Act
        final announcement = coldWeather.formattedAnnouncement;

        // Assert
        expect(
          announcement,
          equals(
            'It is snow today, with a current temperature of -6°C. '
            'Today\'s high is -2°C and low is -10°C. ',
          ),
          reason: 'Announcement should handle negative temperatures correctly',
        );
      });
    });

    group('equality and hashCode', () {
      test('should be equal when all properties match', () {
        // Arrange
        final other = WeatherSummary(
          description: 'clear sky',
          temperature: 22.5,
          feelsLike: 24.0,
          tempMin: 18.0,
          tempMax: 25.0,
          humidity: 65,
          location: 'San Francisco',
          timestamp: testTimestamp,
        );

        // Act & Assert
        expect(
          testWeatherSummary,
          equals(other),
          reason: 'WeatherSummary objects with same properties should be equal',
        );
        expect(
          testWeatherSummary.hashCode,
          equals(other.hashCode),
          reason: 'Equal objects should have same hash code',
        );
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final other = WeatherSummary(
          description: 'cloudy',
          temperature: 22.5,
          feelsLike: 24.0,
          tempMin: 18.0,
          tempMax: 25.0,
          humidity: 65,
          location: 'San Francisco',
          timestamp: testTimestamp,
        );

        // Act & Assert
        expect(
          testWeatherSummary,
          isNot(equals(other)),
          reason:
              'WeatherSummary objects with different properties should not be equal',
        );
      });

      test('should be identical to itself', () {
        // Act & Assert
        expect(
          identical(testWeatherSummary, testWeatherSummary),
          isTrue,
          reason: 'Object should be identical to itself',
        );
      });
    });

    group('toString', () {
      test('should include all properties', () {
        // Act
        final result = testWeatherSummary.toString();

        // Assert
        expect(
          result,
          contains('clear sky'),
          reason: 'toString should include description',
        );
        expect(
          result,
          contains('22.5'),
          reason: 'toString should include temperature',
        );
        expect(
          result,
          contains('24.0'),
          reason: 'toString should include feels like temperature',
        );
        expect(
          result,
          contains('65'),
          reason: 'toString should include humidity',
        );
        expect(
          result,
          contains('San Francisco'),
          reason: 'toString should include location',
        );
        expect(
          result,
          contains(testTimestamp.toString()),
          reason: 'toString should include timestamp',
        );
      });
    });
  });
}
