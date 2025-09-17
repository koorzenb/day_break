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
              if (controller.location.isEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    const Text('Choose how to set your location:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show current location when set
                      if (controller.location.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.green[600], size: 20),
                            const SizedBox(width: 8),
                            const Text('Current Location', style: TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green[600], size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(controller.location, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              // Clear location to show input options again
                              controller.updateLocation('');
                            },
                            icon: const Icon(Icons.edit_location, size: 18),
                            label: const Text('Change Location'),
                            style: TextButton.styleFrom(foregroundColor: Colors.blue[600]),
                          ),
                        ),
                      ] else ...[
                        // Show input options when no location is set
                        if (!controller.hasWeatherValidation)
                          const Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: Text('Weather validation unavailable', style: TextStyle(fontSize: 12, color: Colors.orange)),
                          ),
                        const SizedBox(height: 12),

                        // GPS Detection Section
                        if (controller.hasLocationDetection) ...[
                          Row(
                            children: [
                              Icon(Icons.gps_fixed, color: Colors.blue[600], size: 20),
                              const SizedBox(width: 8),
                              const Text('GPS Detection', style: TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('Detect your current location automatically', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 12),

                          // GPS Detection Button and Loading State
                          if (controller.isDetectingLocation)
                            const Row(
                              children: [
                                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                SizedBox(width: 12),
                                Text('Detecting location...', style: TextStyle(color: Colors.blue)),
                              ],
                            )
                          else if (!controller.hasLocationSuggestion)
                            ElevatedButton.icon(
                              onPressed: controller.detectCurrentLocation,
                              icon: const Icon(Icons.my_location, size: 18),
                              label: const Text('Detect Current Location'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600], foregroundColor: Colors.white),
                            ),

                          // Location Suggestion Dialog/Popup
                          if (controller.hasLocationSuggestion) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                                      const SizedBox(width: 8),
                                      const Text('Location Detected', style: TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(controller.detectedLocationSuggestion!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: controller.acceptLocationSuggestion,
                                        icon: const Icon(Icons.check, size: 18),
                                        label: const Text('Accept'),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600], foregroundColor: Colors.white),
                                      ),
                                      const SizedBox(width: 12),
                                      OutlinedButton.icon(
                                        onPressed: controller.declineLocationSuggestion,
                                        icon: const Icon(Icons.close, size: 18),
                                        label: const Text('Decline'),
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Location Detection Error
                          if (controller.locationDetectionError != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(controller.locationDetectionError!, style: TextStyle(color: Colors.red[700], fontSize: 12)),
                                  ),
                                  IconButton(
                                    onPressed: controller.clearLocationDetectionState,
                                    icon: const Icon(Icons.close, size: 16),
                                    color: Colors.red[600],
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Custom "OR" Divider
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: const Text(
                                  'OR',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              const Text('GPS detection unavailable', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Manual location input
                        Row(
                          children: [
                            Icon(Icons.edit_location, color: Colors.grey[600], size: 20),
                            const SizedBox(width: 8),
                            const Text('Manual Entry', style: TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Enter your location manually', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 12),
                        TextField(
                          onChanged: (value) {
                            // Update location in real-time
                          },
                          onSubmitted: controller.updateLocation,
                          decoration: InputDecoration(
                            hintText: 'e.g., Halifax, Nova Scotia',
                            prefixIcon: const Icon(Icons.location_on),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          controller: TextEditingController(text: controller.location),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Settings Status
              Card(
                color: controller.isSettingsComplete ? Colors.green[50] : Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        controller.isSettingsComplete ? Icons.check_circle : Icons.warning,
                        color: controller.isSettingsComplete ? Colors.green : Colors.orange,
                      ),
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
