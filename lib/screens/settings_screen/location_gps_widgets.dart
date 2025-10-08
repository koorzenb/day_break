part of '../settings_screen.dart';

/// GPS detection section with button, loading state, suggestions, and errors
class _GPSDetectionSection extends StatelessWidget {
  final SettingsController controller;

  const _GPSDetectionSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

        // Location suggestion and error widgets
        if (controller.hasLocationSuggestion) _LocationSuggestion(controller: controller),

        if (controller.locationDetectionError != null) _LocationError(controller: controller),

        // Divider
        _OrDivider(),
      ],
    );
  }
}

/// Location suggestion widget
class _LocationSuggestion extends StatelessWidget {
  final SettingsController controller;

  const _LocationSuggestion({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

/// Location detection error widget
class _LocationError extends StatelessWidget {
  final SettingsController controller;

  const _LocationError({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
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
    );
  }
}

/// GPS unavailable message widget
class _GPSUnavailableMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
    );
  }
}

/// OR divider widget
class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
      ],
    );
  }
}
