import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/app_controller.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Get.put to ensure the controller is created and available
    final AppController appController = Get.put(AppController());

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

          // Test notification with 15s countdown
          const SizedBox(height: 12),
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: controller.isTestNotificationCountdown
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue[600])),
                          const SizedBox(width: 12),
                          Text(
                            'Test notification in ${controller.testNotificationCountdown}s...',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.blue[700]),
                          ),
                        ],
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: controller.hasSettings ? () => controller.scheduleTestNotification(15) : null,
                      icon: const Icon(Icons.notifications_active),
                      label: const Text('Schedule Test Notification (15s)'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
            ),
          ),

          // Info Footer - only show when notifications are not allowed
          if (!controller.isNotificationsAllowed) ...[
            const Spacer(),
            SizedBox(height: 16),
            Center(
              child: Text(
                'Make sure to allow notifications for this app.',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
