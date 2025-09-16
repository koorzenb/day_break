import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_controller.dart';
import 'settings_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appController = Get.find<AppController>();

    return Scaffold(
      body: Obx(() {
        // Show loading while app is initializing
        if (!appController.isInitialized) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Initializing Day Break...')],
            ),
          );
        }

        // If settings are not configured, show settings screen
        if (!appController.hasSettings) {
          return const SettingsScreen();
        }

        // Main app interface when everything is ready
        return _buildMainInterface(context, appController);
      }),
    );
  }

  Widget _buildMainInterface(BuildContext context, AppController controller) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Bar equivalent
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Day Break ☀️', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      Text('Daily Weather Announcements', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    ],
                  ),
                ),
                IconButton(onPressed: controller.openSettings, icon: const Icon(Icons.settings), tooltip: 'Settings'),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Text('Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Text(controller.currentStatus, style: const TextStyle(fontSize: 16))),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions
          const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          // Test Weather Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.triggerWeatherUpdate,
              icon: const Icon(Icons.cloud),
              label: const Text('Test Weather Notification'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),

          const SizedBox(height: 12),

          // Settings Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.openSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),

          const Spacer(),

          // Info Footer
          Center(
            child: Column(
              children: [
                Text(
                  'Daily notifications will be sent at your configured time.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Make sure to allow notifications for this app.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
