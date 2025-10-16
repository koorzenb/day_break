import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Configuration for notifications used by the announcement scheduler
class NotificationConfig {
  /// The unique identifier for the notification channel
  final String channelId;

  /// The user-visible name of the notification channel
  final String channelName;

  /// The user-visible description of the notification channel
  final String channelDescription;

  /// The importance level of notifications
  final Importance importance;

  /// The priority level of notifications
  final Priority priority;

  /// Whether to show a badge on the app icon
  final bool showBadge;

  /// Whether to enable lights for notifications
  final bool enableLights;

  /// Whether to enable vibration for notifications
  final bool enableVibration;

  const NotificationConfig({
    this.channelId = 'scheduled_announcements',
    this.channelName = 'Scheduled Announcements',
    this.channelDescription = 'Automated text-to-speech announcements',
    this.importance = Importance.high,
    this.priority = Priority.high,
    this.showBadge = true,
    this.enableLights = true,
    this.enableVibration = true,
  });

  /// Creates a copy of this configuration with the given fields replaced
  NotificationConfig copyWith({
    String? channelId,
    String? channelName,
    String? channelDescription,
    Importance? importance,
    Priority? priority,
    bool? showBadge,
    bool? enableLights,
    bool? enableVibration,
  }) {
    return NotificationConfig(
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      channelDescription: channelDescription ?? this.channelDescription,
      importance: importance ?? this.importance,
      priority: priority ?? this.priority,
      showBadge: showBadge ?? this.showBadge,
      enableLights: enableLights ?? this.enableLights,
      enableVibration: enableVibration ?? this.enableVibration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationConfig &&
          runtimeType == other.runtimeType &&
          channelId == other.channelId &&
          channelName == other.channelName &&
          channelDescription == other.channelDescription &&
          importance == other.importance &&
          priority == other.priority &&
          showBadge == other.showBadge &&
          enableLights == other.enableLights &&
          enableVibration == other.enableVibration;

  @override
  int get hashCode =>
      channelId.hashCode ^
      channelName.hashCode ^
      channelDescription.hashCode ^
      importance.hashCode ^
      priority.hashCode ^
      showBadge.hashCode ^
      enableLights.hashCode ^
      enableVibration.hashCode;

  @override
  String toString() {
    return 'NotificationConfig{'
        'channelId: $channelId, '
        'channelName: $channelName, '
        'channelDescription: $channelDescription, '
        'importance: $importance, '
        'priority: $priority, '
        'showBadge: $showBadge, '
        'enableLights: $enableLights, '
        'enableVibration: $enableVibration'
        '}';
  }
}
