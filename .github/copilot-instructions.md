## Weekly Reminders

**Review `PRD.md` and `PLAN.md`**

- `PRD.md`: Defines product features, users, and goals.
- `PLAN.md`: Outlines execution strategy, timelines, and milestones.

## Copilot Integration

**Always Use Context7 MCP**: For every Copilot request, use Context7 MCP for context awareness and code understanding.

## Working Effectively

### Prerequisites and Setup

- Flutter 3.35.3 required (`.fvmrc`). Use FVM: `fvm use 3.35.3` or install manually.
- Android SDK required for APK builds (API level 35+ recommended).

### Timezone Configuration

**All time-based operations use Halifax timezone (`America/Halifax`).**

- App handles AST/ADT transitions automatically.
- All scheduling, notifications, and time calculations use Halifax time, regardless of device location.
- Reference: `tz.setLocalLocation(tz.getLocation('America/Halifax'))` in `NotificationService.initialize()`.

### Core Development Commands

- Install dependencies: `flutter pub get`
- Analyze code: `flutter analyze`
- Run all tests: `flutter test` (10-30s, never cancel)
- Build debug APK: `flutter build apk --debug`
- Build release APK: `flutter build apk --release --obfuscate --split-debug-info=./debug-info` (2-5 min, never cancel)
- Run app: `flutter run` (requires device/emulator)

### Version Management and Release Process

### Pre-commit Validation

- Run `flutter analyze` and `flutter test` before every commit.
- Manually test at least one complete user scenario.

- **Committing Changes**: When asked to perform a `git commit`, always use the `dart run update_version.dart` script.
- **Post-Commit Workflow**: After `update_version.dart` completes successfully, you must:
  1.  Conduct a "Good, Bad, and Ugly" review of the codebase.
  2.  Review `PRD.md` for alignment.
  3.  Reconsider and suggest future changes based on the review.

## Validation

### Testing Strategy

- All tests must use `expect` with a `reason` property for comments.

## Project Structure and Key Areas

### Main Application Files

- `lib/`: Source code
- `lib/main.dart`: App entry point

### Build and Configuration

- `pubspec.yaml`: Dependencies and metadata
- `android/`: Android build config
- `analysis_options.yaml`: Linting rules
- `assets/`: Static resources
- `.fvmrc`: Flutter version

### Testing

- `test/`: Unit tests

### Scripts and Automation

- `update_version.dart`: Versioning and changelog
- `build-prod-apk.bat`: Production build (Windows)
- `set-build-env.bat`: Build environment variables

## Common Development Tasks

### Coding Standards

- Use single quotes for strings.
- Use arrow functions for callbacks.
- Follow the Dart style guide: https://dart.dev/guides/language/effective-dart/style
- Write meaningful comments for complex logic.
- Keep functions small and focused on a single task.
- Use async/await for asynchronous operations.
- Coach me in SOLID principles, GoF design patterns, and clean architecture.

### Adding New Features

1. Run `flutter test` for clean state
2. Add tests in `test/`
3. Follow existing patterns (GetX, Hive)
4. Run `flutter analyze` and fix lints
5. Run `flutter test` and ensure all pass
6. Manual test on device/emulator
7. Use `dart run update_version.dart` for version bump/changelog

### Debugging Issues

- Use `flutter doctor -v` for environment issues
- Use `flutter logs` for runtime debugging

## Build Timing and Performance

- `flutter pub get`: 10-30s
- `flutter analyze`: 5-15s
- `flutter test`: 10-30s (never cancel)
- `flutter build apk --release`: 2-5 min (never cancel)
- `build-prod-apk.bat`: 2-5 min (never cancel)

## Known Limitations

- Android SDK required for APK builds
- Production build script is Windows-only
- App requires notification permissions on device

## Troubleshooting

- For Android license issues: `flutter doctor --android-licenses`
- If builds fail: check Flutter version (`flutter --version`)
- If notifications fail: check app permissions on device

## API Key Management

**Never hardcode API keys.**

- Store API keys/secrets in environment variables.
- Use `flutter_dotenv` for runtime loading.
- Never commit `.env` files (add to `.gitignore`).
- Example:
  ```dart
  import 'package:flutter_dotenv/flutter_dotenv.dart';
  final apiKey = dotenv.env['API_KEY'];
  ```
- Rotate exposed keys immediately and update environments.

## Permission Handling

- When adding permission handlers, ensure relevant entries are in `AndroidManifest.xml` (notifications, location, etc).
- Verify permissions are declared to avoid runtime issues on Android.
