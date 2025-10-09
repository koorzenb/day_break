part of '../settings_screen.dart';

/// Recurring schedule section widget for SettingsScreen
/// Handles the recurring announcement configuration including patterns and days
class _RecurringScheduleSection extends StatelessWidget {
  final SettingsController controller;

  const _RecurringScheduleSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Only show if time is selected
      if (controller.selectedTime == null) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text('Schedule 📅', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                // Recurring toggle
                SwitchListTile(
                  secondary: Icon(Icons.repeat, color: Theme.of(context).primaryColor),
                  title: const Text('Recurring announcements'),
                  subtitle: Text(controller.isRecurring ? 'Announcements will repeat' : 'One-time announcement only'),
                  value: controller.isRecurring,
                  onChanged: controller.toggleRecurring,
                ),

                // Recurrence pattern options (shown when recurring is enabled)
                if (controller.isRecurring) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Repeat Pattern', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),

                        // Pattern selection chips
                        _PatternSelectionChips(controller: controller),

                        // Custom days selection (shown when custom pattern is selected)
                        if (controller.recurrencePattern == RecurrencePattern.custom) ...[
                          const SizedBox(height: 16),
                          const Text('Select Days', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          _CustomDaySelection(controller: controller),
                        ],

                        // Summary of selected days
                        if (controller.isRecurring && controller.recurrenceDays.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _ScheduleSummary(controller: controller),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }
}

/// Pattern selection chips widget
class _PatternSelectionChips extends StatelessWidget {
  final SettingsController controller;

  const _PatternSelectionChips({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Wrap(
        spacing: 8.0,
        children: RecurrencePattern.values.map((pattern) {
          final isSelected = controller.recurrencePattern == pattern;
          return ChoiceChip(
            label: Text(pattern.displayName),
            selected: isSelected,
            onSelected: (_) => controller.updateRecurrencePattern(pattern),
            selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            labelStyle: TextStyle(color: isSelected ? Theme.of(context).primaryColor : null, fontWeight: isSelected ? FontWeight.w600 : null),
          );
        }).toList(),
      ),
    );
  }
}

/// Custom day selection widget
class _CustomDaySelection extends StatelessWidget {
  final SettingsController controller;

  const _CustomDaySelection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: List.generate(7, (index) {
          final day = index + 1; // 1=Monday, 7=Sunday
          final isSelected = controller.recurrenceDays.contains(day);
          return FilterChip(
            label: Text(controller.getDayName(day)),
            selected: isSelected,
            onSelected: (_) => controller.toggleRecurrenceDay(day),
            selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            checkmarkColor: Theme.of(context).primaryColor,
            labelStyle: TextStyle(color: isSelected ? Theme.of(context).primaryColor : null, fontWeight: isSelected ? FontWeight.w600 : null),
          );
        }),
      ),
    );
  }
}

/// Schedule summary widget
class _ScheduleSummary extends StatelessWidget {
  final SettingsController controller;

  const _ScheduleSummary({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Announcement Schedule',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${controller.recurrencePattern.displayName}: ${controller.recurrenceDays.map(controller.getFullDayName).join(', ')} at ${controller.formattedTime}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
