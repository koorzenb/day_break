/// Base class for all announcement-related exceptions
abstract class AnnouncementException implements Exception {
  final String message;
  const AnnouncementException(this.message);

  @override
  String toString() => 'AnnouncementException: $message';
}

/// Thrown when notification permission is denied
class NotificationPermissionDeniedException extends AnnouncementException {
  const NotificationPermissionDeniedException()
    : super('Notification permission denied by user');
}

/// Thrown when notification initialization fails
class NotificationInitializationException extends AnnouncementException {
  const NotificationInitializationException(super.message);
}

/// Thrown when notification scheduling fails
class NotificationSchedulingException extends AnnouncementException {
  const NotificationSchedulingException(super.message);
}

/// Thrown when TTS (Text-to-Speech) initialization fails
class TTSInitializationException extends AnnouncementException {
  const TTSInitializationException(super.message);
}

/// Thrown when TTS (Text-to-Speech) announcement fails
class TTSAnnouncementException extends AnnouncementException {
  const TTSAnnouncementException(super.message);
}

/// Thrown when validation fails
class ValidationException extends AnnouncementException {
  const ValidationException(super.message);
}
