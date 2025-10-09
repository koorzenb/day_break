import 'package:day_break/controllers/app_controller.dart';
import 'package:day_break/controllers/settings_controller.dart';
import 'package:day_break/models/location_exceptions.dart';
import 'package:day_break/screens/settings_screen.dart';
import 'package:day_break/services/location_service.dart';
import 'package:day_break/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'settings_screen_gps_test.mocks.dart';

// Generate mocks for testing
@GenerateNiceMocks([
  MockSpec<Box>(),
  MockSpec<LocationService>(),
  MockSpec<AppController>(),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings Screen GPS Location Detection', () {
    late MockBox mockBox;
    late SettingsService mockSettingsService;
    late MockLocationService mockLocationService;
    late MockAppController mockAppController;

    setUp(() {
      // Initialize mocks
      mockBox = MockBox();
      mockSettingsService = SettingsService(mockBox);
      mockLocationService = MockLocationService();
      mockAppController = MockAppController();

      // Set up default mock returns for settings
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
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('shows GPS detection button when location service is available', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const GetMaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Detect Current Location'), findsOneWidget, reason: 'GPS detection button should be visible when LocationService is available');
      expect(find.byIcon(Icons.my_location), findsOneWidget, reason: 'GPS icon should be visible');
    });

    testWidgets('does not show GPS detection button when location service is not available', (WidgetTester tester) async {
      // Arrange - remove LocationService from GetX
      Get.delete<LocationService>();

      await tester.pumpWidget(const GetMaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Detect Current Location'), findsNothing, reason: 'GPS detection button should not be visible when LocationService is not available');
    });

    testWidgets('shows loading indicator when detecting location', (WidgetTester tester) async {
      // Arrange - make the location detection async and slow
      when(mockLocationService.getCurrentLocationSuggestion()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 2));
        return 'Lower Sackville, Nova Scotia, Canada';
      });

      await tester.pumpWidget(const GetMaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Act - tap the detect button
      await tester.tap(find.text('Detect Current Location'));
      await tester.pump();

      // Assert
      expect(find.text('Detecting location...'), findsOneWidget, reason: 'Loading state should be shown during location detection');
      expect(find.byType(CircularProgressIndicator), findsWidgets, reason: 'Loading indicator should be visible');

      // Clean up - wait for the async operation to complete
      await tester.pumpAndSettle();
    });

    testWidgets('shows location suggestion after successful detection', (WidgetTester tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocationSuggestion()).thenAnswer((_) async => 'Lower Sackville, Nova Scotia, Canada');

      await tester.pumpWidget(const GetMaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Detect Current Location'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Location Detected'), findsOneWidget, reason: 'Location detected header should be visible');
      expect(find.text('Lower Sackville, Nova Scotia, Canada'), findsOneWidget, reason: 'Detected location suggestion should be displayed');
      expect(find.text('Accept'), findsOneWidget, reason: 'Accept button should be visible');
      expect(find.text('Decline'), findsOneWidget, reason: 'Decline button should be visible');
      expect(find.text('Detect Current Location'), findsNothing, reason: 'Detect button should be hidden when suggestion is shown');
    });

    testWidgets('accepts location suggestion and updates controller location', (WidgetTester tester) async {
      // Arrange
      final detectedLocation = 'Lower Sackville, Nova Scotia, Canada';
      when(mockLocationService.getCurrentLocationSuggestion()).thenAnswer((_) async => detectedLocation);
      when(mockBox.put('location', detectedLocation)).thenAnswer((_) async => Future.value());

      await tester.pumpWidget(const GetMaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Act - detect location
      await tester.tap(find.text('Detect Current Location'));
      await tester.pumpAndSettle();

      // Act - accept the suggestion
      await tester.tap(find.text('Accept'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Assert
      final controller = Get.find<SettingsController>();
      expect(controller.location, detectedLocation, reason: 'Controller location should be updated after accepting suggestion');
      expect(controller.hasLocationSuggestion, false, reason: 'Suggestion should be cleared after accepting');
      verify(mockBox.put('location', detectedLocation)).called(1);
      verify(mockAppController.checkSettingsStatus()).called(1);
    });

    testWidgets('declines location suggestion and clears state', (WidgetTester tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocationSuggestion()).thenAnswer((_) async => 'Lower Sackville, Nova Scotia, Canada');

      await tester.pumpWidget(const GetMaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Act - detect location
      await tester.tap(find.text('Detect Current Location'));
      await tester.pumpAndSettle();

      // Act - decline the suggestion
      await tester.tap(find.text('Decline'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Assert
      final controller = Get.find<SettingsController>();
      expect(controller.hasLocationSuggestion, false, reason: 'Suggestion should be cleared after declining');
      expect(controller.location, '', reason: 'Location should remain empty after declining');
      expect(find.text('Detect Current Location'), findsOneWidget, reason: 'Detect button should be visible again after declining');
    });

    testWidgets('shows error when location services are disabled', (WidgetTester tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocationSuggestion()).thenThrow(const LocationServicesDisabledException());

      await tester.pumpWidget(const GetMaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Detect Current Location'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please enable location services in your device settings'), findsOneWidget, reason: 'Error message should be shown for disabled services');
      expect(find.byIcon(Icons.error_outline), findsOneWidget, reason: 'Error icon should be visible');
      expect(find.text('Detect Current Location'), findsOneWidget, reason: 'Detect button should still be visible after error');
    });

    testWidgets('shows error when location permission is denied', (WidgetTester tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocationSuggestion()).thenThrow(const LocationPermissionDeniedException());

      await tester.pumpWidget(const GetMaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Detect Current Location'));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('Location permission denied. Please allow location access in app settings'),
        findsOneWidget,
        reason: 'Error message should be shown for denied permission',
      );
    });

    testWidgets('shows error when location permission is permanently denied', (WidgetTester tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocationSuggestion()).thenThrow(const LocationPermissionPermanentlyDeniedException());

      await tester.pumpWidget(const GetMaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Detect Current Location'));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('Location permission permanently denied. Please enable in device settings'),
        findsOneWidget,
        reason: 'Error message should be shown for permanently denied permission',
      );
    });

    testWidgets('shows error when location name cannot be determined', (WidgetTester tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocationSuggestion()).thenThrow(const LocationUnknownException());

      await tester.pumpWidget(const GetMaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Detect Current Location'));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('Could not determine location name from GPS coordinates'),
        findsOneWidget,
        reason: 'Error message should be shown for unknown location',
      );
    });

    testWidgets('shows generic error for unexpected exceptions', (WidgetTester tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocationSuggestion()).thenThrow(Exception('Network error'));

      await tester.pumpWidget(const GetMaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Detect Current Location'));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('Failed to detect location. Please try again or enter manually'),
        findsOneWidget,
        reason: 'Generic error message should be shown for unexpected exceptions',
      );
    });

    testWidgets('clears error state when close button is tapped', (WidgetTester tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocationSuggestion()).thenThrow(const LocationServicesDisabledException());

      await tester.pumpWidget(const GetMaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Act - trigger error
      await tester.tap(find.text('Detect Current Location'));
      await tester.pumpAndSettle();

      // Act - close error
      await tester.tap(find.byIcon(Icons.close).last, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Assert
      final controller = Get.find<SettingsController>();
      expect(controller.locationDetectionError, null, reason: 'Error should be cleared after closing');
      expect(find.text('Please enable location services in your device settings'), findsNothing, reason: 'Error message should be hidden');
    });

    testWidgets('hides GPS detection section when location is already set', (WidgetTester tester) async {
      // Arrange
      when(mockBox.get('location')).thenReturn('Berlin, Germany');

      await tester.pumpWidget(const GetMaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Detect Current Location'), findsNothing, reason: 'GPS detection should be hidden when location is already set');
      expect(find.text('Berlin, Germany'), findsOneWidget, reason: 'Current location should be displayed');
    });

    testWidgets('shows GPS detection section after clearing location', (WidgetTester tester) async {
      // Arrange
      when(mockBox.get('location')).thenReturn('Berlin, Germany');
      when(mockBox.put('location', '')).thenAnswer((_) async => Future.value());

      await tester.pumpWidget(const GetMaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Act - clear location
      await tester.tap(find.text('Change Location'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Detect Current Location'), findsOneWidget, reason: 'GPS detection button should appear after clearing location');
    });
  });
}
