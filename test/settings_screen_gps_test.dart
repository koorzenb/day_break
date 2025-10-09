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

// Simple mock AppController to avoid dependency issues in tests
class MockAppController extends AppController {
  @override
  void checkSettingsStatus() {
    // Do nothing in test - avoid complex dependency setup
  }
}

@GenerateNiceMocks([MockSpec<Box>(), MockSpec<LocationService>(), MockSpec<InternalFinalCallback<void>>(as: #MockInternalFinalCallback)])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings Screen GPS Location Detection', () {
    late SettingsController controller;
    late SettingsService mockSettingsService;
    late MockBox mockBox;
    late MockLocationService mockLocationService;
    late MockInternalFinalCallback mockCallback;
    late MockAppController mockAppController;

    setUp(() {
      mockBox = MockBox();
      mockLocationService = MockLocationService();
      mockCallback = MockInternalFinalCallback();
      mockAppController = MockAppController();

      // Set up default mock returns for all settings
      when(mockBox.get('announcementHour')).thenReturn(null);
      when(mockBox.get('announcementMinute')).thenReturn(null);
      when(mockBox.get('location')).thenReturn(null);
      when(mockBox.get('isRecurring')).thenReturn(false);
      when(mockBox.get('recurrencePattern')).thenReturn(null);
      when(mockBox.get('recurrenceDays')).thenReturn(null);

      // Mock box put operations
      when(mockBox.put(any, any)).thenAnswer((_) async => {});

      // Create SettingsService after mocks are set up
      mockSettingsService = SettingsService(mockBox);

      // Mock LocationService lifecycle methods properly
      when(mockCallback.call()).thenReturn(null);
      when(mockLocationService.onStart).thenReturn(mockCallback);

      // Register services with GetX
      Get.reset();
      Get.put<SettingsService>(mockSettingsService);
      Get.put<LocationService>(mockLocationService);
      Get.put<AppController>(mockAppController);

      controller = SettingsController();
      controller.onInit();
    });

    tearDown(() {
      Get.reset();
    });

    Widget createTestWidget() {
      return GetMaterialApp(home: SettingsScreen());
    }

    testWidgets('displays Detect Current Location button when not detecting and no suggestion', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert - Check basic location section
      expect(find.text('Location 📍'), findsOneWidget, reason: 'Location section should be visible');

      // Assert - GPS Detection section should be visible with LocationService available
      expect(find.text('GPS Detection'), findsOneWidget, reason: 'GPS Detection section should be visible when LocationService is available');
      expect(find.text('Detect your current location automatically'), findsOneWidget, reason: 'GPS Detection description should be visible');

      // Assert - Detect Current Location button should be visible
      expect(find.text('Detect Current Location'), findsOneWidget, reason: 'Should display GPS detection button when not detecting location');
      expect(find.byIcon(Icons.my_location), findsOneWidget, reason: 'GPS button should display location icon');
    });

    testWidgets('shows loading indicator when detecting location', (WidgetTester tester) async {
      // Arrange
      // Mock a slow response to keep loading state visible
      when(
        mockLocationService.getCurrentLocationSuggestion(),
      ).thenAnswer((_) => Future.delayed(const Duration(seconds: 2), () => 'Halifax, Nova Scotia, Canada'));

      await tester.pumpWidget(createTestWidget());

      // Act - tap the GPS detection button by tapping on the text
      final buttonText = find.text('Detect Current Location');
      expect(buttonText, findsOneWidget, reason: 'Should find GPS detection button text');
      await tester.tap(buttonText);
      await tester.pump(); // Update UI to show loading state

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: 'Should show loading indicator while detecting location');
      expect(find.text('Detecting location...'), findsOneWidget, reason: 'Should display detecting location message');
      expect(find.text('Detect Current Location'), findsNothing, reason: 'GPS button should be hidden during location detection');

      // Clean up: Complete the async operation to avoid pending timers
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('displays location suggestion after successful GPS detection', (WidgetTester tester) async {
      // Arrange
      const detectedLocation = 'Lower Sackville, Nova Scotia, Canada';
      when(mockLocationService.getCurrentLocationSuggestion()).thenAnswer((_) async => detectedLocation);

      await tester.pumpWidget(createTestWidget());

      // Act - tap GPS detection button and wait for completion
      await tester.tap(find.text('Detect Current Location'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Location Detected'), findsOneWidget, reason: 'Should display location detected title');
      expect(find.text(detectedLocation), findsOneWidget, reason: 'Should display the detected location name');
      expect(find.text('Accept'), findsOneWidget, reason: 'Should show Accept button for location suggestion');
      expect(find.text('Decline'), findsOneWidget, reason: 'Should show Decline button for location suggestion');
      expect(find.byIcon(Icons.check_circle), findsOneWidget, reason: 'Should show success icon for location detection');
    });

    testWidgets('accepts location suggestion when Accept button is tapped', (WidgetTester tester) async {
      // Arrange
      const detectedLocation = 'Halifax, Nova Scotia, Canada';
      when(mockLocationService.getCurrentLocationSuggestion()).thenAnswer((_) async => detectedLocation);

      await tester.pumpWidget(createTestWidget());

      // Act - detect location and accept suggestion
      await tester.tap(find.text('Detect Current Location'));
      await tester.pumpAndSettle();

      // Tap Accept button - suppress off-screen warnings since functionality is what matters
      await tester.tap(find.text('Accept'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Add a small delay to ensure async operations complete
      await tester.pump(const Duration(milliseconds: 100));

      // Assert
      expect(controller.location, equals(detectedLocation), reason: 'Controller should update location after accepting suggestion');
      expect(controller.hasLocationSuggestion, isFalse, reason: 'Location suggestion should be cleared after accepting');
      expect(find.text('Location Detected'), findsNothing, reason: 'Location suggestion widget should be hidden after accepting');
    });

    testWidgets('declines location suggestion when Decline button is tapped', (WidgetTester tester) async {
      // Arrange
      const detectedLocation = 'Dartmouth, Nova Scotia, Canada';
      when(mockLocationService.getCurrentLocationSuggestion()).thenAnswer((_) async => detectedLocation);

      await tester.pumpWidget(createTestWidget());

      // Act - detect location and decline suggestion
      await tester.tap(find.text('Detect Current Location'));
      await tester.pumpAndSettle();

      // Tap Decline button - suppress off-screen warnings since functionality is what matters
      await tester.tap(find.text('Decline'), warnIfMissed: false);
      await tester.pumpAndSettle(); // Assert
      expect(controller.hasLocationSuggestion, isFalse, reason: 'Location suggestion should be cleared after declining');
      expect(controller.location, isEmpty, reason: 'Location should remain empty after declining suggestion');
      expect(find.text('Location Detected'), findsNothing, reason: 'Location suggestion widget should be hidden after declining');
      expect(find.text('Detect Current Location'), findsOneWidget, reason: 'GPS detection button should reappear after declining');
    });

    testWidgets('displays error message when location services are disabled', (WidgetTester tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocationSuggestion()).thenThrow(LocationServicesDisabledException());

      await tester.pumpWidget(createTestWidget());

      // Act - tap GPS detection button
      await tester.tap(find.text('Detect Current Location'));
      await tester.pumpAndSettle();

      // Assert - Allow for multiple instances of the error message (might appear in different UI contexts)
      expect(
        find.text('Please enable location services in your device settings'),
        findsAtLeastNWidgets(1),
        reason: 'Should display location services disabled error message',
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget, reason: 'Should show error icon for location detection failure');
      expect(controller.locationDetectionError, isNotNull, reason: 'Controller should have location detection error');
    });

    testWidgets('displays error message when location permission is denied', (WidgetTester tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocationSuggestion()).thenThrow(LocationPermissionDeniedException());

      await tester.pumpWidget(createTestWidget());

      // Act - tap GPS detection button
      await tester.tap(find.text('Detect Current Location'));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('Location permission denied. Please allow location access in app settings'),
        findsOneWidget,
        reason: 'Should display permission denied error message',
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget, reason: 'Should show error icon for permission failure');
    });

    testWidgets('displays error message when location permission is permanently denied', (WidgetTester tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocationSuggestion()).thenThrow(LocationPermissionPermanentlyDeniedException());

      await tester.pumpWidget(createTestWidget());

      // Act - tap GPS detection button
      await tester.tap(find.text('Detect Current Location'));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('Location permission permanently denied. Please enable in device settings'),
        findsOneWidget,
        reason: 'Should display permanently denied permission error message',
      );
    });

    testWidgets('displays error message when location name is unknown', (WidgetTester tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocationSuggestion()).thenThrow(LocationUnknownException());

      await tester.pumpWidget(createTestWidget());

      // Act - tap GPS detection button
      await tester.tap(find.text('Detect Current Location'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Could not determine location name from GPS coordinates'), findsOneWidget, reason: 'Should display unknown location error message');
    });

    testWidgets('displays generic error message for other location detection failures', (WidgetTester tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocationSuggestion()).thenThrow(Exception('Network error'));

      await tester.pumpWidget(createTestWidget());

      // Act - tap GPS detection button
      await tester.tap(find.text('Detect Current Location'));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('Failed to detect location. Please try again or enter manually'),
        findsOneWidget,
        reason: 'Should display generic error message for unknown failures',
      );
    });

    testWidgets('clears error message when close button is tapped', (WidgetTester tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocationSuggestion()).thenThrow(LocationServicesDisabledException());

      await tester.pumpWidget(createTestWidget());

      // Act - cause error, then clear it
      await tester.tap(find.text('Detect Current Location'));
      await tester.pumpAndSettle();

      // Verify error is displayed
      expect(find.byIcon(Icons.error_outline), findsOneWidget, reason: 'Error should be displayed initially');

      // Clear the error by tapping close button - suppress off-screen warnings since functionality is what matters
      await tester.tap(find.byIcon(Icons.close), warnIfMissed: false);
      await tester.pumpAndSettle(); // Assert
      expect(controller.locationDetectionError, isNull, reason: 'Location detection error should be cleared');
      expect(find.byIcon(Icons.error_outline), findsNothing, reason: 'Error widget should be hidden after clearing');
      expect(find.text('Detect Current Location'), findsOneWidget, reason: 'GPS detection button should reappear after clearing error');
    });

    testWidgets('maintains loading state during async location detection', (WidgetTester tester) async {
      // Arrange
      when(mockLocationService.getCurrentLocationSuggestion()).thenAnswer((_) async {
        await Future.delayed(Duration(milliseconds: 100));
        return 'Sydney, Nova Scotia, Canada';
      });

      await tester.pumpWidget(createTestWidget());

      // Act - start detection
      await tester.tap(find.text('Detect Current Location'));
      await tester.pump(); // Trigger the async operation

      // Assert loading state
      expect(controller.isDetectingLocation, isTrue, reason: 'Controller should indicate location detection is in progress');
      expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: 'Loading indicator should be visible during detection');

      // Wait for completion and verify final state
      await tester.pumpAndSettle();
      expect(controller.isDetectingLocation, isFalse, reason: 'Controller should indicate location detection is complete');
      expect(find.byType(CircularProgressIndicator), findsNothing, reason: 'Loading indicator should be hidden after completion');
    });

    testWidgets('hides GPS button when location suggestion is available', (WidgetTester tester) async {
      // Arrange
      const detectedLocation = 'Truro, Nova Scotia, Canada';
      when(mockLocationService.getCurrentLocationSuggestion()).thenAnswer((_) async => detectedLocation);

      await tester.pumpWidget(createTestWidget());

      // Act - detect location
      await tester.tap(find.text('Detect Current Location'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Detect Current Location'), findsNothing, reason: 'GPS button should be hidden when location suggestion is available');
      expect(controller.hasLocationSuggestion, isTrue, reason: 'Controller should indicate location suggestion is available');
    });

    testWidgets('displays OR divider below GPS section', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('OR'), findsOneWidget, reason: 'Should display OR divider to separate GPS and manual input sections');
      expect(find.byType(Divider), findsAtLeastNWidgets(2), reason: 'Should display divider lines on both sides of OR text');
    });
  });
}
