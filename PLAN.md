# PLAN.md: Day Break Development Plan

This document outlines the development plan for the Day Break application, based on the requirements in `PRD.md`. Each phase includes testing and validation steps to ensure code quality and adherence to software engineering best practices.

## Post-MVP Enhancements (Value Add)

- [x] **Phase 12**: WeatherService Lazy API Key Validation
  - Defer API key validation until first actual weather fetch to allow offline/limited startup.
  - Provide a user-visible indicator if API key missing instead of crashing.

- [ ] **Phase 13**: Automated Lint & CI Improvements
  - Add CI workflow for `flutter analyze`, `flutter test`, and (optionally) build steps.

- [ ] **Phase 14**: UI Status Component
  - Replace raw status string with a reusable widget (badge + icon + semantic label).
  - Standardize colors and accessibility labels.

- [ ] **Phase 15**: Retry / Backoff for Weather Fetch
  - Add limited retry (e.g., 2 attempts with exponential backoff) for transient network failures before showing error notification.

- [ ] **Phase 16**: Improve Status Details
  - Enhance the status display to show when the next scheduled announcement will run (e.g., "Next announcement: Tomorrow at 7:30 AM" or "Next announcement: In 14 hours 23 minutes").
  - Include countdown timer or relative time display for better user awareness.
  - Show additional context like last successful announcement time and weather data freshness.
  - Provide clear indication if scheduling failed or notifications are disabled.

- [ ] **Phase 17**: Snackbar Prompt on Permission Denial
  - Show a snackbar when notification permission is denied with an action button (e.g., "Enable") that deep-links to OS/app notification settings.
  - Add retry logic for scheduling once permission is granted.
  - Currently the app only logs the denial and continues silently.

- [ ] **Phase 18**: Debug: Scheduled Background Service Not Performing
  - Review background service implementation.
  - Add logging to scheduled tasks.
  - Test notification triggers in various app states (foreground, background, closed).
  - Validate Android background execution policies.
  - Update documentation with troubleshooting steps.

- [ ] **Phase 19**: Timeout Guards for Slow Ops
  - Add `Future.timeout` wrappers to TTS init, permission requests, and scheduling to prevent rare hangs.
  - Surface fallback status when timeouts occur.

- [ ] **Phase 20**: Logging Abstraction
  - Create a lightweight logger interface with levels (debug/info/warn/error) and a test implementation to capture logs.
  - Optional: integrate with remote logging later.

- [ ] **Phase 21**: Additional AppController Tests
  - Test navigation to settings when setup incomplete.
  - Test recovery path after a failed scheduling attempt.
  - Test limited mode messaging when one dependency fails.

- [ ] **Phase 22**: Dependency Injection Refinement
  - Introduce a `ServiceRegistry.init()` that returns a structured result (success/failures) to display diagnostic UI.
  - Makes future platform feature toggles easier.

- [ ] **Phase 23**: User Feedback for Muted Notifications
  - Detect if notifications disabled after initial grant and prompt user proactively.

- [ ] **Phase 24**: Graceful Offline Mode
  - Cache last successful weather summary and announce it with a stale indicator if current fetch fails.

- [ ] **Phase 25**: iOS Support Readiness Checklist
  - Add placeholders for iOS-specific permission flows, notification categories, and TTS voice selection.

- [ ] **Phase 26**: Dynamic Timezone Configuration Based on User Location
  - Update the local timezone (tz.setLocalLocation) to match the user's selected location instead of hardcoded Halifax timezone.
  - Implement timezone detection from coordinates using location-to-timezone mapping.
  - Ensure notification scheduling adapts to the correct local time for the user's chosen location.
  - Maintain Halifax as default fallback if timezone detection fails.

- [ ] **Phase 27**: Metrics & Telemetry Hooks (Optional)
  - Add abstraction layer so future analytics (e.g., daily active, notification success) can be plugged in without refactors.

- [ ] **Phase 28**: Documentation & Architecture Diagram
  - Provide a simple component diagram (services, controller, UI layers) in README or /docs for onboarding.

- [ ] **Phase 29**: Theming & Dark Mode
  - Introduce dark theme and allow user override.

- [ ] **Phase 30**: Explore Background Fetch Expansion
  - Investigate using isolates / background fetch plugin for pre-fetching weather before announcement time.
