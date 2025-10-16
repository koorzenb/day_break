/// Configuration for validation rules applied by the announcement scheduler
class ValidationConfig {
  /// Maximum number of notifications that can be scheduled per day
  final int maxNotificationsPerDay;

  /// Maximum total number of scheduled notifications
  final int maxScheduledNotifications;

  /// Whether to enable edge case validation (DST transitions, leap days, etc.)
  final bool enableEdgeCaseValidation;

  /// Whether to enable timezone validation
  final bool enableTimezoneValidation;

  /// Minimum interval between announcements (in minutes)
  final int minAnnouncementIntervalMinutes;

  /// Maximum days in advance to schedule recurring notifications
  final int maxSchedulingDaysInAdvance;

  const ValidationConfig({
    this.maxNotificationsPerDay = 10,
    this.maxScheduledNotifications = 50,
    this.enableEdgeCaseValidation = true,
    this.enableTimezoneValidation = true,
    this.minAnnouncementIntervalMinutes = 1,
    this.maxSchedulingDaysInAdvance = 14,
  });

  /// Creates a copy of this configuration with the given fields replaced
  ValidationConfig copyWith({
    int? maxNotificationsPerDay,
    int? maxScheduledNotifications,
    bool? enableEdgeCaseValidation,
    bool? enableTimezoneValidation,
    int? minAnnouncementIntervalMinutes,
    int? maxSchedulingDaysInAdvance,
  }) {
    return ValidationConfig(
      maxNotificationsPerDay:
          maxNotificationsPerDay ?? this.maxNotificationsPerDay,
      maxScheduledNotifications:
          maxScheduledNotifications ?? this.maxScheduledNotifications,
      enableEdgeCaseValidation:
          enableEdgeCaseValidation ?? this.enableEdgeCaseValidation,
      enableTimezoneValidation:
          enableTimezoneValidation ?? this.enableTimezoneValidation,
      minAnnouncementIntervalMinutes:
          minAnnouncementIntervalMinutes ?? this.minAnnouncementIntervalMinutes,
      maxSchedulingDaysInAdvance:
          maxSchedulingDaysInAdvance ?? this.maxSchedulingDaysInAdvance,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationConfig &&
          runtimeType == other.runtimeType &&
          maxNotificationsPerDay == other.maxNotificationsPerDay &&
          maxScheduledNotifications == other.maxScheduledNotifications &&
          enableEdgeCaseValidation == other.enableEdgeCaseValidation &&
          enableTimezoneValidation == other.enableTimezoneValidation &&
          minAnnouncementIntervalMinutes ==
              other.minAnnouncementIntervalMinutes &&
          maxSchedulingDaysInAdvance == other.maxSchedulingDaysInAdvance;

  @override
  int get hashCode =>
      maxNotificationsPerDay.hashCode ^
      maxScheduledNotifications.hashCode ^
      enableEdgeCaseValidation.hashCode ^
      enableTimezoneValidation.hashCode ^
      minAnnouncementIntervalMinutes.hashCode ^
      maxSchedulingDaysInAdvance.hashCode;

  @override
  String toString() {
    return 'ValidationConfig{'
        'maxNotificationsPerDay: $maxNotificationsPerDay, '
        'maxScheduledNotifications: $maxScheduledNotifications, '
        'enableEdgeCaseValidation: $enableEdgeCaseValidation, '
        'enableTimezoneValidation: $enableTimezoneValidation, '
        'minAnnouncementIntervalMinutes: $minAnnouncementIntervalMinutes, '
        'maxSchedulingDaysInAdvance: $maxSchedulingDaysInAdvance'
        '}';
  }
}
