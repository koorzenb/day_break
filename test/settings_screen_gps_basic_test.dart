import 'package:day_break/controllers/settings_controller.dart';
import 'package:day_break/screens/settings_screen.dart';
import 'package:day_break/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'settings_screen_gps_basic_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Box>()])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings Screen GPS UI Components', () {
    late SettingsController controller;
    late SettingsService mockSettingsService;
    late MockBox mockBox;

    setUp(() {
      mockBox = MockBox();

      // Set up default mock returns for all settings
      when(mockBox.get('announcementHour')).thenReturn(null);
      when(mockBox.get('announcementMinute')).thenReturn(null);
      when(mockBox.get('location')).thenReturn(null);
      when(mockBox.get('isRecurring')).thenReturn(false);
      when(mockBox.get('recurrencePattern')).thenReturn(null);
      when(mockBox.get('recurrenceDays')).thenReturn(null);

      // Mock box put operations
      when(mockBox.put(any, any)).thenAnswer((_) async => {});

      // Create SettingsService after box mocks are set up
      mockSettingsService = SettingsService(mockBox);

      // Register only the SettingsService - LocationService will not be available
      // This should result in hasLocationDetection being false, showing GPS unavailable message
      Get.reset();
      Get.put<SettingsService>(mockSettingsService);
      // DO NOT register LocationService to test the "GPS unavailable" UI state

      controller = SettingsController();
      controller.onInit();
    });

    tearDown(() {
      Get.reset();
    });

    Widget createTestWidget() {
      return GetMaterialApp(home: SettingsScreen());
    }

    testWidgets('displays location section with proper components when GPS unavailable', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert - Check main location section
      expect(find.text('Location 📍'), findsOneWidget, reason: 'Should display Location section title');
      expect(find.text('Choose how to set your location:'), findsOneWidget, reason: 'Should display location setup instruction');
    });

    testWidgets('displays GPS unavailable message when no LocationService available', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert - Since no LocationService is registered, GPS unavailable message should show
      expect(find.text('GPS detection unavailable'), findsOneWidget, reason: 'Should display GPS unavailable message when LocationService not available');
      expect(find.byIcon(Icons.info_outline), findsAtLeastNWidgets(1), reason: 'Should show info icon for GPS unavailable state and location instruction');
    });

    testWidgets('does not display OR divider when GPS unavailable', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert - OR divider only appears when GPS Detection section is shown
      expect(find.text('OR'), findsNothing, reason: 'Should not display OR divider when GPS is unavailable');
    });

    testWidgets('displays manual location input section', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Manual Entry'), findsOneWidget, reason: 'Should display Manual Entry section title');
      expect(find.text('Enter your location manually'), findsOneWidget, reason: 'Should display manual entry description');
      expect(find.byType(TextField), findsAtLeastNWidgets(1), reason: 'Should display text field for manual location input');
    });

    testWidgets('controller has expected initial GPS state properties', (WidgetTester tester) async {
      // Assert controller initial state
      expect(controller.isDetectingLocation, isFalse, reason: 'Controller should not be detecting location initially');
      expect(controller.hasLocationSuggestion, isFalse, reason: 'Controller should not have location suggestion initially');
      expect(controller.locationDetectionError, isNull, reason: 'Controller should not have location detection error initially');
      expect(controller.hasLocationDetection, isFalse, reason: 'Controller should indicate no location detection available without service');
    });

    testWidgets('controller state properties are reactive with Obx wrappers', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Simulate state changes manually (since no real LocationService)
      controller.clearLocationDetectionState();
      await tester.pump();

      // Assert - The widgets should update reactively
      expect(controller.isDetectingLocation, isFalse, reason: 'Clearing state should ensure not detecting location');
      expect(controller.hasLocationSuggestion, isFalse, reason: 'Clearing state should remove any location suggestion');
      expect(controller.locationDetectionError, isNull, reason: 'Clearing state should remove any location error');
    });

    testWidgets('location input field accepts text input', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Find the location input field
      final textField = find.byType(TextField);
      expect(textField, findsAtLeastNWidgets(1), reason: 'Should find location input field');

      // Enter text in the field
      await tester.enterText(textField.first, 'Halifax, Nova Scotia');
      await tester.pump();

      // Assert
      expect(find.text('Halifax, Nova Scotia'), findsOneWidget, reason: 'Text field should display entered location text');
    });
  });
}
