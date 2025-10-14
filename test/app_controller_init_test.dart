import 'package:day_break/controllers/app_controller.dart';
import 'package:day_break/http_client_wrapper.dart';
import 'package:day_break/models/recurrence_pattern.dart';
import 'package:day_break/services/notification_service.dart';
import 'package:day_break/services/settings_service.dart';
import 'package:day_break/services/weather_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

// Simple fake implementations to avoid code generation
class FakeSettingsService extends SettingsService {
  @override
  String? get location => 'Berlin';
  @override
  int? get announcementHour => 7;
  @override
  int? get announcementMinute => 30;
}

// Minimal fake WeatherService to satisfy NotificationService dependency without network
class FakeWeatherService extends WeatherService {
  FakeWeatherService() : super(HttpClientWrapper());
}

class FailingNotificationService extends NotificationService {
  FailingNotificationService({
    required SettingsService settingsService,
    required WeatherService weatherService,
  }) : super(weatherService: weatherService, settingsService: settingsService);

  @override
  Future<void> scheduleDailyWeatherNotification({
    List<int>? customDays,
    bool? isRecurring,
    RecurrencePattern? recurrencePattern,
  }) async => throw Exception('perm denied');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  test(
    'AppController releases loading state even if notification service throws',
    () async {
      final settings = FakeSettingsService();
      final weather = FakeWeatherService();
      Get.put<SettingsService>(settings);
      Get.put<WeatherService>(weather);
      Get.put<NotificationService>(
        FailingNotificationService(
          settingsService: settings,
          weatherService: weather,
        ),
      );

      final controller = AppController();
      Get.put(controller);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        controller.isInitialized,
        isTrue,
        reason: 'Controller should set isInitialized true even on error',
      );
      expect(
        controller.currentStatus.isNotEmpty,
        isTrue,
        reason: 'Status should reflect limited mode/error',
      );
    },
  );
}
