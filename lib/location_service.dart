import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import 'geolocator_wrapper.dart';
import 'location_exceptions.dart';

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
}
