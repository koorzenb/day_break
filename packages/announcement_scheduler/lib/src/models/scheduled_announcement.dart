import 'recurrence_pattern.dart';

/// Represents a scheduled announcement
class ScheduledAnnouncement {
  /// Unique identifier for the announcement
  final String id;

  /// The text content to be announced
  final String content;

  /// When the announcement is scheduled to be delivered
  final DateTime scheduledTime;

  /// The recurrence pattern (null for one-time announcements)
  final RecurrencePattern? recurrence;

  /// Custom days for custom recurrence pattern (1=Monday, 7=Sunday)
  final List<int>? customDays;

  /// Whether this announcement is currently active
  final bool isActive;

  /// Optional metadata associated with the announcement
  final Map<String, dynamic>? metadata;

  const ScheduledAnnouncement({
    required this.id,
    required this.content,
    required this.scheduledTime,
    this.recurrence,
    this.customDays,
    this.isActive = true,
    this.metadata,
  });

  /// Creates a copy of this announcement with the given fields replaced
  ScheduledAnnouncement copyWith({
    String? id,
    String? content,
    DateTime? scheduledTime,
    RecurrencePattern? recurrence,
    List<int>? customDays,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return ScheduledAnnouncement(
      id: id ?? this.id,
      content: content ?? this.content,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      recurrence: recurrence ?? this.recurrence,
      customDays: customDays ?? this.customDays,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Whether this is a recurring announcement
  bool get isRecurring => recurrence != null;

  /// Whether this is a one-time announcement
  bool get isOneTime => recurrence == null;

  /// Get the days this announcement should run
  List<int> get effectiveDays {
    if (recurrence == null) return [];
    if (recurrence == RecurrencePattern.custom) {
      return customDays ?? [];
    }
    return recurrence!.defaultDays;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledAnnouncement &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          content == other.content &&
          scheduledTime == other.scheduledTime &&
          recurrence == other.recurrence &&
          _listEquals(customDays, other.customDays) &&
          isActive == other.isActive &&
          _mapEquals(metadata, other.metadata);

  @override
  int get hashCode =>
      id.hashCode ^
      content.hashCode ^
      scheduledTime.hashCode ^
      recurrence.hashCode ^
      customDays.hashCode ^
      isActive.hashCode ^
      metadata.hashCode;

  @override
  String toString() {
    return 'ScheduledAnnouncement{'
        'id: $id, '
        'content: $content, '
        'scheduledTime: $scheduledTime, '
        'recurrence: $recurrence, '
        'customDays: $customDays, '
        'isActive: $isActive, '
        'metadata: $metadata'
        '}';
  }

  /// Helper method for comparing lists
  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  /// Helper method for comparing maps
  static bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final K key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) return false;
    }
    return true;
  }
}
