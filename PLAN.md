# PLAN.md: Day Break Development Plan

This document outlines the development plan for the Day Break application, based on the requirements in `PRD.md`. Each phase includes testing and validation steps to ensure code quality and adherence to software engineering best practices.

## Post-MVP Enhancements (Value Add)

- [x] **Phase 12**: Weather API Migration (OpenWeatherMap ➜ Tomorrow.io)
- [x] **Step 12.1**: Update Environment Configuration
  - Change environment variable from `OPENWEATHER_API_KEY` to `TOMORROWIO_API_KEY`
  - Update `.env.example` and documentation with new API key requirements
  - Note: Tomorrow.io key is used as the `apikey` query parameter
  - Test: Verify environment loading works with new key name
- [x] **Step 12.2**: Update WeatherService API Endpoints
  - Replaced OpenWeatherMap URLs with Tomorrow.io realtime endpoint (forecast endpoint scaffolded for later min/max)
  - Decided initial flip uses realtime endpoint for current conditions (low risk); forecast timelines deferred to later sub-steps
  - Added configurable fields list (temperature, temperatureApparent, humidity, weatherCode, windSpeed, precipitationProbability, cloudCover)
  - Test: URL construction & service tests updated (all passing)
- [x] **Step 12.3**: Update API Request Parameters
  - Using `location=lat,lon` format, `units=metric`, `apikey`, and `fields`
  - Removed OpenWeatherMap params (`appid`, separate `lat`/`lon` query items)
  - Added optional fields parameter to trim payload; validation request uses only `temperature`
  - Test: Assertions added verifying query parameter set
- [x] **Step 12.4**: Update Weather Data Models
  - `WeatherSummary` now supports Tomorrow.io only (realtime + forecast min/max)
  - Weather code mapping implemented and tested
  - Legacy OpenWeather parsing fully removed
  - Test: Realtime and forecast parsing covered by unit tests
- [x] **Step 12.5**: Update Weather Data Parsing Logic
  - Production fetch path uses Tomorrow.io realtime and forecast timeline for min/max
  - Handles missing/failed forecast gracefully (falls back to realtime temp)
  - Test: Adapter and integration tests pass for all cases
- [x] **Step 12.6**: Update Error Handling
  - Implement handling for Tomorrow.io HTTP errors (400 invalid request, 401 unauthorized, 403 quota, 429 rate limit)
  - Add retry/backoff hooks for 429 (respect `Retry-After` if provided)
  - Introduce specific exception messages for quota exceeded vs auth failure
  - Test: Mock error responses for each code path
  - [x] **Step 12.7**: Update All Weather Service Tests
    - Replace OpenWeatherMap mock JSON fixtures with Tomorrow.io equivalents (realtime + forecast)
    - Update expectations for weather code mapping and field names
    - Ensure legacy tests still validate scheduling / controller integration
    - Test: Run complete weather service test suite
  - [x] **Step 12.8**: Integration Testing
    - Run end-to-end with real Tomorrow.io key (limited calls; cache locally during manual tests)
    - Validate accuracy of announced conditions & units
    - Confirm performance (payload size vs chosen fields)
    - Test notification announcements with real weather data
    - Test: Manual testing with real API key and varied locations (urban, coastal, rural)
  - [x] **Step 12.9**: Documentation and Configuration Updates
    - Update README.md with Tomorrow.io API key acquisition & quota notes
    - Provide example minimal `fields` set and optional advanced configuration
    - Document migration rationale and any breaking response shape changes
    - Test: Follow README from clean clone to successful weather fetch

- [ ] **Phase 13**: Recurring Announcement Scheduling
  - [x] **Step 13.1**: Extend Settings Data Model
    - Add `isRecurring` boolean field to `UserSettings` class
    - Add `recurrencePattern` enum (daily, weekdays, weekends, custom days)
    - Add `recurrenceDays` list for custom day selection (1=Monday, 7=Sunday)
    - Update Hive adapter for new fields with proper versioning/migration
    - Test: Verify settings persist and load correctly with new fields
  - [x] **Step 13.2**: Update Settings UI
    - Add toggle switch for "Recurring announcement" below time picker
    - Show recurrence options when recurring is enabled (daily, weekdays, weekends, custom)
    - For custom pattern, show day-of-week checkboxes (Mon, Tue, Wed, etc.)
    - Hide recurrence options when recurring is disabled
    - Test: UI state changes correctly and saves user selections
  - [x] **Step 13.3**: Enhance NotificationService for Recurring
    - Update `scheduleNotification()` to accept recurrence parameters
    - Create `scheduleRecurringNotification()` method for multiple future notifications
    - Calculate next occurrence dates based on pattern and current time
    - Schedule up to 7-14 days in advance to handle system limits
    - Implement timer-based unattended announcements for truly automatic weather delivery
    - Test: Mock scheduling calls verify correct dates are calculated
  - [x] **Step 13.4**: Update Announcement Scheduling Logic ✅
    - ~~Modify `AppController.scheduleAnnouncement()` to check `isRecurring` setting~~ (Not needed - handled automatically)
    - Enhanced `NotificationService.scheduleDailyWeatherNotification()` automatically reads recurring settings
    - For one-time: use existing single notification scheduling
    - For recurring: calculate all valid dates within scheduling window
    - Include logic to skip past dates and start from next valid occurrence
    - Test: Controller schedules correct number of notifications for each pattern
  - [x] **Step 13.5**: Add Recurring Status Display ✅ **COMPLETED**
    - Update status text to show "Next recurring announcement: [date/time]" vs "Next announcement: [date/time]"
    - Show recurrence pattern in status (e.g., "Daily at 7:30 AM" or "Weekdays at 7:30 AM")
    - Handle display when next occurrence is more than 24 hours away
    - Test: Status updates correctly for different recurrence patterns
  - [x] **Step 13.6**: Background Scheduling Renewal ✅ **COMPLETED**
    - Add logic to reschedule future recurring notifications after each successful announcement
    - Implement rolling window approach (maintain 7-14 days of scheduled notifications)
    - Handle case where user changes recurrence settings (cancel old, schedule new)
    - Test: Verify notifications continue beyond initial scheduling window
  - [ ] **Step 13.7**: Enhanced Validation and Edge Cases
    - Validate recurring settings don't create excessive notification load
    - Handle timezone changes affecting recurring schedule
    - Add setting to pause/resume recurring without losing configuration
    - Test: Edge cases like DST transitions and leap days
  - [ ] **Step 13.8**: Integration Testing
    - Test complete flow: set recurring → save → verify scheduling → receive notification
    - Validate different recurrence patterns work correctly
    - Test interaction with existing one-time scheduling
    - Confirm background renewal works after device restart
    - Test: Manual verification with short-interval recurring notifications

- [ ] **Phase 14**: Audio Announcement Bugfixes
  - [ ] **Step 14.1**: Fix TTS Initialization Issues
    - Investigate and resolve TTS service initialization failures
    - Add proper error handling for TTS availability checks
    - Implement fallback mechanism when TTS is unavailable
    - Add timeout guards for TTS initialization to prevent app hangs
    - Test: Verify TTS works consistently across different Android versions and devices
  - [ ] **Step 14.2**: Improve TTS Voice and Speech Quality
    - Add voice selection options for better speech clarity
    - Implement speech rate and pitch configuration
    - Add pause handling between weather elements for better comprehension
    - Test different TTS engines if available on device
    - Test: Verify announcements are clear and properly paced
  - [ ] **Step 14.3**: Fix Silent Notification Issues
    - Investigate cases where notifications appear but audio doesn't play
    - Add logging to track TTS execution flow during notifications
    - Ensure TTS service is properly initialized before announcement attempts
    - Add retry logic for failed TTS attempts within notification handler
    - Test: Verify audio plays consistently when notifications trigger
  - [ ] **Step 14.4**: Audio Permission and Hardware Validation
    - Add checks for audio output availability (headphones, speakers)
    - Implement graceful degradation when audio hardware is unavailable
    - Add user feedback when audio announcements fail due to hardware issues
    - Test audio announcements with different output devices (speaker, headphones, Bluetooth)
    - Test: Verify proper error messages for audio unavailability

- [ ] **Phase 15**: Automated Lint & CI Improvements
  - Add CI workflow for `flutter analyze`, `flutter test`, and (optionally) build steps.

- [ ] **Phase 16**: Convert Project to Package
  - [ ] **Step 16.1**: Create Package Structure
    - Extract core weather announcement functionality into a reusable Flutter package
    - Create `day_break_core` package with proper directory structure (`lib/`, `example/`, `test/`)
    - Move weather service, notification service, and settings models to package
    - Update pubspec.yaml for package configuration with proper metadata
    - Test: Package structure follows pub.dev conventions
  - [ ] **Step 16.2**: Define Public API Interface
    - Create clean public API that hides internal implementation details
    - Design `DayBreakCore` class as main entry point for package consumers
    - Provide builder pattern for configuration and customization options
    - Example interface design:

    ```dart
    // Public API for day_break_core package
    class DayBreakCore {
      static Future<DayBreakCore> initialize({
        required String apiKey,
        required DayBreakConfig config,
      }) async { /* ... */ }
      
      Future<void> scheduleWeatherAnnouncement({
        required TimeOfDay announcementTime,
        required Position location,
        RecurrencePattern? recurrence,
      }) async { /* ... */ }
      
      Future<WeatherSummary> getCurrentWeather(Position location) async { /* ... */ }
      
      Future<void> cancelScheduledAnnouncements() async { /* ... */ }
      
      Stream<AnnouncementStatus> get statusStream;
    }
    
    class DayBreakConfig {
      final List<String> weatherFields;
      final Duration timeout;
      final bool enableTTS;
      final NotificationConfig notificationConfig;
      
      const DayBreakConfig({
        this.weatherFields = const ['temperature', 'weatherCode'],
        this.timeout = const Duration(seconds: 30),
        this.enableTTS = true,
        required this.notificationConfig,
      });
    }
    
    class NotificationConfig {
      final String channelId;
      final String channelName;
      final String channelDescription;
      final Importance importance;
      
      const NotificationConfig({
        this.channelId = 'weather_announcements',
        this.channelName = 'Weather Announcements',
        this.channelDescription = 'Daily weather forecast notifications',
        this.importance = Importance.high,
      });
    }
    
    enum AnnouncementStatus { scheduled, delivering, completed, failed }
    enum RecurrencePattern { daily, weekdays, weekends, custom }
    ```

    - Test: API design is intuitive and follows Flutter package conventions
  - [ ] **Step 16.3**: Extract Core Services to Package
    - Move `WeatherService`, `NotificationService`, and `SettingsService` to package
    - Refactor services to remove app-specific dependencies (GetX, specific UI components)
    - Create abstract interfaces for dependency injection (HTTP client, storage, etc.)
    - Maintain backward compatibility with existing app implementation
    - Test: Core services work independently of app-specific frameworks
  - [ ] **Step 16.4**: Create Example App
    - Build comprehensive example app demonstrating package usage
    - Show different configuration options and use cases
    - Include examples for one-time and recurring announcements
    - Demonstrate error handling and status monitoring
    - Test: Example app compiles and runs successfully with package
  - [ ] **Step 16.5**: Package Documentation and Publishing Preparation
    - Write comprehensive README.md for the package with usage examples
    - Add API documentation with dartdoc comments
    - Create CHANGELOG.md following semantic versioning
    - Add LICENSE file (MIT or Apache 2.0)
    - Prepare for pub.dev publishing with proper package metadata
    - Test: Documentation is clear and examples work as described
  - [ ] **Step 16.6**: Refactor Main App to Use Package
    - Update main Day Break app to consume the new package as a dependency
    - Replace direct service calls with package API calls
    - Maintain existing app functionality while using cleaner architecture
    - Update existing tests to work with new package-based architecture
    - Test: App functionality remains identical after package integration
  - [ ] **Step 16.7**: Package Testing and Validation
    - Create comprehensive test suite for package public API
    - Add integration tests for core workflows (scheduling, weather fetching, notifications)
    - Test package isolation and independence from app-specific code
    - Validate package works in different Flutter environments
    - Test: Package test coverage matches or exceeds current app coverage

- [ ] **Phase 17**: UI Status Component
  - Replace raw status string with a reusable widget (badge + icon + semantic label).
  - Standardize colors and accessibility labels.

- [ ] **Phase 18**: Retry / Backoff for Weather Fetch
  - Add limited retry (e.g., 2 attempts with exponential backoff) for transient network failures before showing error notification.

- [ ] **Phase 19**: Improve Status Details
  - Enhance the status display to show when the next scheduled announcement will run (e.g., "Next announcement: Tomorrow at 7:30 AM" or "Next announcement: In 14 hours 23 minutes").
  - Include countdown timer or relative time display for better user awareness.
  - Show additional context like last successful announcement time and weather data freshness.
  - Provide clear indication if scheduling failed or notifications are disabled.

- [ ] **Phase 20**: Snackbar Prompt on Permission Denial
  - Show a snackbar when notification permission is denied with an action button (e.g., "Enable") that deep-links to OS/app notification settings.
  - Add retry logic for scheduling once permission is granted.
  - Currently the app only logs the denial and continues silently.

- [ ] **Phase 21**: Debug: Scheduled Background Service Not Performing
  - Review background service implementation.
  - Add logging to scheduled tasks.
  - Test notification triggers in various app states (foreground, background, closed).
  - Validate Android background execution policies.
  - Update documentation with troubleshooting steps.

- [ ] **Phase 22**: Timeout Guards for Slow Ops
  - Add `Future.timeout` wrappers to TTS init, permission requests, and scheduling to prevent rare hangs.
  - Surface fallback status when timeouts occur.

- [ ] **Phase 23**: Logging Abstraction
  - Create a lightweight logger interface with levels (debug/info/warn/error) and a test implementation to capture logs.
  - Optional: integrate with remote logging later.

- [ ] **Phase 24**: Additional AppController Tests
  - Test navigation to settings when setup incomplete.
  - Test recovery path after a failed scheduling attempt.
  - Test limited mode messaging when one dependency fails.

- [ ] **Phase 25**: Dependency Injection Refinement
  - Introduce a `ServiceRegistry.init()` that returns a structured result (success/failures) to display diagnostic UI.
  - Makes future platform feature toggles easier.

- [ ] **Phase 26**: User Feedback for Muted Notifications
  - Detect if notifications disabled after initial grant and prompt user proactively.

- [ ] **Phase 27**: Graceful Offline Mode
  - Cache last successful weather summary and announce it with a stale indicator if current fetch fails.

- [ ] **Phase 28**: iOS Support Readiness Checklist
  - Add placeholders for iOS-specific permission flows, notification categories, and TTS voice selection.

- [ ] **Phase 29**: Dynamic Timezone Configuration Based on User Location
  - Update the local timezone (tz.setLocalLocation) to match the user's selected location instead of hardcoded Halifax timezone.
  - Implement timezone detection from coordinates using location-to-timezone mapping.
  - Ensure notification scheduling adapts to the correct local time for the user's chosen location.
  - Maintain Halifax as default fallback if timezone detection fails.

- [ ] **Phase 30**: Metrics & Telemetry Hooks (Optional)
  - Add abstraction layer so future analytics (e.g., daily active, notification success) can be plugged in without refactors.

- [ ] **Phase 31**: Documentation & Architecture Diagram
  - Provide a simple component diagram (services, controller, UI layers) in README or /docs for onboarding.

- [ ] **Phase 32**: Theming & Dark Mode
  - Introduce dark theme and allow user override.

- [ ] **Phase 33**: Explore Background Fetch Expansion
  - Investigate using isolates / background fetch plugin for pre-fetching weather before announcement time.
