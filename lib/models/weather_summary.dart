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
    // Extract forecast list and city information
    final List<dynamic> forecastList = json['list'] as List<dynamic>;
    final Map<String, dynamic> cityInfo = json['city'] as Map<String, dynamic>;

    if (forecastList.isEmpty) {
      throw const FormatException('Forecast list is empty');
    }

    // Use the first forecast entry for current conditions
    final currentForecast = forecastList.first as Map<String, dynamic>;

    // Calculate daily temperature range from today's forecasts only
    // Filter forecasts to only include entries from today (before end of day)
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final endOfTodayEpoch = endOfToday.millisecondsSinceEpoch ~/ 1000;

    double dailyMin = double.infinity;
    double dailyMax = double.negativeInfinity;

    for (final forecast in forecastList) {
      final forecastMap = forecast as Map<String, dynamic>;
      final dt = forecastMap['dt'] as int;

      // Break when we reach tomorrow's forecasts (since list is chronologically ordered)
      if (dt > endOfTodayEpoch) {
        break;
      }

      final tempMin = (forecastMap['main']['temp_min'] as num).toDouble();
      final tempMax = (forecastMap['main']['temp_max'] as num).toDouble();
      dailyMin = dailyMin < tempMin ? dailyMin : tempMin;
      dailyMax = dailyMax > tempMax ? dailyMax : tempMax;
    }

    // Fallback to current forecast min/max if no valid daily range found
    if (dailyMin == double.infinity || dailyMax == double.negativeInfinity) {
      dailyMin = (currentForecast['main']['temp_min'] as num).toDouble();
      dailyMax = (currentForecast['main']['temp_max'] as num).toDouble();
    }

    return WeatherSummary(
      description: currentForecast['weather'][0]['description'] as String,
      temperature: (currentForecast['main']['temp'] as num).toDouble(),
      feelsLike: (currentForecast['main']['feels_like'] as num).toDouble(),
      tempMin: dailyMin,
      tempMax: dailyMax,
      humidity: currentForecast['main']['humidity'] as int,
      location: cityInfo['name'] as String,
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
