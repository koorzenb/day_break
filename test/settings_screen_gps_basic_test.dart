import 'package:day_break/controllers/app_controller.dart';
import 'package:day_break/controllers/settings_controller.dart';
import 'package:day_break/services/location_service.dart';
import 'package:day_break/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'settings_screen_gps_basic_test.mocks.dart';

// Generate mocks for basic testing
@GenerateNiceMocks([
  MockSpec<Box>(),
  MockSpec<LocationService>(),
  MockSpec<AppController>(),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings Controller GPS Basic Tests', () {
    late MockBox mockBox;
    late SettingsService mockSettingsService;
    late MockLocationService mockLocationService;
    late MockAppController mockAppController;
    late SettingsController controller;

    setUp(() {
      // Initialize mocks
      mockBox = MockBox();
      mockSettingsService = SettingsService(mockBox);
      mockLocationService = MockLocationService();
      mockAppController = MockAppController();

      // Set up default mock returns
      when(mockBox.get('announcementHour')).thenReturn(null);
      when(mockBox.get('announcementMinute')).thenReturn(null);
      when(mockBox.get('location')).thenReturn(null);
      when(mockBox.get('isRecurring')).thenReturn(false);
      when(mockBox.get('recurrencePattern')).thenReturn(null);
      when(mockBox.get('recurrenceDays')).thenReturn(null);

      // Set up AppController mock
      when(mockAppController.checkSettingsStatus()).thenReturn(null);

      // Reset GetX and register services
      Get.reset();
      Get.put<SettingsService>(mockSettingsService);
      Get.put<LocationService>(mockLocationService);
      Get.put<AppController>(mockAppController);

      // Create controller
      controller = SettingsController();
    });

    tearDown(() {
      Get.reset();
    });

    test('hasLocationDetection returns true when LocationService is available', () {
      expect(controller.hasLocationDetection, true, reason: 'Location detection should be available when LocationService is registered');
    });

    test('hasLocationDetection returns false when LocationService is not available', () {
      // Arrange - remove LocationService
      Get.delete<LocationService>();
      final newController = SettingsController();

      // Assert
      expect(newController.hasLocationDetection, false, reason: 'Location detection should not be available when LocationService is missing');
    });

    test('initial GPS state is correct', () {
      expect(controller.isDetectingLocation, false, reason: 'Should not be detecting location initially');
      expect(controller.detectedLocationSuggestion, null, reason: 'Should have no suggestion initially');
      expect(controller.locationDetectionError, null, reason: 'Should have no error initially');
      expect(controller.hasLocationSuggestion, false, reason: 'Should not have suggestion initially');
    });

    test('detectCurrentLocation sets loading state', () async {
      // Arrange - make detection slow
      when(mockLocationService.getCurrentLocationSuggestion()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return 'Halifax, Nova Scotia, Canada';
      });

      // Act - start detection (don't await)
      final detectionFuture = controller.detectCurrentLocation();

      // Assert - check loading state immediately
      expect(controller.isDetectingLocation, true, reason: 'Should be in loading state during detection');
      expect(controller.detectedLocationSuggestion, null, reason: 'Suggestion should be cleared');
      expect(controller.locationDetectionError, null, reason: 'Error should be cleared');

      // Clean up
      await detectionFuture;
      expect(controller.isDetectingLocation, false, reason: 'Loading should complete');
    });

    test('detectCurrentLocation sets suggestion on success', () async {
      // Arrange
      const expectedLocation = 'Halifax, Nova Scotia, Canada';
      when(mockLocationService.getCurrentLocationSuggestion()).thenAnswer((_) async => expectedLocation);

      // Act
      await controller.detectCurrentLocation();

      // Assert
      expect(controller.isDetectingLocation, false, reason: 'Loading should be complete');
      expect(controller.detectedLocationSuggestion, expectedLocation, reason: 'Suggestion should be set');
      expect(controller.hasLocationSuggestion, true, reason: 'Should have suggestion');
      expect(controller.locationDetectionError, null, reason: 'Should have no error');
    });

    test('detectCurrentLocation sets error on exception', () async {
      // Arrange
      when(mockLocationService.getCurrentLocationSuggestion()).thenThrow(Exception('GPS failed'));

      // Act
      await controller.detectCurrentLocation();

      // Assert
      expect(controller.isDetectingLocation, false, reason: 'Loading should be complete');
      expect(controller.detectedLocationSuggestion, null, reason: 'Suggestion should remain null');
      expect(controller.locationDetectionError, isNotNull, reason: 'Should have error message');
      expect(controller.hasLocationSuggestion, false, reason: 'Should not have suggestion');
    });

    test('acceptLocationSuggestion updates location when suggestion exists', () async {
      // Arrange
      const suggestedLocation = 'Halifax, Nova Scotia, Canada';
      when(mockLocationService.getCurrentLocationSuggestion()).thenAnswer((_) async => suggestedLocation);
      when(mockBox.put('location', suggestedLocation)).thenAnswer((_) async => Future.value());

      // Detect location first
      await controller.detectCurrentLocation();
      expect(controller.hasLocationSuggestion, true, reason: 'Should have suggestion before accepting');

      // Act
      await controller.acceptLocationSuggestion();

      // Assert
      expect(controller.location, suggestedLocation, reason: 'Location should be updated');
      expect(controller.hasLocationSuggestion, false, reason: 'Suggestion should be cleared after accepting');
      expect(controller.detectedLocationSuggestion, null, reason: 'Suggestion should be null');
      verify(mockBox.put('location', suggestedLocation)).called(1);
    });

    test('acceptLocationSuggestion does nothing when no suggestion exists', () async {
      // Arrange - no suggestion
      expect(controller.hasLocationSuggestion, false, reason: 'Should not have suggestion');

      // Act
      await controller.acceptLocationSuggestion();

      // Assert
      expect(controller.location, '', reason: 'Location should remain empty');
      verifyNever(mockBox.put('location', any));
    });

    test('declineLocationSuggestion clears suggestion state', () async {
      // Arrange - set up a suggestion first
      const suggestedLocation = 'Halifax, Nova Scotia, Canada';
      when(mockLocationService.getCurrentLocationSuggestion()).thenAnswer((_) async => suggestedLocation);

      await controller.detectCurrentLocation();
      expect(controller.hasLocationSuggestion, true, reason: 'Should have suggestion before declining');

      // Act
      controller.declineLocationSuggestion();

      // Assert
      expect(controller.hasLocationSuggestion, false, reason: 'Suggestion should be cleared');
      expect(controller.detectedLocationSuggestion, null, reason: 'Suggestion should be null');
      expect(controller.locationDetectionError, null, reason: 'Error should be null');
    });

    test('clearLocationDetectionState clears all location detection state', () async {
      // Arrange - set up a suggestion
      const suggestedLocation = 'Halifax, Nova Scotia, Canada';
      when(mockLocationService.getCurrentLocationSuggestion()).thenAnswer((_) async => suggestedLocation);

      await controller.detectCurrentLocation();
      expect(controller.hasLocationSuggestion, true, reason: 'Should have suggestion');

      // Act
      controller.clearLocationDetectionState();

      // Assert
      expect(controller.detectedLocationSuggestion, null, reason: 'Suggestion should be cleared');
      expect(controller.locationDetectionError, null, reason: 'Error should be cleared');
      expect(controller.isDetectingLocation, false, reason: 'Loading state should be cleared');
      expect(controller.hasLocationSuggestion, false, reason: 'Should not have suggestion');
    });
  });
}
