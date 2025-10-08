/// Enumeration for different recurrence patterns for weather announcements
enum RecurrencePattern { daily, weekdays, weekends, custom }

/// Extension methods for RecurrencePattern to provide utility functions
extension RecurrencePatternExtension on RecurrencePattern {
  String get displayName {
    switch (this) {
      case RecurrencePattern.daily:
        return 'Daily';
      case RecurrencePattern.weekdays:
        return 'Weekdays';
      case RecurrencePattern.weekends:
        return 'Weekends';
      case RecurrencePattern.custom:
        return 'Custom';
    }
  }

  /// Get the default days for non-custom patterns
  /// Returns days of week where 1=Monday, 2=Tuesday, ..., 7=Sunday
  List<int> get defaultDays {
    switch (this) {
      case RecurrencePattern.daily:
        return [1, 2, 3, 4, 5, 6, 7]; // All days
      case RecurrencePattern.weekdays:
        return [1, 2, 3, 4, 5]; // Monday to Friday
      case RecurrencePattern.weekends:
        return [6, 7]; // Saturday and Sunday
      case RecurrencePattern.custom:
        return []; // Custom pattern has no defaults
    }
  }
}
