import 'package:day_break/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  group('Settings Screen Simple UI Tests', () {
    setUp(() {
      Get.reset();
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('settings screen renders without crashing', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(GetMaterialApp(home: SettingsScreen()));

      // Assert - Just check that the app bar renders
      expect(find.text('Settings ⚙️'), findsOneWidget, reason: 'Should display Settings title in app bar');
    });

    testWidgets('displays location section', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(GetMaterialApp(home: SettingsScreen()));

      // Assert - Check location section exists
      expect(find.text('Location 📍'), findsOneWidget, reason: 'Should display Location section');
    });

    testWidgets('displays manual input when no location service', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(GetMaterialApp(home: SettingsScreen()));

      // Look for manual input text field
      expect(find.byType(TextFormField), findsAtLeastNWidgets(1), reason: 'Should display manual location input field');
    });
  });
}
