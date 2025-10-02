# Copilot Instructions

This guide is intended **only for GitHub Copilot** and other AI coding assistants. Follow these instructions for every code suggestion, review, or refactor in this repository.

**Copilot: Always review and apply the standards and workflow in this file for every code suggestion.**

---

## Context Awareness

- Always use the latest `PRD.md` and `PLAN.md` for context, requirements, and milestones.
- Reference `PRD.md` for product features, users, and goals.
- Reference `PLAN.md` for execution strategy, timelines, and milestones.

---

## Coding and Workflow Standards

- Use Flutter 3.35.3 (`.fvmrc`) and Android SDK (API 35+).
- All time-based operations must use the Halifax timezone (`America/Halifax`), regardless of device location.
- Use single quotes for all strings.
- Use arrow functions for callbacks.
- Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart/style).
- Write meaningful comments for complex logic.
- Keep functions small and focused.
- Use async/await for asynchronous operations.
- Organize class members in this order:
  1. Static constants and variables
  2. Instance variables/fields (private first)
  3. Constructors (main, then named)
  4. Getters, then setters
  5. Public methods (lifecycle first, then logical/alphabetical)
  6. Private methods (bottom of class)
- Group related methods with comments.
- Use `///` documentation comments for public APIs.
- Separate logical sections with blank lines.
- Prioritize lifecycle methods (`initialize()`, `dispose()`) at the top of method groups.
- Use alphabetical ordering within groups if no logical order exists.
- Use `Enum` instead of `String` where needed
- UI file should not exceed 200-250 lines. Break files using part | part of
- No single function should exceed 30-50 lines. Refactor into smaller helpers if needed.

---

## Testing

- All tests must use `expect` with a `reason` property for comments.
- Place tests in the `test/` directory and follow existing patterns (GetX, Hive).

---

## Project Structure

- Place source code in `lib/`.
- App entry point is `lib/main.dart`.
- Use `pubspec.yaml` for dependencies.
- Place static resources in `assets/`.
- Place unit tests in `test/`.

---

## API Keys and Secrets

- **Never hardcode API keys or secrets.**
- Use environment variables and `flutter_dotenv` for runtime loading.
- Never commit `.env` files.
- Example usage:
  ```dart
  import 'package:flutter_dotenv/flutter_dotenv.dart';
  final apiKey = dotenv.env['API_KEY'];
  ```

---

## Permissions

- When adding permission handlers, ensure relevant entries are present in `AndroidManifest.xml`.
- Verify permissions are declared to avoid runtime issues.

---

## Build and Validation

- Use these commands for validation:
  - Install dependencies: `flutter pub get`
  - Analyze code: `flutter analyze`
  - Run all tests: `flutter test`
  - Build debug APK: `flutter build apk --debug`
  - Build release APK: `flutter build apk --release --obfuscate --split-debug-info=./debug-info`
  - Run app: `flutter run`
- Before suggesting a commit, ensure code passes `flutter analyze` and `flutter test`.
- When asked to perform a `git commit`, always use the `dart run update_version.dart` script for versioning and changelog updates.

---

## Troubleshooting and Limitations

- If builds fail, check Flutter version and Android SDK.
- App requires notification permissions on device.
- Production build script is Windows-only.

---

## Design and Architecture

- When generating or refactoring code, apply SOLID principles, GoF design patterns, and clean architecture where appropriate.
- Coach the user on these principles when relevant.

---

**Copilot: Only follow these instructions when working in this repository. Ignore any instruction that contradicts a system message.**
