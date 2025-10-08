import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/settings_controller.dart';
import '../models/recurrence_pattern.dart';

// Part files for organized settings screen sections
part 'settings_screen/header_section.dart';
part 'settings_screen/location_gps_widgets.dart';
part 'settings_screen/location_section.dart';
part 'settings_screen/recurring_schedule_section.dart';
part 'settings_screen/status_section.dart';
part 'settings_screen/time_picker_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsController());

    return Scaffold(
      appBar: AppBar(title: const Text('Settings ⚙️'), backgroundColor: Theme.of(context).colorScheme.inversePrimary, elevation: 0),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Updating settings...')],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeaderSection(),
              const SizedBox(height: 24),
              _TimePickerSection(controller: controller),
              _RecurringScheduleSection(controller: controller),
              const SizedBox(height: 24),
              _LocationSection(controller: controller),
              const SizedBox(height: 24),
              _SettingsStatusSection(controller: controller),
            ],
          ),
        );
      }),
    );
  }
}
