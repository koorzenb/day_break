part of '../settings_screen.dart';

/// Time picker section widget for SettingsScreen
/// Handles the daily announcement time selection
class _TimePickerSection extends StatelessWidget {
  final SettingsController controller;

  const _TimePickerSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Announcement Time ⏰',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.access_time,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Daily announcement time'),
              subtitle: Text(
                controller.formattedTime,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: controller.selectedTime != null
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: controller.showTimePicker,
            ),
          ),
        ],
      ),
    );
  }
}
