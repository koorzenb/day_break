# GPS Location Detection Tests

## Overview

This directory contains comprehensive widget and unit tests for the GPS location detection feature in the Settings Screen. The tests verify that the GPS detection flow works correctly, handles errors gracefully, and maintains proper state throughout the user interaction.

## Test Files

### 1. `settings_screen_gps_test.dart` - Widget Tests

Comprehensive widget tests that verify the complete UI behavior of GPS location detection in the Settings Screen.

**Test Coverage:**

- GPS detection button visibility (shown when LocationService available, hidden when not)
- Loading indicators during location detection
- Location suggestion display and interaction
- Accept/Decline button functionality
- Error handling for various GPS exceptions
- State management across the UI lifecycle
- GPS section visibility based on location state

**Key Features:**

- Uses `testWidgets` for UI testing
- Tests actual Settings Screen widget rendering
- Verifies user interactions (button taps, state changes)
- Tests error states and edge cases

### 2. `settings_screen_gps_basic_test.dart` - Controller Unit Tests

Focused unit tests that verify the SettingsController GPS functionality in isolation.

**Test Coverage:**

- GPS availability detection
- Initial state correctness
- Location detection state management
- Suggestion handling (accept/decline)
- Error handling
- State clearing functionality

**Key Features:**

- Direct controller testing without UI
- Faster execution than widget tests
- Focused on controller logic and state management
- Easier to debug state issues

## The AppController Issue

### Problem

The original implementation had a critical issue: `SettingsController.updateLocation()` calls `Get.find<AppController>().checkSettingsStatus()`, but tests didn't register an AppController, causing `Get.find()` to throw exceptions.

### Solution

Both test files now properly register a `MockAppController` in the setup:

```dart
setUp(() {
  // ... other setup
  mockAppController = MockAppController();
  when(mockAppController.checkSettingsStatus()).thenReturn(null);
  
  Get.put<AppController>(mockAppController);
});
```

This ensures:

1. `Get.find<AppController>()` succeeds in tests
2. `checkSettingsStatus()` can be called without side effects
3. Tests can verify AppController interactions

## Mock Generation

Mocks are generated using Mockito with `@GenerateNiceMocks` annotations:

```dart
@GenerateNiceMocks([
  MockSpec<Box>(),
  MockSpec<LocationService>(),
  MockSpec<AppController>(),
])
```

### Generating Mocks

To regenerate mocks after changes:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Test Patterns

### 1. Service Registration Pattern

All tests follow this pattern for registering dependencies:

```dart
setUp(() {
  mockBox = MockBox();
  mockSettingsService = SettingsService(mockBox);
  mockLocationService = MockLocationService();
  mockAppController = MockAppController();
  
  Get.reset();
  Get.put<SettingsService>(mockSettingsService);
  Get.put<LocationService>(mockLocationService);
  Get.put<AppController>(mockAppController);
});
```

### 2. Async Testing Pattern

For async operations, tests properly await completion:

```dart
test('shows loading indicator when detecting location', () async {
  when(mockLocationService.getCurrentLocationSuggestion()).thenAnswer((_) async {
    await Future.delayed(Duration(seconds: 2));
    return 'Location';
  });
  
  await tester.tap(find.text('Detect Current Location'));
  await tester.pump(); // Trigger state change
  
  expect(find.text('Detecting location...'), findsOneWidget);
  
  await tester.pumpAndSettle(); // Wait for completion
});
```

### 3. Off-screen Widget Pattern

Some widgets may be off-screen in scrollable views. Use `warnIfMissed: false` for such cases:

```dart
await tester.tap(find.text('Accept'), warnIfMissed: false);
```

### 4. State Verification Pattern

Tests verify both controller state and UI updates:

```dart
// Act
await controller.acceptLocationSuggestion();

// Assert - Controller state
expect(controller.location, expectedLocation);
expect(controller.hasLocationSuggestion, false);

// Assert - Storage interaction
verify(mockBox.put('location', expectedLocation)).called(1);

// Assert - AppController notification
verify(mockAppController.checkSettingsStatus()).called(1);
```

## Running Tests

### Run All GPS Tests

```bash
flutter test test/settings_screen_gps_test.dart
flutter test test/settings_screen_gps_basic_test.dart
```

### Run Specific Test

```bash
flutter test test/settings_screen_gps_test.dart --name "accepts location suggestion"
```

### Run with Coverage

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## Test Scenarios Covered

### Happy Path

1. ✅ User taps "Detect Current Location"
2. ✅ Loading indicator appears
3. ✅ Location suggestion is displayed
4. ✅ User taps "Accept"
5. ✅ Location is saved to settings
6. ✅ AppController is notified
7. ✅ UI updates to show saved location

### Error Scenarios

1. ✅ Location services disabled
2. ✅ Permission denied (initial)
3. ✅ Permission permanently denied
4. ✅ GPS coordinates found but name unknown
5. ✅ Generic/network errors
6. ✅ LocationService not available

### State Management

1. ✅ Initial state (no suggestion, no error, not loading)
2. ✅ Loading state (during detection)
3. ✅ Suggestion state (after successful detection)
4. ✅ Error state (after failed detection)
5. ✅ Cleared state (after dismiss or decline)

### Edge Cases

1. ✅ Accept with no suggestion (no-op)
2. ✅ Decline clears suggestion
3. ✅ Error dismiss clears error
4. ✅ GPS section hidden when location already set
5. ✅ GPS section shown after clearing location

## Dependencies

### Required Mocks

- `MockBox<E>` - For Hive storage operations
- `MockLocationService` - For GPS operations
- `MockAppController` - For settings status updates

### Key Testing Packages

- `flutter_test` - Flutter testing framework
- `mockito` - Mock generation and verification
- `get` - GetX state management (used in tests)

## Troubleshooting

### Common Issues

**Issue: `Get.find<AppController>()` throws exception**

- **Solution:** Ensure `MockAppController` is registered in `setUp()`

**Issue: Widget not found in widget tests**

- **Solution:** Use `warnIfMissed: false` for off-screen widgets or ensure proper scrolling

**Issue: Async tests fail**

- **Solution:** Use `await tester.pumpAndSettle()` to wait for animations/futures

**Issue: Mock methods not called**

- **Solution:** Verify the test flow and ensure `await` on async operations

## Future Improvements

1. **Integration Tests:** Add end-to-end tests with actual GPS mocking
2. **Performance Tests:** Measure GPS detection response times
3. **Accessibility Tests:** Verify screen reader compatibility
4. **Visual Regression Tests:** Capture screenshots for UI changes
5. **Error Recovery Tests:** Test retry mechanisms and user recovery flows

## Contributing

When adding new GPS features:

1. Add corresponding tests in both files (widget + unit)
2. Update mocks if new dependencies are added
3. Run all tests before committing
4. Update this README with new test scenarios
5. Follow existing test patterns and naming conventions

## References

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [GetX Testing Guide](https://github.com/jonataslaw/getx#tests)
- [Copilot Instructions](../.github/copilot-instructions.md)
