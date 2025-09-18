import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../geolocator_wrapper.dart';
import '../models/location_exceptions.dart';

class LocationService extends GetxService {
  final GeolocatorWrapper _geolocator;

  LocationService([GeolocatorWrapper? geolocator]) : _geolocator = geolocator ?? GeolocatorWrapper();

  Future<Position> determinePosition() async {
    final serviceEnabled = await _geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServicesDisabledException();
    }

    var permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationPermissionDeniedException();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionPermanentlyDeniedException();
    }

    return _geolocator.getCurrentPosition();
  }

  /// Get the current location with a human-readable location name suggestion
  /// Returns a formatted location string like "San Francisco, CA, USA"
  /// Throws LocationException on errors
  Future<String> getCurrentLocationSuggestion() async {
    try {
      // Get current GPS position
      final position = await determinePosition();

      // Convert coordinates to human-readable address
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isEmpty) {
        throw const LocationUnknownException();
      }

      // Use the first placemark to build a readable location name
      final placemark = placemarks.first;
      final locationParts = <String>[];

      // Add city if available
      if (placemark.locality?.isNotEmpty == true) {
        locationParts.add(placemark.locality!);
      }

      // Add state/administrative area if available
      if (placemark.administrativeArea?.isNotEmpty == true) {
        locationParts.add(placemark.administrativeArea!);
      }

      // Add country if available
      if (placemark.country?.isNotEmpty == true) {
        locationParts.add(placemark.country!);
      }

      // If we couldn't build a meaningful location string, throw exception
      if (locationParts.isEmpty) {
        throw const LocationUnknownException();
      }

      return locationParts.join(', ');
    } catch (e) {
      // Re-throw our custom exceptions as-is
      if (e is LocationException) {
        rethrow;
      }
      // Wrap any other exceptions as unknown location error
      throw const LocationUnknownException();
    }
  }
}
