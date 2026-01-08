part of '../settings_screen.dart';

/// Location section widget for SettingsScreen
/// Handles location setting including GPS detection and manual input
class _LocationSection extends StatelessWidget {
  final SettingsController controller;

  const _LocationSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location 📍',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (controller.location.isEmpty) ...[
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Choose how to set your location:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
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
                  if (controller.location.isNotEmpty)
                    _CurrentLocationDisplay(controller: controller)
                  else
                    _LocationInputOptions(controller: controller),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget to display current location when set
class _CurrentLocationDisplay extends StatelessWidget {
  final SettingsController controller;

  const _CurrentLocationDisplay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.green[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Current Location',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
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
                  child: Text(
                    controller.location,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () => controller.updateLocation(''),
              icon: const Icon(Icons.edit_location, size: 18),
              label: const Text('Change Location'),
              style: TextButton.styleFrom(foregroundColor: Colors.blue[600]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget containing location input options when no location is set
class _LocationInputOptions extends StatelessWidget {
  final SettingsController controller;

  const _LocationInputOptions({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weather validation status
        if (!controller.hasWeatherValidation)
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Text(
              'Weather validation unavailable',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),
        const SizedBox(height: 12),

        // GPS Detection Section
        if (controller.hasLocationDetection)
          _GPSDetectionSection(controller: controller)
        else
          _GPSUnavailableMessage(),

        // Manual location input
        _ManualLocationInput(controller: controller),
      ],
    );
  }
}

// These GPS-related widgets are now in location_gps_widgets.dart

/// Manual location input widget
class _ManualLocationInput extends StatefulWidget {
  final SettingsController controller;

  const _ManualLocationInput({required this.controller});

  @override
  State<_ManualLocationInput> createState() => _ManualLocationInputState();
}

class _ManualLocationInputState extends State<_ManualLocationInput> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.controller.location);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Update text controller when location changes
      if (_textController.text != widget.controller.location) {
        _textController.text = widget.controller.location;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_location, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Manual Entry',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your location manually',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) {
              // Update location in real-time
            },
            onSubmitted: widget.controller.updateLocation,
            decoration: InputDecoration(
              hintText: 'e.g., Lower Sackville, Nova Scotia, Canada',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            controller: _textController,
          ),
        ],
      );
    });
  }
}
