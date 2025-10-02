/// Simple holder for forecast min/max
class ForecastRange {
  final double min;
  final double max;
  const ForecastRange(this.min, this.max);
}

class WeatherSummary {
  /// Returns a copy with optional min/max override
  WeatherSummary copyWith({double? minOverride, double? maxOverride}) {
    return WeatherSummary(
      description: description,
      temperature: temperature,
      feelsLike: feelsLike,
      tempMin: minOverride ?? tempMin,
      tempMax: maxOverride ?? tempMax,
      humidity: humidity,
      location: location,
      timestamp: timestamp,
    );
  }

  final String description;
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final String location;
  final DateTime timestamp;

  const WeatherSummary({
    required this.description,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.location,
    required this.timestamp,
  });

  /// Factory for Tomorrow.io realtime data (no forecast range yet)
  factory WeatherSummary.realtime({
    required String description,
    required double temperature,
    required double feelsLike,
    required int humidity,
    required String location,
    required DateTime timestamp,
  }) {
    return WeatherSummary(
      description: description,
      temperature: temperature,
      feelsLike: feelsLike,
      tempMin: temperature,
      tempMax: temperature,
      humidity: humidity,
      location: location,
      timestamp: timestamp,
    );
  }

  String get formattedAnnouncement {
    return 'It is $description today, with a current temperature of ${temperature.round()}°C. '
        'Today\'s high is ${tempMax.round()}°C and low is ${tempMin.round()}°C. ';
  }

  @override
  String toString() {
    return 'WeatherSummary(description: $description, temperature: $temperature, '
        'feelsLike: $feelsLike, tempMin: $tempMin, tempMax: $tempMax, '
        'humidity: $humidity, location: $location, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeatherSummary &&
        other.description == description &&
        other.temperature == temperature &&
        other.feelsLike == feelsLike &&
        other.tempMin == tempMin &&
        other.tempMax == tempMax &&
        other.humidity == humidity &&
        other.location == location &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return description.hashCode ^
        temperature.hashCode ^
        feelsLike.hashCode ^
        tempMin.hashCode ^
        tempMax.hashCode ^
        humidity.hashCode ^
        location.hashCode ^
        timestamp.hashCode;
  }
}
