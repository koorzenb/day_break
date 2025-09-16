import 'package:day_break/geolocator_wrapper.dart';
import 'package:day_break/location_exceptions.dart';
import 'package:day_break/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'location_service_test.mocks.dart';

@GenerateMocks([GeolocatorWrapper])
void main() {
  group('LocationService', () {
    late LocationService locationService;
    late MockGeolocatorWrapper mockGeolocator;

    setUp(() {
      mockGeolocator = MockGeolocatorWrapper();
      locationService = LocationService(mockGeolocator);
    });

    test('determinePosition returns position when location services are enabled and permission is granted', () async {
      when(mockGeolocator.isLocationServiceEnabled()).thenAnswer((_) async => true);
      when(mockGeolocator.checkPermission()).thenAnswer((_) async => LocationPermission.whileInUse);
      when(mockGeolocator.getCurrentPosition()).thenAnswer(
        (_) async => Position(
          latitude: 123,
          longitude: 456,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        ),
      );

      final position = await locationService.determinePosition();

      expect(position, isA<Position>());
    });

    test('determinePosition throws LocationServicesDisabledException when services are disabled', () async {
      when(mockGeolocator.isLocationServiceEnabled()).thenAnswer((_) async => false);

      expect(locationService.determinePosition(), throwsA(isA<LocationServicesDisabledException>()));
    });

    test('determinePosition requests permission when denied and then returns position', () async {
      when(mockGeolocator.isLocationServiceEnabled()).thenAnswer((_) async => true);
      when(mockGeolocator.checkPermission()).thenAnswer((_) async => LocationPermission.denied);
      when(mockGeolocator.requestPermission()).thenAnswer((_) async => LocationPermission.whileInUse);
      when(mockGeolocator.getCurrentPosition()).thenAnswer(
        (_) async => Position(
          latitude: 123,
          longitude: 456,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        ),
      );

      final position = await locationService.determinePosition();

      expect(position, isA<Position>());
    });

    test('determinePosition throws LocationPermissionDeniedException when permission is denied twice', () async {
      when(mockGeolocator.isLocationServiceEnabled()).thenAnswer((_) async => true);
      when(mockGeolocator.checkPermission()).thenAnswer((_) async => LocationPermission.denied);
      when(mockGeolocator.requestPermission()).thenAnswer((_) async => LocationPermission.denied);

      expect(locationService.determinePosition(), throwsA(isA<LocationPermissionDeniedException>()));
    });

    group('getCurrentLocationSuggestion', () {
      test('throws LocationServicesDisabledException when location services are disabled', () async {
        when(mockGeolocator.isLocationServiceEnabled()).thenAnswer((_) async => false);

        expect(locationService.getCurrentLocationSuggestion(), throwsA(isA<LocationServicesDisabledException>()));
      });

      test('throws LocationPermissionDeniedException when permission is denied', () async {
        when(mockGeolocator.isLocationServiceEnabled()).thenAnswer((_) async => true);
        when(mockGeolocator.checkPermission()).thenAnswer((_) async => LocationPermission.denied);
        when(mockGeolocator.requestPermission()).thenAnswer((_) async => LocationPermission.denied);

        expect(locationService.getCurrentLocationSuggestion(), throwsA(isA<LocationPermissionDeniedException>()));
      });

      test('throws LocationPermissionPermanentlyDeniedException when permission is denied forever', () async {
        when(mockGeolocator.isLocationServiceEnabled()).thenAnswer((_) async => true);
        when(mockGeolocator.checkPermission()).thenAnswer((_) async => LocationPermission.deniedForever);

        expect(locationService.getCurrentLocationSuggestion(), throwsA(isA<LocationPermissionPermanentlyDeniedException>()));
      });

      // Note: Full integration testing of getCurrentLocationSuggestion() with actual geocoding
      // would require mocking the geocoding package which uses static methods.
      // For now, we test the error handling paths through determinePosition().
      // In a real-world scenario, we might extract the geocoding logic to a wrapper class
      // that can be injected and mocked, similar to how we handle GeolocatorWrapper.
    });
  });
}
