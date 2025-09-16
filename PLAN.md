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
    - `flutter_tts`: For text-to-speech functionality to provide audible weather announcements.
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

- [x] **Enhanced Location Selection:**
  - Provide dual-mode location selection: manual entry or GPS-based suggestion.
  - Implement GPS location detection with reverse geocoding to get human-readable location names.
  - Create location suggestion popup that displays detected location (e.g., "San Francisco, CA").
  - Allow users to accept the suggested location or decline and enter manually.
  - Ensure graceful fallback to manual entry if GPS detection fails or user declines.

- [~] **Testing:**
  -   Write unit tests for the `LocationService`. Use mocking to simulate responses from the `geolocator` package.
  - Test both GPS detection and manual entry workflows.
  - Ensure all tests pass by running `flutter test`.

## Phase 4: Weather Service

- [x] **Create Weather Service:**
  - Implement a `WeatherService` to fetch data from a weather API using the `http` package.
  - Create data models to parse the JSON response from the API.

- [x] **Develop API Logic:**
  - Implement error handling for network issues or API failures.
  - Provide a fallback mechanism if weather data cannot be retrieved.

- [x] **Testing:**
  - Write unit tests for the `WeatherService`, mocking the `http` client to simulate API responses and error conditions.
  - Ensure all tests pass by running `flutter test`.

## Phase 5: Notification Service

- [x] **Create Notification Service:**
  - Implement a `NotificationService` using `flutter_local_notifications`.
  - Configure platform-specific notification settings (Android).

- [x] **Develop Scheduling Logic:**
  - Create a method to schedule a daily notification at the time specified by the user.
  - The notification content will be constructed using data from the `WeatherService`.

- [ ] **Add Audible Announcements:**
  - Integrate `flutter_tts` for text-to-speech functionality.
  - Implement voice announcements that read the weather forecast aloud when the notification is triggered.
  - Provide configuration options for voice settings (speech rate, pitch, language).
  - Ensure voice announcements work in conjunction with visual notifications.

- [ ] **Testing:**
  - Write unit tests to verify the notification scheduling logic.
  - Test text-to-speech functionality with mock weather data.
  - Ensure all tests pass by running `flutter test`.

## Phase 6: UI - Settings Screen

- [~] **Build UI:**
  - Create a simple settings screen for the initial setup and subsequent configuration changes.
  - Include a time picker for the announcement time and enhanced location selection interface. Use the `geolocator` package to suggest the current location, allowing users to accept or decline the suggestion. If they accept, populate the location field; if they decline or if GPS detection fails, allow manual entry.
  - Add a back button/navigation to return to the main screen after configuration.
  - Implement automatic navigation back to MainScreen when initial setup is complete.

- [x] **Enhanced Location Selection UI:**
  - Create dual-mode location input interface with manual entry field and GPS detection button.
  - Implement location suggestion dialog/popup showing detected location with accept/decline options.
  - Display clear loading states during GPS location detection.
  - Show appropriate error messages if GPS detection fails.
  - Provide smooth transitions between manual and GPS-based location selection.

- [x] **State Management:**
  - Use a `GetX` controller (`SettingsController`) to manage the state of the UI and handle user input.
  - Connect the controller to the `SettingsService` to persist the user's choices.
  - Implement navigation logic to detect when initial setup is complete and return to main flow.
  - Add state management for location detection process (loading, success, error states).

- [~] **Navigation Flow:**
  - Ensure settings screen has proper back navigation for users returning from MainScreen.
  - Implement automatic return to MainScreen when both location and notification time are configured.
  - Provide clear visual feedback when setup is complete.

- [ ] **Testing:**
  - Write widget tests for the settings screen to verify that UI elements are present and interact correctly with the controller.
  - Test navigation flow and back button functionality.
  - Test both manual location entry and GPS-based location selection workflows.
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
    - Verify the initial setup flow with proper navigation back to MainScreen.
    - Test enhanced location selection: both manual entry and GPS-based location detection.
    - Verify location suggestion popup shows detected location with accept/decline options.
    - Test graceful fallback to manual entry when GPS detection fails or is declined.
    - Test changing the announcement time and location with back button functionality.
    - Confirm that both visual and audible notifications are triggered at the correct time.
    - Test text-to-speech functionality with actual weather data.
    - Check that the app works correctly when opened from a terminated state.
    - Verify voice announcement quality and clarity.

- [ ] **Pre-Commit Checks:**
  - Run `flutter analyze` to fix any remaining issues.
  - Run `flutter test` to ensure the entire test suite passes.

- [ ] **Commit:**
  - Use the `dart run update_version.dart` script to create a commit with a descriptive message (e.g., "feat: initial app implementation").
