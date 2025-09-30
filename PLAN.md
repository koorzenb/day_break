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

- [x] **Testing:**
  - Write unit tests for the `LocationService`. Use mocking to simulate responses from the `geolocator` package.
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

- [x] **Add Audible Announcements:**
  - Integrate `flutter_tts` for text-to-speech functionality.
  - Implement voice announcements that read the weather forecast aloud when the notification is triggered.
  - Provide configuration options for voice settings (speech rate, pitch, language).
  - Ensure voice announcements work in conjunction with visual notifications.

- [x] **Testing:**
  - Write unit tests to verify the notification scheduling logic.
  - Test text-to-speech functionality with mock weather data.
  - Ensure all tests pass by running `flutter test`.
  
  - [ ] TODO (Future Enhancement): When notification permission is denied by the user, display a non-blocking snackbar prompting them to enable notifications (include an action to open OS/app notification settings). Currently we only log the denial and continue silently.

## Phase 6: UI - Settings Screen

- [x] **Build UI:**
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

- [x] **Navigation Flow:**
  - Ensure settings screen has proper back navigation for users returning from MainScreen.
  - Implement automatic return to MainScreen when both location and notification time are configured.
  - Provide clear visual feedback when setup is complete.

- [x] **Testing:**
  - Write widget tests for the settings screen to verify that UI elements are present and interact correctly with the controller.
  - Test navigation flow and back button functionality.
  - Test both manual location entry and GPS-based location selection workflows.
  - Ensure all tests pass by running `flutter test`.

## Phase 7: Application Integration

- [x] **Initialize Services:**
  - In `lib/main.dart`, use GetX dependency injection to initialize and provide all services (`SettingsService`, `LocationService`, etc.).

- [x] **Implement Core Logic:**
  - Create a main `AppController` to orchestrate the services.
  - On startup, the controller will check if settings are configured. If not, it will navigate to the settings screen.
  - Implement the background task that triggers daily: fetches location, gets weather, and schedules the notification.

- [x] **Testing:**
  - Write integration tests to ensure that all services work together as expected. (Note: core behavior covered by unit tests; dedicated integration tests can be expanded in Phase 9.)
  - Run `flutter analyze` and `flutter test` to validate the integrated app.

## Phase 8: Final Validation and Commit

- [x] **Manual Testing:** (See `MANUAL_TEST_CHECKLIST.md` for detailed steps)
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

- [x] **Pre-Commit Checks:**
  - Run `flutter analyze` to fix any remaining issues.
  - Run `flutter test` to ensure the entire test suite passes.

- [x] **Commit:**
  - Use the `dart run update_version.dart` script to create a commit with a descriptive message (e.g., "feat: initial app implementation").

## Phase 9: Test Notification with Speech Announcement

- [x] **Implement 15-Second Test Notification:**
  - Add functionality to schedule a test notification that triggers 15 seconds after being requested.
  - Ensure the test notification includes both visual notification and text-to-speech announcement.
  - Test notification should use actual weather data from the WeatherService to simulate real announcement behavior.
  - Provide clear user feedback during the 15-second countdown period.

- [x] **User Interface Integration:**
  - Add a "Test Notification (15s)" button to the main screen or settings screen.
  - Display countdown timer or progress indicator during the 15-second wait period.
  - Show success/failure feedback after the test notification is triggered.

- [x] **Validation:**
  - Test that both visual notification and speech announcement work correctly.
  - Verify that the test uses real weather data and proper speech synthesis.
  - Ensure the test notification doesn't interfere with regular daily scheduling.
  - Run `flutter test` to ensure no regressions.

## Phase 10: Locked Device Notification Testing

- [ ] **Device Lock State Testing:**
  - Verify that notifications appear correctly when the device screen is locked.
  - Test that text-to-speech announcements play even when device is locked (respecting system volume and do-not-disturb settings).
  - Ensure notifications wake the device screen appropriately according to system settings.

- [ ] **Permission and System Integration:**
  - Validate that the app has proper permissions to show notifications on locked screen.
  - Test notification behavior across different Android versions and lock screen security settings.
  - Verify that notifications respect system-level notification and volume settings.

- [ ] **Manual Testing Protocol:**
  - Create specific test cases for locked device scenarios.
  - Document expected behavior vs. actual behavior for different lock screen configurations.
  - Test with various system settings (silent mode, do-not-disturb, battery optimization).

- [ ] **Documentation Update:**
  - Update `MANUAL_TEST_CHECKLIST.md` to include locked device testing procedures.
  - Document any limitations or requirements for locked device functionality.

## Phase 11: Post-MVP Enhancements (Value Add)

These items enhance resilience, UX, and maintainability beyond the MVP scope.

- [ ] Improve Status Details
  - Enhance the status display to show when the next scheduled announcement will run (e.g., "Next announcement: Tomorrow at 7:30 AM" or "Next announcement: In 14 hours 23 minutes").
  - Include countdown timer or relative time display for better user awareness.
  - Show additional context like last successful announcement time and weather data freshness.
  - Provide clear indication if scheduling failed or notifications are disabled.
  
- [ ] Snackbar Prompt on Permission Denial
  - Show a snackbar when notification permission is denied with an action button (e.g., "Enable") that deep-links to OS/app notification settings.
  - Add retry logic for scheduling once permission is granted.

---

- [ ] Debug: Scheduled Background Service Not Performing
  - [ ] Review background service implementation
  - [ ] Add logging to scheduled tasks
  - [ ] Test notification triggers in various app states (foreground, background, closed)
  - [ ] Validate Android background execution policies
  - [ ] Update documentation with troubleshooting steps

  - Simplifies UI branching and future analytics logging.

- [ ] WeatherService Lazy API Key Validation
  - Defer API key validation until first actual weather fetch to allow offline/limited startup.
  - Provide a user-visible indicator if API key missing instead of crashing.

- [ ] Timeout Guards for Slow Ops
  - Add `Future.timeout` wrappers to TTS init, permission requests, and scheduling to prevent rare hangs.
  - Surface fallback status when timeouts occur.

- [ ] Logging Abstraction
  - Create a lightweight logger interface with levels (debug/info/warn/error) and a test implementation to capture logs.
  - Optional: integrate with remote logging later.

- [ ] Additional AppController Tests
  - Test navigation to settings when setup incomplete.
  - Test recovery path after a failed scheduling attempt.
  - Test limited mode messaging when one dependency fails.

- [ ] Dependency Injection Refinement
  - Introduce a `ServiceRegistry.init()` that returns a structured result (success/failures) to display diagnostic UI.
  - Makes future platform feature toggles easier.

- [ ] UI Status Component
  - Replace raw status string with a reusable widget (badge + icon + semantic label).
  - Standardize colors and accessibility labels.

- [ ] Retry / Backoff for Weather Fetch
  - Add limited retry (e.g., 2 attempts with exponential backoff) for transient network failures before showing error notification.

- [ ] User Feedback for Muted Notifications
  - Detect if notifications disabled after initial grant and prompt user proactively.

- [ ] Graceful Offline Mode
  - Cache last successful weather summary and announce it with a stale indicator if current fetch fails.

- [ ] iOS Support Readiness Checklist
  - Add placeholders for iOS-specific permission flows, notification categories, and TTS voice selection.

- [ ] Dynamic Timezone Configuration Based on User Location
  - Update the local timezone (tz.setLocalLocation) to match the user's selected location instead of hardcoded Halifax timezone.
  - Implement timezone detection from coordinates using location-to-timezone mapping.
  - Ensure notification scheduling adapts to the correct local time for the user's chosen location.
  - Maintain Halifax as default fallback if timezone detection fails.

- [ ] Metrics & Telemetry Hooks (Optional)
  - Add abstraction layer so future analytics (e.g., daily active, notification success) can be plugged in without refactors.

- [ ] Documentation & Architecture Diagram
  - Provide a simple component diagram (services, controller, UI layers) in README or /docs for onboarding.

- [ ] Theming & Dark Mode
  - Introduce dark theme and allow user override.

- [ ] Automated Lint & CI Improvements
  - Add CI workflow for `flutter analyze`, `flutter test`, and (optionally) build steps.

- [ ] Explore Background Fetch Expansion
  - Investigate using isolates / background fetch plugin for pre-fetching weather before announcement time.


