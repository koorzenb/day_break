import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'controllers/app_controller.dart';
import 'http_client_wrapper.dart';
import 'screens/main_screen.dart';
import 'screens/settings_screen.dart';
import 'services/background_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'services/weather_service.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  // Create the notification channel before initializing the background service
  const androidChannel = AndroidNotificationChannel(
    'weather_announcements', // id
    'Weather Announcements', // title
    description: 'Daily weather forecast notifications', // description
    importance: Importance.high,
  );

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
    androidChannel,
  );

  await initializeBackgroundService();
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

  // continue with AI assisted debugging. Remeber to use context7

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
  final settingService = Get.find<SettingsService>();
  await settingService.clearSettings();

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
      enableLog: true,
      logWriterCallback: (text, {isError = false}) {
        // Print all Get.log messages to the debug console
        if (isError) {
          print('ERROR: $text');
        } else {
          print(text);
        }
      },
    );
  }
}
