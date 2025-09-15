## Weekly Reminders

**Review `PRD.md` and `PLAN.md`**

- **PRD (`PRD.md`):** Review this to stay aligned with **what** we are building and **why**. It defines the product's features, users, and overall goals.
- **Plan (`PLAN.md`):** Review this to track **how** and **when** we will deliver. It outlines our execution strategy, timelines, and key milestones.

## Copilot Integration

**Always Use Context7 MCP**: For every request submitted to Copilot, always use the context7 MCP (Model Context Protocol) to ensure proper context awareness and enhanced code understanding capabilities.

## Working Effectively

### Prerequisites and Setup

- Install Flutter 3.35.3 exactly (specified in .fvmrc file)
- Use FVM (Flutter Version Management) if available: `fvm use 3.35.3`
- If FVM not available, install Flutter 3.35.3 manually from Flutter releases
- Ensure Android SDK is available for APK builds (API level 35+ recommended)

### Core Development Commands

- Install dependencies: `flutter pub get`
- Run code analysis: `flutter analyze`
- Run all tests: `flutter test` -- typically takes 10-30 seconds. NEVER CANCEL.
- Build debug APK: `flutter build apk --debug`
- Build release APK: `flutter build apk --release --obfuscate --split-debug-info=./debug-info` -- takes 2-5 minutes on modern hardware. NEVER CANCEL. Set timeout to 10+ minutes.
- Run app in debug mode: `flutter run` (requires connected device or emulator)

### Version Management and Release Process

- **Committing Changes**: When asked to perform a `git commit`, always use the `dart run update_version.dart` script.
- **Post-Commit Workflow**: After `update_version.dart` completes successfully, you must:
  1.  Conduct a "Good, Bad, and Ugly" review of the codebase.
  2.  Review `PRD.md` for alignment.
  3.  Reconsider and suggest future changes based on the review.
- Update version and changelog: `dart run update_version.dart`
  - This script runs tests first and will abort if tests fail
  - Prompts for commit message with format: "type: description" (e.g., "fix: resolve timer issue")
  - Automatically updates pubspec.yaml, CHANGELOG.md, and set-build-env.bat
  - Commits changes automatically
- Build production APK (Windows only): `build-prod-apk.bat`
  - Runs full test suite first
  - Creates release APK with obfuscation
  - Takes 2-5 minutes total. NEVER CANCEL. Set timeout to 10+ minutes.
  - Outputs to release/{version}/ folder

## Validation

### Manual Testing Requirements

After making any changes, ALWAYS test the following core functionality:

1. **App Launch**: Verify app starts without crashes and shows burn status
2. **Status Updates**: Check that burn status displays correctly (Green=Burn, Orange=Restricted, Red=No Burn)
3. **Time-based Logic**: Test burn permission logic at different times (before 8am, 2pm-7pm, after 7pm)
4. **Background Processing**: Verify notification system works (requires device permissions)
5. **Modal Information**: Test info modal shows correct burn guidelines based on current status

### Testing Strategy

- Always run `flutter test` before making any changes to understand current state
- The test suite covers:
  - BurnLogicService: Core burn permission logic with time-based rules
  - BurnStatus models: Status types and display properties
  - UI state calculations: Proper text and color display for all scenarios
- Tests typically complete in 10-30 seconds
- If any tests fail, fix them before proceeding with changes
- Make sure that all tests have 'expect' statements. Whenever you comment on an 'expect' statement, rather try to insert this into the 'reason' property for the expect-statement.

### Pre-commit Validation

Always run these commands before committing changes:

- `flutter analyze` -- lint and static analysis, takes 5-15 seconds
- `flutter test` -- full test suite, takes 10-30 seconds. NEVER CANCEL.
- Manual testing of at least one complete user scenario

## Project Structure and Key Areas

### Main Application Files

- `lib/`: Contains the source code for the app.
- `lib/main.dart` - App entry point with initialization

### Build and Configuration

- `pubspec.yaml` - Flutter dependencies and app metadata
- `android/` - Android-specific build configuration
- `analysis_options.yaml` - Dart/Flutter linting rules
- `assets/`: Contains images and other static resources.
- `.fvmrc` - Flutter version specification (3.35.3)

### Testing

- `test/` - Comprehensive unit test suite

### Scripts and Automation

- `update_version.dart` - Version management with automated testing
- `build-prod-apk.bat` - Windows production build script
- `set-build-env.bat` - Build environment variables

## Common Development Tasks

### Coding Standards

- Use single quotes for strings.
- Use arrow functions for callbacks.
- Follow the Dart style guide: https://dart.dev/guides/language/effective-dart/style
- Write meaningful comments for complex logic.
- Use descriptive variable and function names.
- Keep functions small and focused on a single task.
- Use async/await for asynchronous operations.
- Coach me in SOLID principles, GoF design patterns, and clean architecture.

### Adding New Features

1. Run `flutter test` to ensure clean starting state
2. Create tests for new functionality in appropriate `test/` subdirectory
3. Implement feature following existing patterns (GetX for state management, Hive for storage)
4. Run `flutter analyze` and fix any linting issues
5. Run `flutter test` and ensure all tests pass
6. Test manually on device/emulator
7. Use `dart run update_version.dart` for version bump and changelog

### Debugging Issues

- Check `flutter doctor -v` for environment issues
- Use `flutter logs` for runtime debugging

## Build Timing and Performance

- `flutter pub get`: 10-30 seconds typically
- `flutter analyze`: 5-15 seconds typically
- `flutter test`: 10-30 seconds for full suite. NEVER CANCEL.
- `flutter build apk --release`: 2-5 minutes typically. NEVER CANCEL. Set timeout to 10+ minutes.
- Production build with `build-prod-apk.bat`: 2-5 minutes total. NEVER CANCEL. Set timeout to 10+ minutes.

## Known Limitations

- Build requires Android SDK setup for APK generation
- Production build script (`build-prod-apk.bat`) is Windows-specific
- App requires notification permissions on device for full functionality

## Troubleshooting

- If `flutter doctor` shows Android license issues: run `flutter doctor --android-licenses`
- If builds fail: verify Flutter 3.35.3 is being used (check with `flutter --version`)
- If tests fail: check that no breaking changes were made to BurnLogicService time calculations
- If notifications don't work: verify app has notification permissions on test device

## API Key Management

**Never Hardcode API Keys**

- API keys must **never** be hardcoded anywhere in the codebase.
- Always store API keys and secrets in environment variables.
- For mobile apps, use a dotenv-like solution (e.g., [flutter_dotenv](https://pub.dev/packages/flutter_dotenv)) to load environment variables at runtime.
- Document required environment variables in your setup instructions.
- Ensure `.env` files are **never** committed to source control (add to `.gitignore`).

**Implementation Guidance**

- When accessing API keys in code, always read them from environment variables using the dotenv package.
- Example usage in Dart/Flutter:

  ```dart
  import 'package:flutter_dotenv/flutter_dotenv.dart';

  final apiKey = dotenv.env['API_KEY'];
  ```

- Update build and deployment scripts to ensure environment variables are set appropriately for each environment (development, staging, production).

**Security Reminder**

- Review code for accidental exposure of secrets before every commit.
- If an API key is ever exposed, rotate it immediately and update all relevant environments.
