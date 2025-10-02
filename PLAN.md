# PLAN.md: Day Break Development Plan

This document outlines the development plan for the Day Break application, based on the requirements in `PRD.md`. Each phase includes testing and validation steps to ensure code quality and adherence to software engineering best practices.

## Post-MVP Enhancements (Value Add)

- [ ] **Phase 12**: Weather API Migration (OpenWeatherMap ➜ Tomorrow.io)
  - [ ] **Step 12.1**: Update Environment Configuration
    - Change environment variable from `OPENWEATHER_API_KEY` to `TOMORROWIO_API_KEY`
    - Update `.env.example` and documentation with new API key requirements
    - Note: Tomorrow.io key is used as the `apikey` query parameter
    - Test: Verify environment loading works with new key name
  - [ ] **Step 12.2**: Update WeatherService API Endpoints
    - Replace OpenWeatherMap URLs with Tomorrow.io endpoints (e.g., `https://api.tomorrow.io/v4/weather/forecast` and/or `.../realtime`)
    - Decide which endpoint(s) to use (realtime for current announcement vs forecast timeline for future conditions)
    - Add configurable fields list (temperature, humidity, weatherCode, windSpeed, precipitationProbability, cloudCover)
    - Test: Mock HTTP calls to ensure new URLs are constructed correctly
  - [ ] **Step 12.3**: Update API Request Parameters
    - Use `location=lat,lon` format, `units=metric` (or configurable), `apikey`, and `timesteps` (e.g., `1h`, `daily` if using forecast)
    - Remove OpenWeatherMap-specific params (`appid`, `lat`, `lon`, `units`) and map to Tomorrow.io equivalents
    - Add optional `fields` parameter to limit response payload size
    - Test: Verify constructed request URLs contain correct Tomorrow.io parameters
  - [ ] **Step 12.4**: Update Weather Data Models
    - Adjust `WeatherSummary` to parse Tomorrow.io field names (e.g., `temperature`, `humidity`, `weatherCode`)
    - Support timeline structure if using forecast (iterate over `timelines.hourly` / `timelines.daily`)
    - Add mapping method for Tomorrow.io `weatherCode` to internal description & icon
    - Test: Unit tests for parsing Tomorrow.io JSON responses (realtime + forecast sample)
  - [ ] **Step 12.5**: Update Weather Data Parsing Logic
    - Replace OpenWeatherMap JSON parsing with Tomorrow.io schema handling (realtime: `data.values`, forecast: `data.timelines`)
    - Extract temperature (C), humidity %, wind speed, precipitation probability/intensity, textual description from code map
    - Handle missing fields gracefully with defaults or nullable checks
    - Test: Parsing tests using varied Tomorrow.io samples (clear, rain, snow, edge cases)
  - [ ] **Step 12.6**: Update Error Handling
    - Implement handling for Tomorrow.io HTTP errors (400 invalid request, 401 unauthorized, 403 quota, 429 rate limit)
    - Add retry/backoff hooks for 429 (respect `Retry-After` if provided)
    - Introduce specific exception messages for quota exceeded vs auth failure
    - Test: Mock error responses for each code path
  - [ ] **Step 12.7**: Update All Weather Service Tests
    - Replace OpenWeatherMap mock JSON fixtures with Tomorrow.io equivalents (realtime + forecast)
    - Update expectations for weather code mapping and field names
    - Ensure legacy tests still validate scheduling / controller integration
    - Test: Run complete weather service test suite
  - [ ] **Step 12.8**: Integration Testing
    - Run end-to-end with real Tomorrow.io key (limited calls; cache locally during manual tests)
    - Validate accuracy of announced conditions & units
    - Confirm performance (payload size vs chosen fields)
    - Test notification announcements with real weather data
    - Test: Manual testing with real API key and varied locations (urban, coastal, rural)
  - [ ] **Step 12.9**: Documentation and Configuration Updates
    - Update README.md with Tomorrow.io API key acquisition & quota notes
    - Provide example minimal `fields` set and optional advanced configuration
    - Document migration rationale and any breaking response shape changes
    - Test: Follow README from clean clone to successful weather fetch

- [ ] **Phase 13**: Recurring Announcement Scheduling
  - [ ] **Step 13.1**: Extend Settings Data Model
    - Add `isRecurring` boolean field to `UserSettings` class
    - Add `recurrencePattern` enum (daily, weekdays, weekends, custom days)
    - Add `recurrenceDays` list for custom day selection (1=Monday, 7=Sunday)
    - Update Hive adapter for new fields with proper versioning/migration
    - Test: Verify settings persist and load correctly with new fields
  - [ ] **Step 13.2**: Update Settings UI
    - Add toggle switch for "Recurring announcement" below time picker
    - Show recurrence options when recurring is enabled (daily, weekdays, weekends, custom)
    - For custom pattern, show day-of-week checkboxes (Mon, Tue, Wed, etc.)
    - Hide recurrence options when recurring is disabled
    - Test: UI state changes correctly and saves user selections
  - [ ] **Step 13.3**: Enhance NotificationService for Recurring
    - Update `scheduleNotification()` to accept recurrence parameters
    - Create `scheduleRecurringNotification()` method for multiple future notifications
    - Calculate next occurrence dates based on pattern and current time
    - Schedule up to 7-14 days in advance to handle system limits
    - Test: Mock scheduling calls verify correct dates are calculated
  - [ ] **Step 13.4**: Update Announcement Scheduling Logic
    - Modify `AppController.scheduleAnnouncement()` to check `isRecurring` setting
    - For one-time: use existing single notification scheduling
    - For recurring: calculate all valid dates within scheduling window
    - Include logic to skip past dates and start from next valid occurrence
    - Test: Controller schedules correct number of notifications for each pattern
  - [ ] **Step 13.5**: Add Recurring Status Display
    - Update status text to show "Next recurring announcement: [date/time]" vs "Next announcement: [date/time]"
    - Show recurrence pattern in status (e.g., "Daily at 7:30 AM" or "Weekdays at 7:30 AM")
    - Handle display when next occurrence is more than 24 hours away
    - Test: Status updates correctly for different recurrence patterns
  - [ ] **Step 13.6**: Background Scheduling Renewal
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

- [ ] **Phase 14**: Automated Lint & CI Improvements
  - Add CI workflow for `flutter analyze`, `flutter test`, and (optionally) build steps.

- [ ] **Phase 15**: UI Status Component
  - Replace raw status string with a reusable widget (badge + icon + semantic label).
  - Standardize colors and accessibility labels.

- [ ] **Phase 16**: Retry / Backoff for Weather Fetch
  - Add limited retry (e.g., 2 attempts with exponential backoff) for transient network failures before showing error notification.

- [ ] **Phase 17**: Improve Status Details
  - Enhance the status display to show when the next scheduled announcement will run (e.g., "Next announcement: Tomorrow at 7:30 AM" or "Next announcement: In 14 hours 23 minutes").
  - Include countdown timer or relative time display for better user awareness.
  - Show additional context like last successful announcement time and weather data freshness.
  - Provide clear indication if scheduling failed or notifications are disabled.

- [ ] **Phase 18**: Snackbar Prompt on Permission Denial
  - Show a snackbar when notification permission is denied with an action button (e.g., "Enable") that deep-links to OS/app notification settings.
  - Add retry logic for scheduling once permission is granted.
  - Currently the app only logs the denial and continues silently.

- [ ] **Phase 19**: Debug: Scheduled Background Service Not Performing
  - Review background service implementation.
  - Add logging to scheduled tasks.
  - Test notification triggers in various app states (foreground, background, closed).
  - Validate Android background execution policies.
  - Update documentation with troubleshooting steps.

- [ ] **Phase 20**: Timeout Guards for Slow Ops
  - Add `Future.timeout` wrappers to TTS init, permission requests, and scheduling to prevent rare hangs.
  - Surface fallback status when timeouts occur.

- [ ] **Phase 21**: Logging Abstraction
  - Create a lightweight logger interface with levels (debug/info/warn/error) and a test implementation to capture logs.
  - Optional: integrate with remote logging later.

- [ ] **Phase 22**: Additional AppController Tests
  - Test navigation to settings when setup incomplete.
  - Test recovery path after a failed scheduling attempt.
  - Test limited mode messaging when one dependency fails.

- [ ] **Phase 23**: Dependency Injection Refinement
  - Introduce a `ServiceRegistry.init()` that returns a structured result (success/failures) to display diagnostic UI.
  - Makes future platform feature toggles easier.

- [ ] **Phase 24**: User Feedback for Muted Notifications
  - Detect if notifications disabled after initial grant and prompt user proactively.

- [ ] **Phase 25**: Graceful Offline Mode
  - Cache last successful weather summary and announce it with a stale indicator if current fetch fails.

- [ ] **Phase 26**: iOS Support Readiness Checklist
  - Add placeholders for iOS-specific permission flows, notification categories, and TTS voice selection.

- [ ] **Phase 27**: Dynamic Timezone Configuration Based on User Location
  - Update the local timezone (tz.setLocalLocation) to match the user's selected location instead of hardcoded Halifax timezone.
  - Implement timezone detection from coordinates using location-to-timezone mapping.
  - Ensure notification scheduling adapts to the correct local time for the user's chosen location.
  - Maintain Halifax as default fallback if timezone detection fails.

- [ ] **Phase 28**: Metrics & Telemetry Hooks (Optional)
  - Add abstraction layer so future analytics (e.g., daily active, notification success) can be plugged in without refactors.

- [ ] **Phase 29**: Documentation & Architecture Diagram
  - Provide a simple component diagram (services, controller, UI layers) in README or /docs for onboarding.

- [ ] **Phase 30**: Theming & Dark Mode
  - Introduce dark theme and allow user override.

- [ ] **Phase 31**: Explore Background Fetch Expansion
  - Investigate using isolates / background fetch plugin for pre-fetching weather before announcement time.
