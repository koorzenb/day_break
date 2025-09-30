class WeatherSummary {
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

  factory WeatherSummary.fromJson(Map<String, dynamic> json) {
    return WeatherSummary(
      description: json['weather'][0]['description'] as String,
      temperature: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      tempMin: (json['main']['temp_min'] as num).toDouble(),
      tempMax: (json['main']['temp_max'] as num).toDouble(),
      humidity: json['main']['humidity'] as int,
      location: json['name'] as String,
      timestamp: DateTime.now(),
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
