import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'models/announcement_config.dart';
import 'models/announcement_exceptions.dart';
import 'models/announcement_status.dart';
import 'models/recurrence_pattern.dart';
import 'models/scheduled_announcement.dart';
import 'services/announcement_service.dart';

/// Main entry point for the announcement scheduler package
class AnnouncementScheduler {
  final AnnouncementConfig _config;
  final AnnouncementService _service;

  /// Stream controller for announcement status updates
  final StreamController<AnnouncementStatus> _statusController =
      StreamController<AnnouncementStatus>.broadcast();

  AnnouncementScheduler._({
    required AnnouncementConfig config,
    required AnnouncementService service,
  }) : _config = config,
       _service = service;

  /// Initialize the announcement scheduler with the given configuration
  static Future<AnnouncementScheduler> initialize({
    required AnnouncementConfig config,
  }) async {
    // Initialize timezone data
    tz.initializeTimeZones();

    // Set local timezone if specified
    if (config.forceTimezone && config.timezoneLocation != null) {
      try {
        tz.setLocalLocation(tz.getLocation(config.timezoneLocation!));
      } catch (e) {
        throw NotificationInitializationException(
          'Failed to set timezone location ${config.timezoneLocation}: $e',
        );
      }
    }

    // Initialize the announcement service
    final service = AnnouncementService();
    await service.initialize(config);

    return AnnouncementScheduler._(config: config, service: service);
  }

  /// Schedule an announcement with optional recurrence
  Future<String> scheduleAnnouncement({
    required String content,
    required TimeOfDay announcementTime,
    RecurrencePattern? recurrence,
    List<int>? customDays,
    Map<String, dynamic>? metadata,
  }) async {
    // Validate content
    if (content.trim().isEmpty) {
      throw const ValidationException('Announcement content cannot be empty');
    }

    // Validate custom days if using custom recurrence
    if (recurrence == RecurrencePattern.custom) {
      if (customDays == null || customDays.isEmpty) {
        throw const ValidationException(
          'Custom days must be provided when using custom recurrence pattern',
        );
      }
      if (customDays.any((day) => day < 1 || day > 7)) {
        throw const ValidationException(
          'Custom days must be between 1 (Monday) and 7 (Sunday)',
        );
      }
    }

    // Generate unique ID
    final id = 'announcement_${DateTime.now().millisecondsSinceEpoch}';

    // Calculate next occurrence
    final now = DateTime.now();
    final nextOccurrence = _calculateNextOccurrence(
      announcementTime,
      recurrence,
      customDays,
      now,
    );

    // Create scheduled announcement
    final announcement = ScheduledAnnouncement(
      id: id,
      content: content,
      scheduledTime: nextOccurrence,
      recurrence: recurrence,
      customDays: customDays,
      metadata: metadata,
    );

    // Schedule with the service
    await _service.scheduleAnnouncement(announcement);

    _log('Scheduled announcement: $id at $nextOccurrence');
    return id;
  }

  /// Schedule a one-time announcement at a specific date and time
  Future<String> scheduleOneTimeAnnouncement({
    required String content,
    required DateTime dateTime,
    Map<String, dynamic>? metadata,
  }) async {
    // Validate content
    if (content.trim().isEmpty) {
      throw const ValidationException('Announcement content cannot be empty');
    }

    // Validate date is in the future
    if (dateTime.isBefore(DateTime.now())) {
      throw const ValidationException('Scheduled time must be in the future');
    }

    // Generate unique ID
    final id = 'announcement_${DateTime.now().millisecondsSinceEpoch}';

    // Create scheduled announcement
    final announcement = ScheduledAnnouncement(
      id: id,
      content: content,
      scheduledTime: dateTime,
      metadata: metadata,
    );

    // Schedule with the service
    await _service.scheduleAnnouncement(announcement);

    _log('Scheduled one-time announcement: $id at $dateTime');
    return id;
  }

  /// Cancel all scheduled announcements
  Future<void> cancelScheduledAnnouncements() async {
    await _service.cancelAllScheduledAnnouncements();
    _log('Cancelled all scheduled announcements');
  }

  /// Cancel a specific announcement by ID
  Future<void> cancelAnnouncementById(String id) async {
    await _service.cancelAnnouncementById(id);
    _log('Cancelled announcement: $id');
  }

  /// Get all currently scheduled announcements
  Future<List<ScheduledAnnouncement>> getScheduledAnnouncements() async {
    return await _service.getScheduledAnnouncements();
  }

  /// Stream of announcement status updates
  Stream<AnnouncementStatus> get statusStream => _statusController.stream;

  /// Dispose resources
  Future<void> dispose() async {
    await _statusController.close();
    await _service.dispose();
  }

  /// Calculate the next occurrence based on recurrence pattern
  DateTime _calculateNextOccurrence(
    TimeOfDay time,
    RecurrencePattern? recurrence,
    List<int>? customDays,
    DateTime from,
  ) {
    final now = from;
    final today = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // For one-time announcements
    if (recurrence == null) {
      // If the time today has already passed, schedule for tomorrow
      if (today.isAfter(now)) {
        return today;
      } else {
        return today.add(const Duration(days: 1));
      }
    }

    // For recurring announcements, find the next valid day
    final targetDays = recurrence == RecurrencePattern.custom
        ? (customDays ?? [])
        : recurrence.defaultDays;

    // Start checking from today
    var candidate = today;

    // If today's time has passed, start from tomorrow
    if (candidate.isBefore(now) || candidate.isAtSameMomentAs(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }

    // Find the next day that matches our recurrence pattern
    while (!targetDays.contains(candidate.weekday)) {
      candidate = candidate.add(const Duration(days: 1));
    }

    return candidate;
  }

  /// Log debug information if enabled
  void _log(String message) {
    if (_config.enableDebugLogging) {
      debugPrint('[AnnouncementScheduler] $message');
    }
  }
}
