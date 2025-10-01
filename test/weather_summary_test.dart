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

    group('fromJson', () {
      test('should create WeatherSummary from valid JSON', () {
        // Arrange
        final json = {
          'cod': '200',
          'message': 0,
          'cnt': 3,
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
              'main': {'temp': 20.0, 'feels_like': 21.0, 'temp_min': 16.0, 'temp_max': 23.0, 'humidity': 70},
              'weather': [
                {'description': 'few clouds'},
              ],
            },
            {
              'dt': 1759352400,
              'main': {'temp': 19.0, 'feels_like': 20.0, 'temp_min': 15.0, 'temp_max': 22.0, 'humidity': 75},
              'weather': [
                {'description': 'overcast clouds'},
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

        // Act
        final result = WeatherSummary.fromJson(json);

        // Assert
        expect(result.description, equals('clear sky'), reason: 'Description should be parsed from first forecast weather array');
        expect(result.temperature, equals(22.5), reason: 'Temperature should be parsed from first forecast main object');
        expect(result.feelsLike, equals(24.0), reason: 'Feels like should be parsed from first forecast main object');
        expect(result.tempMin, equals(15.0), reason: 'Temperature minimum should be calculated from daily forecasts');
        expect(result.tempMax, equals(25.0), reason: 'Temperature maximum should be calculated from daily forecasts');
        expect(result.humidity, equals(65), reason: 'Humidity should be parsed from first forecast main object');
        expect(result.location, equals('San Francisco'), reason: 'Location should be parsed from city name field');
        expect(result.timestamp, isA<DateTime>(), reason: 'Timestamp should be set to current time');
      });

      test('should handle integer temperature values', () {
        // Arrange
        final json = {
          'cod': '200',
          'message': 0,
          'cnt': 2,
          'list': [
            {
              'dt': 1759330800,
              'main': {'temp': 20, 'feels_like': 22, 'temp_min': 18, 'temp_max': 25, 'humidity': 70},
              'weather': [
                {'description': 'cloudy'},
              ],
            },
            {
              'dt': 1759341600,
              'main': {'temp': 19, 'feels_like': 21, 'temp_min': 17, 'temp_max': 24, 'humidity': 75},
              'weather': [
                {'description': 'overcast clouds'},
              ],
            },
          ],
          'city': {
            'id': 12345,
            'name': 'Test City',
            'coord': {'lat': 40.0, 'lon': -74.0},
            'country': 'US',
          },
        };

        // Act
        final result = WeatherSummary.fromJson(json);

        // Assert
        expect(result.temperature, equals(20.0), reason: 'Integer temperature should be converted to double');
        expect(result.feelsLike, equals(22.0), reason: 'Integer feels like should be converted to double');
        expect(result.tempMin, equals(17.0), reason: 'Daily temp_min should be calculated from forecasts');
        expect(result.tempMax, equals(25.0), reason: 'Daily temp_max should be calculated from forecasts');
      });
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
          reason: 'Announcement should include rounded temperatures and all weather details',
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
        expect(testWeatherSummary, equals(other), reason: 'WeatherSummary objects with same properties should be equal');
        expect(testWeatherSummary.hashCode, equals(other.hashCode), reason: 'Equal objects should have same hash code');
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
        expect(testWeatherSummary, isNot(equals(other)), reason: 'WeatherSummary objects with different properties should not be equal');
      });

      test('should be identical to itself', () {
        // Act & Assert
        expect(identical(testWeatherSummary, testWeatherSummary), isTrue, reason: 'Object should be identical to itself');
      });
    });

    group('toString', () {
      test('should include all properties', () {
        // Act
        final result = testWeatherSummary.toString();

        // Assert
        expect(result, contains('clear sky'), reason: 'toString should include description');
        expect(result, contains('22.5'), reason: 'toString should include temperature');
        expect(result, contains('24.0'), reason: 'toString should include feels like temperature');
        expect(result, contains('65'), reason: 'toString should include humidity');
        expect(result, contains('San Francisco'), reason: 'toString should include location');
        expect(result, contains(testTimestamp.toString()), reason: 'toString should include timestamp');
      });
    });
  });
}
