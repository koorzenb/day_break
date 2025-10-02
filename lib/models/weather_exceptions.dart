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

/// Thrown when API quota is exceeded
class WeatherQuotaExceededException extends WeatherApiException {
  const WeatherQuotaExceededException(super.message, super.statusCode);

  @override
  String toString() => 'WeatherQuotaExceededException ($statusCode): $message';
}

/// Thrown when API request is invalid (400)
class WeatherBadRequestException extends WeatherApiException {
  const WeatherBadRequestException(super.message, super.statusCode);

  @override
  String toString() => 'WeatherBadRequestException ($statusCode): $message';
}

/// Thrown when API authentication fails
class WeatherAuthException extends WeatherApiException {
  const WeatherAuthException(super.message, super.statusCode);

  @override
  String toString() => 'WeatherAuthException ($statusCode): $message';
}

/// Thrown when API rate limit is exceeded
class WeatherRateLimitException extends WeatherApiException {
  final int? retryAfterSeconds;

  const WeatherRateLimitException(super.message, super.statusCode, [this.retryAfterSeconds]);

  @override
  String toString() {
    final retryInfo = retryAfterSeconds != null ? ' (retry after ${retryAfterSeconds}s)' : '';
    return 'WeatherRateLimitException ($statusCode): $message$retryInfo';
  }
}
