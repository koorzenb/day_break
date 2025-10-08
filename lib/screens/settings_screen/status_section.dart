part of '../settings_screen.dart';

/// Settings status and reset section for SettingsScreen
/// Shows completion status and provides reset functionality
class _SettingsStatusSection extends StatelessWidget {
  final SettingsController controller;

  const _SettingsStatusSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Settings Status Card
        Card(
          color: controller.isSettingsComplete ? Colors.green[50] : Colors.orange[50],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(controller.isSettingsComplete ? Icons.check_circle : Icons.warning, color: controller.isSettingsComplete ? Colors.green : Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.isSettingsComplete ? 'Setup Complete' : 'Setup Required',
                        style: TextStyle(fontWeight: FontWeight.w600, color: controller.isSettingsComplete ? Colors.green : Colors.orange),
                      ),
                      Text(
                        controller.isSettingsComplete ? 'All required settings are configured.' : 'Please set both time and location',
                        style: TextStyle(fontSize: 12, color: controller.isSettingsComplete ? Colors.green : Colors.orange),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Reset Button (for development/testing)
        if (controller.isSettingsComplete) _ResetButton(controller: controller),
      ],
    );
  }
}

/// Reset button widget with confirmation dialog
class _ResetButton extends StatelessWidget {
  final SettingsController controller;

  const _ResetButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _showResetDialog(context),
        icon: const Icon(Icons.refresh),
        label: const Text('Reset Settings'),
        style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
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
  }
}
