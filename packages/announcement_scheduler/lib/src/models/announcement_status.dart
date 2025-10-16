/// Status of an announcement
enum AnnouncementStatus {
  /// Announcement is scheduled and waiting to be delivered
  scheduled,

  /// Announcement is currently being delivered (TTS playing)
  delivering,

  /// Announcement was successfully delivered
  completed,

  /// Announcement delivery failed
  failed,
}

/// Extension methods for AnnouncementStatus
extension AnnouncementStatusExtension on AnnouncementStatus {
  String get displayName {
    switch (this) {
      case AnnouncementStatus.scheduled:
        return 'Scheduled';
      case AnnouncementStatus.delivering:
        return 'Delivering';
      case AnnouncementStatus.completed:
        return 'Completed';
      case AnnouncementStatus.failed:
        return 'Failed';
    }
  }

  bool get isActive =>
      this == AnnouncementStatus.scheduled ||
      this == AnnouncementStatus.delivering;
  bool get isComplete =>
      this == AnnouncementStatus.completed || this == AnnouncementStatus.failed;
}
