import 'package:day_break/notification_exceptions.dart';
import 'package:day_break/notification_service.dart';
import 'package:day_break/settings_service.dart';
import 'package:day_break/weather_service.dart';
import 'package:day_break/weather_summary.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'notification_service_test.mocks.dart';

@GenerateMocks([FlutterLocalNotificationsPlugin, WeatherService, SettingsService, AndroidFlutterLocalNotificationsPlugin])
void main() {
  group('NotificationService', () {
    late NotificationService notificationService;
    late MockFlutterLocalNotificationsPlugin mockNotifications;
    late MockWeatherService mockWeatherService;
    late MockSettingsService mockSettingsService;
    late MockAndroidFlutterLocalNotificationsPlugin mockAndroidPlugin;
    late Position testPosition;

    setUpAll(() {
      // Initialize timezone data for tests
      tz.initializeTimeZones();
    });

    setUp(() {
      mockNotifications = MockFlutterLocalNotificationsPlugin();
      mockWeatherService = MockWeatherService();
      mockSettingsService = MockSettingsService();
      mockAndroidPlugin = MockAndroidFlutterLocalNotificationsPlugin();

      notificationService = NotificationService(notifications: mockNotifications, weatherService: mockWeatherService, settingsService: mockSettingsService);

      testPosition = Position(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    });

    group('initialize', () {
      test('should initialize notifications successfully', () async {
        // Arrange
        when(mockNotifications.initialize(any, onDidReceiveNotificationResponse: anyNamed('onDidReceiveNotificationResponse'))).thenAnswer((_) async => true);
        when(mockNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()).thenReturn(mockAndroidPlugin);
        when(mockAndroidPlugin.requestNotificationsPermission()).thenAnswer((_) async => true);
        when(mockAndroidPlugin.createNotificationChannel(any)).thenAnswer((_) async {});

        // Act
        await notificationService.initialize();

        // Assert
        verify(mockNotifications.initialize(any, onDidReceiveNotificationResponse: anyNamed('onDidReceiveNotificationResponse'))).called(1);
        verify(mockAndroidPlugin.requestNotificationsPermission()).called(1);
        verify(mockAndroidPlugin.createNotificationChannel(any)).called(1);
      });

      test('should throw NotificationInitializationException when initialization fails', () async {
        // Arrange
        when(mockNotifications.initialize(any, onDidReceiveNotificationResponse: anyNamed('onDidReceiveNotificationResponse'))).thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => notificationService.initialize(),
          throwsA(isA<NotificationInitializationException>()),
          reason: 'Should throw NotificationInitializationException when initialization fails',
        );
      });

      test('should continue initialization when permission denied (non-fatal)', () async {
        // Arrange
        when(mockNotifications.initialize(any, onDidReceiveNotificationResponse: anyNamed('onDidReceiveNotificationResponse'))).thenAnswer((_) async => true);
        when(mockNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()).thenReturn(mockAndroidPlugin);
        when(mockAndroidPlugin.requestNotificationsPermission()).thenAnswer((_) async => false);

        // Act (should not throw)
        await notificationService.initialize();

        // Assert
        verify(mockAndroidPlugin.requestNotificationsPermission()).called(1);
      });
    });

    group('scheduleDailyWeatherNotification', () {
      setUp(() {
        when(mockSettingsService.announcementHour).thenReturn(8);
        when(mockSettingsService.announcementMinute).thenReturn(0);
        when(mockNotifications.cancelAll()).thenAnswer((_) async {});
        when(
          mockNotifications.zonedSchedule(
            any,
            any,
            any,
            any,
            any,
            uiLocalNotificationDateInterpretation: anyNamed('uiLocalNotificationDateInterpretation'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).thenAnswer((_) async {});
      });

      test('should schedule daily notification successfully', () async {
        // Act
        await notificationService.scheduleDailyWeatherNotification();

        // Assert
        verify(mockNotifications.cancelAll()).called(1);
        verify(
          mockNotifications.zonedSchedule(
            0,
            'Good Morning! ☀️',
            'Fetching your daily weather update...',
            any,
            any,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: 'daily_weather',
          ),
        ).called(1);
      });

      test('should throw NotificationSchedulingException when announcement time not set', () async {
        // Arrange
        when(mockSettingsService.announcementHour).thenReturn(null);
        when(mockSettingsService.announcementMinute).thenReturn(null);

        // Act & Assert
        expect(
          () => notificationService.scheduleDailyWeatherNotification(),
          throwsA(isA<NotificationSchedulingException>().having((e) => e.message, 'message', contains('Announcement time not set'))),
          reason: 'Should throw NotificationSchedulingException when time not set',
        );
      });

      test('should handle scheduling errors gracefully', () async {
        // Arrange
        when(
          mockNotifications.zonedSchedule(
            any,
            any,
            any,
            any,
            any,
            uiLocalNotificationDateInterpretation: anyNamed('uiLocalNotificationDateInterpretation'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).thenThrow(Exception('Scheduling failed'));

        // Act & Assert
        expect(
          () => notificationService.scheduleDailyWeatherNotification(),
          throwsA(isA<NotificationSchedulingException>()),
          reason: 'Should wrap scheduling errors in NotificationSchedulingException',
        );
      });
    });

    group('showWeatherNotification', () {
      late WeatherSummary testWeather;

      setUp(() {
        testWeather = WeatherSummary(
          description: 'clear sky',
          temperature: 22.5,
          feelsLike: 24.0,
          tempMin: 18.0,
          tempMax: 25.0,
          humidity: 65,
          location: 'San Francisco',
          timestamp: DateTime.now(),
        );

        when(mockNotifications.show(any, any, any, any, payload: anyNamed('payload'))).thenAnswer((_) async {});
      });

      test('should show weather notification with API data', () async {
        // Arrange
        when(mockWeatherService.getWeather(testPosition)).thenAnswer((_) async => testWeather);

        // Act
        await notificationService.showWeatherNotification(testPosition);

        // Assert
        verify(mockWeatherService.getWeather(testPosition)).called(1);
        verify(mockNotifications.show(1, 'Weather Update 🌤️ - 18.0/25.0°C', testWeather.formattedAnnouncement, any, payload: 'weather_update')).called(1);
      });

      test('should show error notification when API fails', () async {
        // Arrange
        when(mockWeatherService.getWeather(testPosition)).thenThrow(Exception('API error'));

        // Act
        await notificationService.showWeatherNotification(testPosition);

        // Assert
        verify(mockWeatherService.getWeather(testPosition)).called(1);
        verify(
          mockNotifications.show(
            1,
            'Weather Service Unavailable 📵',
            'Unable to fetch current weather data. Please check your internet connection and try again later.',
            any,
            payload: 'weather_update',
          ),
        ).called(1);
      });

      test('should handle notification display errors', () async {
        // Arrange
        when(mockWeatherService.getWeather(testPosition)).thenAnswer((_) async => testWeather);
        when(mockNotifications.show(any, any, any, any, payload: anyNamed('payload'))).thenThrow(Exception('Display failed'));

        // Act & Assert
        expect(
          () => notificationService.showWeatherNotification(testPosition),
          throwsA(isA<NotificationSchedulingException>()),
          reason: 'Should wrap display errors in NotificationSchedulingException',
        );
      });
    });

    group('notification management', () {
      test('should cancel all notifications', () async {
        // Arrange
        when(mockNotifications.cancelAll()).thenAnswer((_) async {});

        // Act
        await notificationService.cancelAllNotifications();

        // Assert
        verify(mockNotifications.cancelAll()).called(1);
      });

      test('should cancel specific notification', () async {
        // Arrange
        when(mockNotifications.cancel(any)).thenAnswer((_) async {});

        // Act
        await notificationService.cancelNotification(1);

        // Assert
        verify(mockNotifications.cancel(1)).called(1);
      });

      test('should get pending notifications', () async {
        // Arrange
        final pendingNotifications = <PendingNotificationRequest>[const PendingNotificationRequest(0, 'Test', 'Body', 'payload')];
        when(mockNotifications.pendingNotificationRequests()).thenAnswer((_) async => pendingNotifications);

        // Act
        final result = await notificationService.getPendingNotifications();

        // Assert
        expect(result, equals(pendingNotifications), reason: 'Should return pending notifications from plugin');
        verify(mockNotifications.pendingNotificationRequests()).called(1);
      });
    });

    group('areNotificationsEnabled', () {
      test('should return true when notifications are enabled on Android', () async {
        // Arrange
        when(mockNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()).thenReturn(mockAndroidPlugin);
        when(mockAndroidPlugin.areNotificationsEnabled()).thenAnswer((_) async => true);

        // Act
        final result = await notificationService.areNotificationsEnabled();

        // Assert
        expect(result, isTrue, reason: 'Should return true when Android notifications enabled');
      });

      test('should return false when notifications are disabled on Android', () async {
        // Arrange
        when(mockNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()).thenReturn(mockAndroidPlugin);
        when(mockAndroidPlugin.areNotificationsEnabled()).thenAnswer((_) async => false);

        // Act
        final result = await notificationService.areNotificationsEnabled();

        // Assert
        expect(result, isFalse, reason: 'Should return false when Android notifications disabled');
      });

      test('should return true when Android plugin is not available', () async {
        // Arrange
        when(mockNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()).thenReturn(null);

        // Act
        final result = await notificationService.areNotificationsEnabled();

        // Assert
        expect(result, isTrue, reason: 'Should assume enabled when Android plugin not available');
      });
    });
  });
}
