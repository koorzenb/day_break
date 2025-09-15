import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import 'geolocator_wrapper.dart';

class LocationService extends GetxService {
  final GeolocatorWrapper _geolocator;

  LocationService([GeolocatorWrapper? geolocator]) : _geolocator = geolocator ?? GeolocatorWrapper();

  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await _geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    return await _geolocator.getCurrentPosition();
  }
}
