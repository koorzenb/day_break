import 'package:day_break/controllers/app_controller.dart';
import 'package:day_break/http_client_wrapper.dart';
import 'package:day_break/models/recurrence_pattern.dart';
import 'package:day_break/services/notification_service.dart';
import 'package:day_break/services/settings_service.dart';
import 'package:day_break/services/weather_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest.dart' as tz_data;

// Mock SettingsService for testing different configurations
class MockSettingsService extends SettingsService {
  int? _announcementHour;
  int? _announcementMinute;
  bool _isRecurring;
  RecurrencePattern _recurrencePattern;
  List<int> _recurrenceDays;

  MockSettingsService({int? hour, int? minute, bool isRecurring = false, RecurrencePattern pattern = RecurrencePattern.daily, List<int>? customDays})
    : _announcementHour = hour,
      _announcementMinute = minute,
      _isRecurring = isRecurring,
      _recurrencePattern = pattern,
      _recurrenceDays = customDays ?? pattern.defaultDays;

  @override
  int? get announcementHour => _announcementHour;

  @override
  int? get announcementMinute => _announcementMinute;

  @override
  bool get isRecurring => _isRecurring;

  @override
  RecurrencePattern get recurrencePattern => _recurrencePattern;

  @override
  List<int> get recurrenceDays => _recurrenceDays;

  @override
  String? get location => 'Halifax'; // Required for controller init

  // Setters for testing
  void setTime(int? hour, int? minute) {
    _announcementHour = hour;
    _announcementMinute = minute;
  }

  void setRecurringConfigForTest(bool recurring, RecurrencePattern pattern, List<int>? days) {
    _isRecurring = recurring;
    _recurrencePattern = pattern;
    _recurrenceDays = days ?? pattern.defaultDays;
  }
}

// Minimal mock services
class MockWeatherService extends WeatherService {
  MockWeatherService() : super(HttpClientWrapper());
}

class MockNotificationService extends NotificationService {
  MockNotificationService({required SettingsService settingsService, required WeatherService weatherService})
    : super(weatherService: weatherService, settingsService: settingsService);

  @override
  Future<void> scheduleDailyWeatherNotification({List<int>? customDays, bool? isRecurring, RecurrencePattern? recurrencePattern}) async {
    // Mock implementation - just return success
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Initialize timezone data
    tz_data.initializeTimeZones();
  });

  setUp(() {
    Get.reset();
  });

  group('AppController Status Display Tests', () {
    test('Shows status message for single notification', () async {
      final mockSettings = MockSettingsService(hour: 7, minute: 30, isRecurring: false);
      final mockWeather = MockWeatherService();
      final mockNotification = MockNotificationService(settingsService: mockSettings, weatherService: mockWeather);

      Get.put<SettingsService>(mockSettings);
      Get.put<WeatherService>(mockWeather);
      Get.put<NotificationService>(mockNotification);

      final controller = AppController();
      Get.put(controller);

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final status = controller.currentStatus;
      expect(status, isNotEmpty, reason: 'Should generate a status message');
      expect(status, contains('7:30'), reason: 'Should show the scheduled time');
      expect(status, isNot(contains('recurring')), reason: 'Should not mention recurring for single notifications');
    });

    test('Shows status message for recurring daily notifications', () async {
      final mockSettings = MockSettingsService(hour: 8, minute: 45, isRecurring: true, pattern: RecurrencePattern.daily);
      final mockWeather = MockWeatherService();
      final mockNotification = MockNotificationService(settingsService: mockSettings, weatherService: mockWeather);

      Get.put<SettingsService>(mockSettings);
      Get.put<WeatherService>(mockWeather);
      Get.put<NotificationService>(mockNotification);

      final controller = AppController();
      Get.put(controller);

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final status = controller.currentStatus;
      expect(status, contains('recurring'), reason: 'Should indicate recurring notifications');
      expect(status, contains('Daily'), reason: 'Should show the recurrence pattern');
      expect(status, contains('8:45'), reason: 'Should show the scheduled time');
    });

    test('Shows status message for recurring weekdays notifications', () async {
      final mockSettings = MockSettingsService(hour: 6, minute: 0, isRecurring: true, pattern: RecurrencePattern.weekdays);
      final mockWeather = MockWeatherService();
      final mockNotification = MockNotificationService(settingsService: mockSettings, weatherService: mockWeather);

      Get.put<SettingsService>(mockSettings);
      Get.put<WeatherService>(mockWeather);
      Get.put<NotificationService>(mockNotification);

      final controller = AppController();
      Get.put(controller);

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final status = controller.currentStatus;
      expect(status, contains('recurring'), reason: 'Should indicate recurring notifications');
      expect(status, contains('Weekdays'), reason: 'Should show the weekdays pattern');
      expect(status, contains('6:00'), reason: 'Should show the scheduled time');
    });

    test('Shows ready status when announcement time not configured', () async {
      final mockSettings = MockSettingsService(); // No hour/minute set
      final mockWeather = MockWeatherService();
      final mockNotification = MockNotificationService(settingsService: mockSettings, weatherService: mockWeather);

      Get.put<SettingsService>(mockSettings);
      Get.put<WeatherService>(mockWeather);
      Get.put<NotificationService>(mockNotification);

      final controller = AppController();
      Get.put(controller);

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final status = controller.currentStatus;
      expect(status, equals('Ready'), reason: 'Should show Ready when settings are incomplete');
    });

    test('Shows status for custom recurring pattern', () async {
      final customDays = [1, 3, 5]; // Monday, Wednesday, Friday
      final mockSettings = MockSettingsService(hour: 9, minute: 30, isRecurring: true, pattern: RecurrencePattern.custom, customDays: customDays);
      final mockWeather = MockWeatherService();
      final mockNotification = MockNotificationService(settingsService: mockSettings, weatherService: mockWeather);

      Get.put<SettingsService>(mockSettings);
      Get.put<WeatherService>(mockWeather);
      Get.put<NotificationService>(mockNotification);

      final controller = AppController();
      Get.put(controller);

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final status = controller.currentStatus;
      expect(status, contains('recurring'), reason: 'Should indicate recurring notifications');
      expect(status, contains('Custom'), reason: 'Should show custom pattern');
      expect(status, contains('9:30'), reason: 'Should show the scheduled time');
    });
  });
}
