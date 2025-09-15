# PLAN.md: Day Break Development Plan

This document outlines the development plan for the Day Break application, based on the requirements in `PRD.md`. Each phase includes testing and validation steps to ensure code quality and adherence to software engineering best practices.

## Phase 1: Project Setup and Core Dependencies

- [x] **Initialize Project:**
  - Ensure the Flutter project is correctly set up and follows the structure outlined in `copilot-instructions.md`.
  - Verify the Flutter version using `.fvmrc`.

- [x] **Add Dependencies:**
  - Add the following core packages to `pubspec.yaml`:
    - `get`: For state management and dependency injection.
    - `hive` & `hive_flutter`: For local storage of user settings.
    - `geolocator`: For fetching the user's location.
    - `flutter_local_notifications`: For scheduling and displaying daily announcements.
    - `http`: For making requests to the weather API.
  - Run `flutter pub get` to install the dependencies.

- [x] **Initial Validation:**
  - Run `flutter test` to ensure the default widget test passes and the project is in a clean state.
  - Run `flutter analyze` to check for initial analysis issues.

## Phase 2: Settings Service and Storage

- [x] **Create Settings Service:**
  - Implement a `SettingsService` to manage user preferences (location, announcement time).
  - Use Hive to initialize a box for storing these settings.

- [x] **Develop Storage Logic:**
  - Create methods to save and retrieve the user's preferred announcement time and location.
  - Initialize Hive in `lib/main.dart`.

- [x] **Testing:**
  - Write unit tests for the `SettingsService` to verify that saving and loading settings work correctly.
  - Ensure all tests pass by running `flutter test`.

## Phase 3: Location Service

- [x] **Create Location Service:**
  - Implement a `LocationService` using the `geolocator` package.
  - Develop logic to request location permissions on app startup.
  - Handle cases where permission is denied, allowing for manual input as per `PRD.md`.

- [x] **Testing:**
  - Write unit tests for the `LocationService`. Use mocking to simulate responses from the `geolocator` package.
  - Ensure all tests pass by running `flutter test`.

## Phase 4: Weather Service

- [ ] **Create Weather Service:**
  - Implement a `WeatherService` to fetch data from a weather API using the `http` package.
  - Create data models to parse the JSON response from the API.

- [ ] **Develop API Logic:**
  - Implement error handling for network issues or API failures.
  - Provide a fallback mechanism if weather data cannot be retrieved.

- [ ] **Testing:**
  - Write unit tests for the `WeatherService`, mocking the `http` client to simulate API responses and error conditions.
  - Ensure all tests pass by running `flutter test`.

## Phase 5: Notification Service

- [ ] **Create Notification Service:**
  - Implement a `NotificationService` using `flutter_local_notifications`.
  - Configure platform-specific notification settings (Android).

- [ ] **Develop Scheduling Logic:**
  - Create a method to schedule a daily notification at the time specified by the user.
  - The notification content will be constructed using data from the `WeatherService`.

- [ ] **Testing:**
  - Write unit tests to verify the notification scheduling logic.
  - Ensure all tests pass by running `flutter test`.

## Phase 6: UI - Settings Screen

- [ ] **Build UI:**
  - Create a simple settings screen for the initial setup and subsequent configuration changes.
  - Include a time picker for the announcement time and a field for manual location entry.

- [ ] **State Management:**
  - Use a `GetX` controller (`SettingsController`) to manage the state of the UI and handle user input.
  - Connect the controller to the `SettingsService` to persist the user's choices.

- [ ] **Testing:**
  - Write widget tests for the settings screen to verify that UI elements are present and interact correctly with the controller.
  - Ensure all tests pass by running `flutter test`.

## Phase 7: Application Integration

- [ ] **Initialize Services:**
  - In `lib/main.dart`, use GetX dependency injection to initialize and provide all services (`SettingsService`, `LocationService`, etc.).

- [ ] **Implement Core Logic:**
  - Create a main `AppController` to orchestrate the services.
  - On startup, the controller will check if settings are configured. If not, it will navigate to the settings screen.
  - Implement the background task that triggers daily: fetches location, gets weather, and schedules the notification.

- [ ] **Testing:**
  - Write integration tests to ensure that all services work together as expected.
  - Run `flutter analyze` and `flutter test` to validate the integrated app.

## Phase 8: Final Validation and Commit

- [ ] **Manual Testing:**
  - Perform manual testing on a physical device or emulator as outlined in `copilot-instructions.md`.
    - Verify the initial setup flow.
    - Test changing the announcement time and location.
    - Confirm that a notification is triggered at the correct time.
    - Check that the app works correctly when opened from a terminated state.

- [ ] **Pre-Commit Checks:**
  - Run `flutter analyze` to fix any remaining issues.
  - Run `flutter test` to ensure the entire test suite passes.

- [ ] **Commit:**
  - Use the `dart run update_version.dart` script to create a commit with a descriptive message (e.g., "feat: initial app implementation").
