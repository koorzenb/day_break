/// Base class for all notification-related exceptions
abstract class NotificationException implements Exception {
  final String message;
  const NotificationException(this.message);

  @override
  String toString() => 'NotificationException: $message';
}

/// Thrown when notification permission is denied
class NotificationPermissionDeniedException extends NotificationException {
  const NotificationPermissionDeniedException()
    : super('Notification permission denied by user');
}

/// Thrown when notification initialization fails
class NotificationInitializationException extends NotificationException {
  const NotificationInitializationException(super.message);
}

/// Thrown when notification scheduling fails
class NotificationSchedulingException extends NotificationException {
  const NotificationSchedulingException(super.message);
}
