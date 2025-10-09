# Quick Test Commands

## Run GPS Tests

### All GPS Tests

```bash
# Widget tests
flutter test test/settings_screen_gps_test.dart

# Unit tests  
flutter test test/settings_screen_gps_basic_test.dart

# Both
flutter test test/settings_screen_gps_test.dart test/settings_screen_gps_basic_test.dart
```

### Specific Test

```bash
# Run a specific test by name
flutter test test/settings_screen_gps_test.dart --name "accepts location suggestion"

# Run a specific test group
flutter test test/settings_screen_gps_test.dart --name "Settings Screen GPS"
```

### With Coverage

```bash
# Generate coverage report
flutter test --coverage test/settings_screen_gps_test.dart

# View coverage (requires lcov installed)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
start coverage/html/index.html  # Windows
xdg-open coverage/html/index.html  # Linux
```

### Regenerate Mocks (if needed)

```bash
# Delete old mocks and regenerate
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate on changes)
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Test Checklist

Before committing changes to GPS functionality:

- [ ] Run widget tests: `flutter test test/settings_screen_gps_test.dart`
- [ ] Run unit tests: `flutter test test/settings_screen_gps_basic_test.dart`
- [ ] Verify all 24 tests pass
- [ ] Check coverage if adding new code
- [ ] Update tests if changing GPS behavior
- [ ] Regenerate mocks if changing service interfaces

## Common Test Flags

```bash
# Verbose output
flutter test --verbose test/settings_screen_gps_test.dart

# Run tests in a specific file only
flutter test test/settings_screen_gps_test.dart --plain-name "test name"

# Show test names only (dry run)
flutter test --dry-run test/settings_screen_gps_test.dart

# Run with different concurrency
flutter test --concurrency=1 test/settings_screen_gps_test.dart

# Update golden files (if using visual regression)
flutter test --update-goldens test/settings_screen_gps_test.dart
```

## Debugging Tests

### Print Debug Info

Add to your test:

```dart
print('Controller state: ${controller.location}');
debugPrint('Detailed info: ${controller.toJson()}');
```

### Run Single Test

```bash
flutter test test/settings_screen_gps_test.dart --name "shows loading indicator"
```

### Check Test Output

```bash
# With verbose logging
flutter test test/settings_screen_gps_test.dart -v

# With custom reporter
flutter test test/settings_screen_gps_test.dart --reporter=expanded
```

## Continuous Integration

### GitHub Actions Example

```yaml
- name: Run GPS Tests
  run: |
    flutter test test/settings_screen_gps_test.dart
    flutter test test/settings_screen_gps_basic_test.dart
    
- name: Generate Coverage
  run: flutter test --coverage
  
- name: Upload Coverage
  uses: codecov/codecov-action@v3
  with:
    files: coverage/lcov.info
```

## Troubleshooting

### "Flutter command not found"

```bash
# Check Flutter installation
which flutter
flutter --version

# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"
```

### "Mock generation failed"

```bash
# Clean and regenerate
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### "Tests hang or timeout"

```bash
# Increase timeout
flutter test --timeout=60s test/settings_screen_gps_test.dart

# Run with more verbose output to see where it hangs
flutter test -v test/settings_screen_gps_test.dart
```

### "Widget not found"

- Check if widget is off-screen (use `warnIfMissed: false`)
- Ensure proper `await tester.pumpAndSettle()`
- Verify widget is actually rendered in current state

## Documentation

- **Test Overview:** `test/GPS_TESTS_README.md`
- **Implementation Summary:** `GPS_TESTING_FIX_SUMMARY.md`
- **Copilot Instructions:** `.github/copilot-instructions.md`
- **Flutter Testing Docs:** <https://docs.flutter.dev/testing>

## Quick Verification

Run this to verify test setup:

```bash
# Check test files exist
ls -lh test/settings_screen_gps*.dart

# Count tests
grep -c "test(" test/settings_screen_gps_test.dart
grep -c "test(" test/settings_screen_gps_basic_test.dart

# Verify mocks
ls -lh test/settings_screen_gps*.mocks.dart
```

Expected output:

- Widget test: ~14 tests
- Unit test: ~10 tests
- Total: 24 tests
