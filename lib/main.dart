import 'package:day_break/app_controller.dart';
import 'package:day_break/http_client_wrapper.dart';
import 'package:day_break/location_service.dart';
import 'package:day_break/main_screen.dart';
import 'package:day_break/notification_service.dart';
import 'package:day_break/settings_screen.dart';
import 'package:day_break/settings_service.dart';
import 'package:day_break/weather_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  await initServices();
  runApp(const MyApp());
}

Future<void> initServices() async {
  await Get.putAsync(() => SettingsService().init());

  // Initialize HTTP client and wrapper
  final httpClient = http.Client();
  Get.put(httpClient);

  final httpClientWrapper = HttpClientWrapper(httpClient);
  Get.put(httpClientWrapper);

  // Initialize LocationService
  final locationService = LocationService();
  Get.put(locationService);

  // Initialize WeatherService with the wrapper
  final weatherService = WeatherService(httpClientWrapper);
  Get.put(weatherService);

  // Initialize and setup NotificationService
  final notificationService = NotificationService(
    notifications: FlutterLocalNotificationsPlugin(),
    weatherService: weatherService,
    settingsService: Get.find<SettingsService>(),
  );

  await notificationService.initialize();
  Get.put(notificationService);

  // // TODO: remove this
  // final settingService = Get.find<SettingsService>();
  // await settingService.clearSettings();

  // Initialize AppController (this orchestrates all other services)
  final appController = AppController();
  Get.put(appController);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Day Break',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
      home: const MainScreen(),
      getPages: [GetPage(name: '/settings', page: () => const SettingsScreen())],
    );
  }
}
