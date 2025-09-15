import 'package:day_break/http_client_wrapper.dart';
import 'package:day_break/notification_service.dart';
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

  // Initialize HTTP client wrapper
  Get.put(HttpClientWrapper(Get.put(http.Client())));

  // Initialize WeatherService
  Get.put(WeatherService(Get.find()));

  // Initialize and setup NotificationService
  final notificationService = NotificationService(notifications: FlutterLocalNotificationsPlugin(), weatherService: Get.find(), settingsService: Get.find());

  await notificationService.initialize();
  Get.put(notificationService);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text(widget.title)),
      body: const Center(child: Center(child: Text('Add something...'))),
    );
  }
}
