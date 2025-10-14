/// Location-related domain exceptions for clearer error handling and testing.
abstract class LocationException implements Exception {
  final String message;
  const LocationException(this.message);
  @override
  String toString() => '$runtimeType: $message';
}

class LocationServicesDisabledException extends LocationException {
  const LocationServicesDisabledException()
    : super('Location services are disabled.');
}

class LocationPermissionDeniedException extends LocationException {
  const LocationPermissionDeniedException()
    : super('Location permissions are denied');
}

class LocationPermissionPermanentlyDeniedException extends LocationException {
  const LocationPermissionPermanentlyDeniedException()
    : super(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
}

class LocationUnknownException extends LocationException {
  const LocationUnknownException() : super('Unable to determine location name');
}
