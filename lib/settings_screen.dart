import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'settings_controller.dart';

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
              // Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.wb_sunny, color: Colors.orange[600], size: 32),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Day Break', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                Text('Configure your daily weather announcements', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Announcement Time Section
              const Text('Announcement Time ⏰', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Icon(Icons.access_time, color: Theme.of(context).primaryColor),
                  title: const Text('Daily announcement time'),
                  subtitle: Text(
                    controller.formattedTime,
                    style: TextStyle(fontWeight: FontWeight.w500, color: controller.selectedTime != null ? Theme.of(context).primaryColor : Colors.grey),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: controller.showTimePicker,
                ),
              ),

              const SizedBox(height: 24),

              // Location Section
              const Text('Location 📍', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Enter your location for weather updates', style: TextStyle(fontSize: 14, color: Colors.grey)),
                          if (!controller.hasWeatherValidation)
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Icon(Icons.info_outline, size: 16, color: Colors.orange),
                            ),
                        ],
                      ),
                      if (!controller.hasWeatherValidation)
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Text('Weather validation unavailable', style: TextStyle(fontSize: 12, color: Colors.orange)),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (value) {
                          // Update location in real-time
                        },
                        onSubmitted: controller.updateLocation,
                        decoration: InputDecoration(
                          hintText: 'e.g., San Francisco, CA',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        controller: TextEditingController(text: controller.location),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Settings Status
              if (!controller.isSettingsComplete)
                Card(
                  color: Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Setup Required',
                                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange),
                              ),
                              Text('Please set both time and location', style: TextStyle(fontSize: 12, color: Colors.orange)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // Reset Button (for development/testing)
              if (controller.isSettingsComplete)
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Get.dialog(
                        AlertDialog(
                          title: const Text('Reset Settings'),
                          content: const Text(
                            'Are you sure you want to reset all settings? '
                            'This will clear your announcement time and location.',
                          ),
                          actions: [
                            TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () {
                                Get.back();
                                controller.resetSettings();
                              },
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Settings'),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
