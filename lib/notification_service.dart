import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_exceptions.dart';
import 'settings_service.dart';
import 'weather_service.dart';

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _notifications;
  FlutterTts? _tts;
  final WeatherService _weatherService;
  final SettingsService _settingsService;

  static const String _channelId = 'weather_announcements';
  static const String _channelName = 'Weather Announcements';
  static const String _channelDescription = 'Daily weather forecast notifications';

  NotificationService({FlutterLocalNotificationsPlugin? notifications, FlutterTts? tts, WeatherService? weatherService, SettingsService? settingsService})
    : _notifications = notifications ?? FlutterLocalNotificationsPlugin(),
      _tts = tts, // Don't initialize here, do it lazily
      _weatherService = weatherService ?? Get.find<WeatherService>(),
      _settingsService = settingsService ?? Get.find<SettingsService>();

  /// Initialize the notification service
  Future<void> initialize() async {
    // Initialize timezone data
    tz.initializeTimeZones();

    // Initialize TTS
    await _initializeTts();

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

  /// Initialize and configure TTS settings
  Future<void> _initializeTts() async {
    try {
      // Initialize TTS lazily if not already done
      _tts ??= FlutterTts();

      // Set language
      await _tts!.setLanguage('en-US');

      // Configure speech parameters
      await _tts!.setSpeechRate(0.5); // Slower for clarity
      await _tts!.setVolume(1.0); // Full volume
      await _tts!.setPitch(0.9); // Normal pitch

      // Wait for speech completion
      await _tts!.awaitSpeakCompletion(true);
    } catch (e) {
      // TTS initialization failure shouldn't prevent notification service from working
      // Log error but continue with visual-only notifications
      Get.log('TTS initialization failed: $e', isError: true);
      _tts = null; // Set to null to indicate TTS is not available
    }
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

  /// Speak weather announcement using TTS
  Future<void> _speakWeatherAnnouncement(String announcement) async {
    try {
      if (_tts != null) {
        await _tts!.speak(announcement);
      }
    } catch (e) {
      // TTS failure shouldn't prevent the notification from showing
      // Log error but continue with visual-only notification
      Get.log('TTS speech failed: $e', isError: true);
    }
  }

  /// Configure TTS speech rate (0.1 to 2.0)
  Future<void> configureSpeechRate(double rate) async {
    try {
      if (_tts != null) {
        // Clamp rate to valid range
        final clampedRate = rate.clamp(0.1, 2.0);
        await _tts!.setSpeechRate(clampedRate);
      }
    } catch (e) {
      Get.log('Failed to set speech rate: $e', isError: true);
    }
  }

  /// Configure TTS pitch (0.1 to 2.0)
  Future<void> configurePitch(double pitch) async {
    try {
      if (_tts != null) {
        // Clamp pitch to valid range
        final clampedPitch = pitch.clamp(0.1, 2.0);
        await _tts!.setPitch(clampedPitch);
      }
    } catch (e) {
      Get.log('Failed to set pitch: $e', isError: true);
    }
  }

  /// Configure TTS volume (0.0 to 1.0)
  Future<void> configureVolume(double volume) async {
    try {
      if (_tts != null) {
        // Clamp volume to valid range
        final clampedVolume = volume.clamp(0.0, 1.0);
        await _tts!.setVolume(clampedVolume);
      }
    } catch (e) {
      Get.log('Failed to set volume: $e', isError: true);
    }
  }

  /// Configure TTS language
  Future<void> configureLanguage(String language) async {
    try {
      if (_tts != null) {
        await _tts!.setLanguage(language);
      }
    } catch (e) {
      Get.log('Failed to set language: $e', isError: true);
    }
  }

  /// Get available TTS languages
  Future<List<dynamic>> getAvailableLanguages() async {
    try {
      if (_tts != null) {
        return await _tts!.getLanguages;
      }
      return [];
    } catch (e) {
      Get.log('Failed to get languages: $e', isError: true);
      return [];
    }
  }

  /// Get available TTS voices
  Future<List<Map<String, String>>> getAvailableVoices() async {
    try {
      if (_tts != null) {
        final voices = await _tts!.getVoices;
        return voices.cast<Map<String, String>>();
      }
      return [];
    } catch (e) {
      Get.log('Failed to get voices: $e', isError: true);
      return [];
    }
  }

  /// Set TTS voice
  Future<void> configureVoice(Map<String, String> voice) async {
    try {
      if (_tts != null) {
        await _tts!.setVoice(voice);
      }
    } catch (e) {
      Get.log('Failed to set voice: $e', isError: true);
    }
  }

  /// Test TTS with a sample announcement
  Future<void> testTtsAnnouncement() async {
    const testMessage = 'This is a test of the text-to-speech functionality. The current weather is partly cloudy with a temperature of 72 degrees Fahrenheit.';
    await _speakWeatherAnnouncement(testMessage);
  }

  /// Stop current TTS speech
  Future<void> stopSpeech() async {
    try {
      if (_tts != null) {
        await _tts!.stop();
      }
    } catch (e) {
      Get.log('Failed to stop speech: $e', isError: true);
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

  final _weatherEmojis = <String, String>{
    'clear': '☀️',
    'sunny': '☀️',
    'partly cloudy': '⛅',
    'cloudy': '☁️',
    'overcast': '🌥️',
    'rain': '🌧️',
    'showers': '🌦️',
    'thunderstorm': '⛈️',
    'snow': '❄️',
    'fog': '🌫️',
    'mist': '🌫️',
    'windy': '💨',
    'hail': '🌨️',
    'drizzle': '🌦️',
  };

  /// Show immediate weather notification with current weather data
  Future<void> showWeatherNotification(Position position) async {
    try {
      String title;
      String body;

      try {
        final weather = await _weatherService.getWeather(position);
        final emoji = _weatherEmojis[weather.description.toLowerCase()] ?? '🌤️';
        title = 'Weather Update $emoji - ${weather.tempMin}/${weather.tempMax}°C';
        body = weather.formattedAnnouncement;

        // Speak the weather announcement
        await _speakWeatherAnnouncement(weather.formattedAnnouncement);
      } catch (e) {
        // Show error notification if weather API fails
        title = 'Weather Service Unavailable 📵';
        body = 'Unable to fetch current weather data. Please check your internet connection and try again later.';

        // Speak the error message
        await _speakWeatherAnnouncement(body);
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
        // Map weather descriptions to emojis

        // Get emoji for current weather description, fallback to default
        final emoji = _weatherEmojis[weather.description.toLowerCase()] ?? '🌤️';

        title = 'Weather Update $emoji - ${weather.tempMin}/${weather.tempMax}°C';
        body = weather.formattedAnnouncement;

        // Speak the weather announcement
        await _speakWeatherAnnouncement(weather.formattedAnnouncement);
      } catch (e) {
        // Show error notification if weather API fails
        title = 'Weather Service Unavailable 📵';
        body = 'Unable to fetch weather data for $locationName. Please check your internet connection and try again later.';

        // Speak the error message
        await _speakWeatherAnnouncement(body);
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
