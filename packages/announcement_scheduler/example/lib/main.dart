import 'package:flutter/material.dart';

import 'pages/example_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AnnouncementSchedulerExample());
}

class AnnouncementSchedulerExample extends StatelessWidget {
  const AnnouncementSchedulerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Announcement Scheduler Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const ExampleHomePage(),
    );
  }
}
