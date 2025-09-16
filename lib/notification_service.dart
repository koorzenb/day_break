import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_exceptions.dart';
import 'settings_service.dart';
import 'weather_service.dart';

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _notifications;
  final WeatherService _weatherService;
  final SettingsService _settingsService;

  static const String _channelId = 'weather_announcements';
  static const String _channelName = 'Weather Announcements';
  static const String _channelDescription = 'Daily weather forecast notifications';

  NotificationService({FlutterLocalNotificationsPlugin? notifications, WeatherService? weatherService, SettingsService? settingsService})
    : _notifications = notifications ?? FlutterLocalNotificationsPlugin(),
      _weatherService = weatherService ?? Get.find<WeatherService>(),
      _settingsService = settingsService ?? Get.find<SettingsService>();

  /// Initialize the notification service
  Future<void> initialize() async {
    // Initialize timezone data
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    final initialized = await _notifications.initialize(initSettings, onDidReceiveNotificationResponse: _onNotificationResponse);

    if (initialized != true) {
      throw const NotificationInitializationException('Failed to initialize notifications');
    }

    // Request permissions for Android 13+
    await _requestPermissions();

    // Create notification channel for Android
    await _createNotificationChannel();
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      if (granted != true) {
        throw const NotificationPermissionDeniedException();
      }
    }
  }

  /// Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.defaultImportance,
      showBadge: true,
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
    }
  }

  /// Schedule daily weather notification
  Future<void> scheduleDailyWeatherNotification() async {
    try {
      // Cancel any existing notifications
      await cancelAllNotifications();

      // Get announcement time from settings
      final hour = _settingsService.announcementHour;
      final minute = _settingsService.announcementMinute;

      if (hour == null || minute == null) {
        throw const NotificationSchedulingException('Announcement time not set in settings');
      }

      // Schedule for next occurrence of the time
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

      // If the scheduled time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        0, // notification id
        'Good Morning! ☀️',
        'Fetching your daily weather update...',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
        ),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
        payload: 'daily_weather',
      );
    } catch (e) {
      if (e is NotificationException) {
        rethrow;
      }
      throw NotificationSchedulingException('Failed to schedule notification: $e');
    }
  }

  /// Show immediate weather notification with current weather data
  Future<void> showWeatherNotification(Position position) async {
    try {
      String title;
      String body;

      try {
        final weather = await _weatherService.getWeather(position);
        title = 'Weather Update 🌤️';
        body = weather.formattedAnnouncement;
      } catch (e) {
        // Show error notification if weather API fails
        title = 'Weather Service Unavailable 📵';
        body = 'Unable to fetch current weather data. Please check your internet connection and try again later.';
      }

      await _notifications.show(
        1, // notification id
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
        ),
        payload: 'weather_update',
      );
    } catch (e) {
      if (e is NotificationException) {
        // TODO: check codebase if all rethrow are handled properly
        rethrow;
      }
      throw NotificationSchedulingException('Failed to show weather notification: $e');
    }
  }

  /// Show immediate weather notification using location name
  Future<void> showWeatherNotificationByLocation(String locationName) async {
    try {
      String title;
      String body;

      try {
        final weather = await _weatherService.getWeatherByLocation(locationName);
        title = 'Weather Update 🌤️';
        body = weather.formattedAnnouncement;
      } catch (e) {
        // Show error notification if weather API fails
        title = 'Weather Service Unavailable 📵';
        body = 'Unable to fetch weather data for $locationName. Please check your internet connection and try again later.';
      }

      await _notifications.show(
        1, // notification id
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
        ),
        payload: 'weather_update',
      );
    } catch (e) {
      if (e is NotificationException) {
        rethrow;
      }
      throw NotificationSchedulingException('Failed to show weather notification: $e');
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Cancel specific notification by id
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Get list of pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return _notifications.pendingNotificationRequests();
  }

  /// Handle notification response when user taps notification
  void _onNotificationResponse(NotificationResponse response) {
    switch (response.payload) {
      case 'daily_weather':
        // Handle daily weather notification tap
        // Could navigate to weather details screen
        break;
      case 'weather_update':
        // Handle weather update notification tap
        break;
      default:
        break;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }

    return true; // Assume enabled on other platforms
  }
}
