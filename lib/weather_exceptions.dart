/// Base class for all weather-related exceptions
abstract class WeatherException implements Exception {
  final String message;
  const WeatherException(this.message);

  @override
  String toString() => 'WeatherException: $message';
}

/// Thrown when network request fails
class WeatherNetworkException extends WeatherException {
  const WeatherNetworkException(super.message);

  @override
  String toString() => 'WeatherNetworkException: $message';
}

/// Thrown when API returns an error response
class WeatherApiException extends WeatherException {
  final int statusCode;

  const WeatherApiException(super.message, this.statusCode);

  @override
  String toString() => 'WeatherApiException ($statusCode): $message';
}

/// Thrown when weather data parsing fails
class WeatherParsingException extends WeatherException {
  const WeatherParsingException(super.message);

  @override
  String toString() => 'WeatherParsingException: $message';
}
