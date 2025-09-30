import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/notification_exceptions.dart';
import 'settings_service.dart';
import 'weather_service.dart';

class NotificationService extends GetxService {
  static const String _channelId = 'weather_announcements';
  static const String _channelName = 'Weather Announcements';
  static const String _channelDescription = 'Daily weather forecast notifications';
  static Duration testNotificationDelay = Duration(seconds: 60);
  final FlutterLocalNotificationsPlugin _notifications;
  FlutterTts? _tts;
  final WeatherService _weatherService;
  final SettingsService _settingsService;
  bool _exactAlarmsAllowed = false;
  bool _notificationAllowed = false;
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

  NotificationService({FlutterLocalNotificationsPlugin? notifications, FlutterTts? tts, WeatherService? weatherService, SettingsService? settingsService})
    : _notifications = notifications ?? FlutterLocalNotificationsPlugin(),
      _tts = tts, // Don't initialize here, do it lazily
      _weatherService = weatherService ?? Get.find<WeatherService>(),
      _settingsService = settingsService ?? Get.find<SettingsService>();

  /// Get whether both notification permissions and exact alarms are allowed
  bool get isNotificationsAllowed => _exactAlarmsAllowed && _notificationAllowed;

  /// Initialize the notification service
  Future<void> initialize() async {
    // Initialize timezone data
    tz.initializeTimeZones();

    await _initializeTts();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    final initialized = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    if (initialized != true) {
      throw const NotificationInitializationException('Failed to initialize notifications');
    }

    // Request permissions for Android 13+
    await _requestPermissions();

    // Create notification channel for Android
    await _createNotificationChannel();
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

  /// Speak weather announcement for test notification using configured location
  Future<void> speakTestWeatherAnnouncement() async {
    try {
      final location = _settingsService.location;
      if (location == null || location.isEmpty) {
        await _speakWeatherAnnouncement('Test notification delivered. No location configured for weather announcement.');
        return;
      }

      // Fetch and speak actual weather data
      final weather = await _weatherService.getWeatherByLocation(location);
      await _speakWeatherAnnouncement(weather.formattedAnnouncement);
    } catch (e) {
      // Fallback TTS message if weather fetch fails
      await _speakWeatherAnnouncement('Test notification delivered. Weather data is currently unavailable.');
    }
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

  /// Schedule a notification for testing purposes with real weather data
  Future<void> scheduleTestNotification(int delaySeconds) async {
    try {
      await cancelNotification(9999);
      String? location = await _validateNotificationAndLocation();

      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('America/Halifax'));

      testNotificationDelay = Duration(seconds: delaySeconds);

      final now = tz.TZDateTime.now(tz.local);
      final scheduledDate = now.add(testNotificationDelay);

      String speechText = 'This is a test notification. Fetching weather data.';
      try {
        final weather = await _weatherService.getWeatherByLocation(location);
        speechText = weather.formattedAnnouncement;
      } catch (e) {
        speechText = 'This is a test notification. Weather data is currently unavailable.';
      }

      // Schedule the test notification with weather data
      await _scheduleWeatherNotification(
        notificationId: 9999,
        scheduledDate: scheduledDate,
        location: location,
        defaultTitle: 'Test Weather Notification ⏰',
        defaultBody: 'Fetching weather data for $location...',
        fallbackBodyTemplate:
            'Test notification scheduled for ${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}:${scheduledDate.second.toString().padLeft(2, '0')} - Weather data unavailable',
        logContext: 'test notification',
        speechText: speechText,
        payloadPrefix: 'test_weather_with_speech',
        androidDetails: const AndroidNotificationDetails(
          'weather_announcements',
          'Weather Announcements',
          channelDescription: 'Daily weather forecast notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      );

      // Provide immediate TTS demonstration
      await _speakWeatherAnnouncement('Test notification scheduled successfully');

      // Schedule automatic speech to play when the notification appears
      Timer(testNotificationDelay, () {
        _speakWeatherAnnouncement(speechText);
        Get.log('[NotificationService] Automatic TTS triggered for test notification', isError: false);
      });

      Get.log('[NotificationService] Test notification scheduled successfully with weather data and automatic TTS.', isError: false);
    } catch (e) {
      Get.log('[NotificationService] Error scheduling test notification: $e', isError: true);
      if (e is NotificationException) {
        rethrow;
      }
      throw NotificationSchedulingException('Failed to schedule test notification: $e');
    }
  }

  /// Schedule daily weather notification
  Future<void> scheduleDailyWeatherNotification() async {
    try {
      await cancelAllNotifications();
      String? location = await _validateNotificationAndLocation();

      final hour = _settingsService.announcementHour;
      final minute = _settingsService.announcementMinute;

      if (hour == null || minute == null) {
        Get.log('[NotificationService] Announcement time not set in settings.', isError: true);
        throw const NotificationSchedulingException('Announcement time not set in settings');
      }

      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('America/Halifax'));

      // Schedule for next occurrence of the time
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      Duration notificationDelay = scheduledDate.difference(now);

      // If the scheduled time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
        notificationDelay = scheduledDate.difference(now);
        Get.log('[NotificationService] Scheduled time already passed, rescheduling for tomorrow: $scheduledDate', isError: false);
      }

      // Prepare speech text for daily notification
      String speechText = 'Good morning! Fetching your daily weather update.';
      try {
        final weather = await _weatherService.getWeatherByLocation(location);
        speechText = 'Good morning! ${weather.formattedAnnouncement}';
      } catch (e) {
        speechText = 'Good morning! Daily weather update is ready. Weather data will be announced when you interact with the notification.';
      }

      await _scheduleWeatherNotification(
        notificationId: 0,
        scheduledDate: scheduledDate,
        location: location,
        defaultTitle: 'Good Morning! ☀️',
        defaultBody: 'Fetching your daily weather update for $location...',
        fallbackBodyTemplate: 'Daily weather update for \$location - Weather data will be available when you open the notification.',
        logContext: 'daily notification',
        speechText: speechText,
        payloadPrefix: 'daily_weather_with_speech',
        androidDetails: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        scheduleMode: _exactAlarmsAllowed ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      Timer(notificationDelay, () {
        _speakWeatherAnnouncement("Good morning, Bahrint. I'm prepping your weather update while you ${_getFunnyClip()} ");
      });

      final extendedDelay = notificationDelay + const Duration(seconds: 10);

      Timer(extendedDelay, () {
        _speakWeatherAnnouncement(speechText);
        Get.log('[NotificationService] Automatic TTS triggered for test notification', isError: false);
      });

      Get.log('[NotificationService] zonedSchedule called successfully.', isError: false);
      Get.log(
        '[NotificationService] Scheduled for ${scheduledDate.difference(now).inMinutes} minutes and ${scheduledDate.difference(now).inSeconds.remainder(60)} seconds in the future.',
      );
    } catch (e) {
      Get.log('[NotificationService] Error scheduling notification: $e', isError: true);
      if (e is NotificationException) {
        rethrow;
      }
      throw NotificationSchedulingException('Failed to schedule notification: $e');
    }
  }

  Future<String> _validateNotificationAndLocation() async {
    // Verify notifications are enabled
    final notificationsEnabled = await areNotificationsEnabled();
    if (!notificationsEnabled) {
      throw const NotificationSchedulingException('Notifications are disabled. Please enable them in device settings.');
    }

    // Get location from settings for weather data
    final location = _settingsService.location;
    if (location == null || location.isEmpty) {
      throw const NotificationSchedulingException('No location set in settings. Please configure your location first.');
    }
    return location;
  }

  /// Fetch weather data, prepare notification content, and schedule the notification
  Future<void> _scheduleWeatherNotification({
    required int notificationId,
    required tz.TZDateTime scheduledDate,
    required String location,
    required String defaultTitle,
    required String defaultBody,
    required String fallbackBodyTemplate,
    required String logContext,
    required String speechText,
    required String payloadPrefix,
    required AndroidNotificationDetails androidDetails,
    AndroidScheduleMode? scheduleMode,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    String title = defaultTitle;
    String body = defaultBody;

    try {
      final weather = await _weatherService.getWeatherByLocation(location);
      final emoji = _weatherEmojis[weather.description.toLowerCase()] ?? '🌤️';
      title = '${defaultTitle.replaceFirst('☀️', emoji).replaceFirst('⏰', emoji)} ${weather.tempMin.round()}/${weather.tempMax.round()}°C';
      body = weather.formattedAnnouncement;

      Get.log('[NotificationService] Weather data fetched successfully for $logContext', isError: false);
    } catch (e) {
      Get.log('[NotificationService] Failed to fetch weather for $logContext, using fallback: $e', isError: false);
      body = fallbackBodyTemplate.replaceAll('\$location', location);
    }

    // Schedule the notification
    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true)),
      androidScheduleMode: scheduleMode ?? AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: matchDateTimeComponents,
      payload: '$payloadPrefix:$speechText',
    );
  }

  String _getFunnyClip() {
    final clips = [
      'enjoy your coffee',
      'pump some iron',
      'seize the day',
      'embrace the sunshine',
      'are serving your kids. Did I say "serving"? I meant to say "slaving over breakfast"',
      'take on the world',
      'rise and shine',
      'conquer the dishes',
    ];
    clips.shuffle();
    return clips.first;
  }

  /// Show immediate weather notification with current weather data
  Future<void> showWeatherNotification(Position position) async {
    try {
      String title;
      String body;

      try {
        final weather = await _weatherService.getWeather(position);
        final emoji = _weatherEmojis[weather.description.toLowerCase()] ?? '🌤️';
        title = 'Weather Update $emoji ${weather.tempMin.round()}/${weather.tempMax.round()}°C';
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

        title = 'Weather Update $emoji ${weather.tempMin.round()}/${weather.tempMax.round()}°C';
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
      _notificationAllowed = granted ?? false;
      // Don't make permission denial fatal – allow app to continue without notifications
      if (!_notificationAllowed) {
        Get.log('Notification permission denied by user. Continuing without scheduled notifications.', isError: true);
        return; // Early return; caller can decide whether to schedule later
      }

      // Request exact alarm permission for Android 12+ (API level 31+) on real devices only
      final exactAlarmGranted = await androidPlugin.requestExactAlarmsPermission();
      if (exactAlarmGranted == true) {
        _exactAlarmsAllowed = true;
        Get.log('[NotificationService] Exact alarm permission granted - notifications will use precise timing');
      } else {
        _exactAlarmsAllowed = false;
        Get.log('Exact alarm permission denied. Will use inexact scheduling.', isError: false);
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

  /// Handle notification response when user taps notification
  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload ?? '';

    if (payload.startsWith('test_weather_with_speech:')) {
      // Extract speech text and play it for test notifications
      final speechText = payload.substring('test_weather_with_speech:'.length);
      _speakWeatherAnnouncement(speechText);
      Get.log('[NotificationService] Test notification delivered with speech: $speechText', isError: false);
    } else if (payload.startsWith('daily_weather_with_speech:')) {
      // Extract speech text and play it for daily notifications
      final speechText = payload.substring('daily_weather_with_speech:'.length);
      _speakWeatherAnnouncement(speechText);
      Get.log('[NotificationService] Daily weather notification delivered with speech: $speechText', isError: false);
    } else {
      switch (payload) {
        case 'daily_weather':
          // Legacy daily weather notification (without speech)
          Get.log('[NotificationService] Legacy daily weather notification tapped', isError: false);
          break;
        case 'weather_update':
          // Handle weather update notification tap
          break;
        default:
          Get.log('Unknown notification payload: $payload', isError: false);
          break;
      }
    }
  }

  /// Handle background notification response (static method required)
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    // Note: Get.log won't work in background context, so we use print for debugging
    final payload = response.payload ?? '';
    print('[NotificationService] Background notification received: payload=$payload');

    if (payload.startsWith('test_weather_with_speech:')) {
      print('[NotificationService] Background test notification - speech would be triggered when app opens');
      // Note: TTS cannot be triggered from background context, but this logs the intent
    } else if (payload.startsWith('daily_weather_with_speech:')) {
      print('[NotificationService] Background daily weather notification - speech would be triggered when app opens');
      // Note: TTS cannot be triggered from background context, but this logs the intent
    } else {
      // Handle background notification processing here
      // This is called when the app is not running and user taps notification
      switch (payload) {
        case 'daily_weather':
          print('[NotificationService] Background daily weather notification (legacy) tapped');
          // Could trigger weather fetch and display when app launches
          break;
        case 'weather_update':
          print('[NotificationService] Background weather update notification tapped');
          break;
        default:
          print('[NotificationService] Unknown background notification payload: $payload');
          break;
      }
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
