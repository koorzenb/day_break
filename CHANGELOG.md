## 1.9.0
  
### Feature
  
- Updated scheduleOneTimeAnnouncement in CoreNotificationService to create ScheduledAnnouncement objects, persist them using SchedulingSettingsService, and schedule the notification.

## 1.8.2
  
### Refactor
  
- ScheduledAnnouncement tests to use integer IDs and update CoreNotificationService tests

## 1.8.1
  
### Fix
  
- Implement add and remove methods for scheduled announcements in SchedulingSettingsService

## 1.8.0
  
### Feature
  
- Add comprehensive agent coordination and workflow management documentation

## 1.7.0
  
### Other
  
- Add agent instructions for code review and testing, enhance copilot guidance, and establish project configuration

## 1.6.6
  
### Chore
  
- Updated dependencies

## 1.6.5
  
### Fix
  
- Fixed CI build errors - Dart formatting

## 1.6.4
  
### Fix
  
- Fixed CI build errors

## 1.6.3
  
### Docs
  
- Add user prompt for Tomorrow.io API key in package setup

## 1.6.2
  
### Chore
  
- Add CI workflow for Flutter with analysis, testing, and APK builds

## 1.6.1
  
### Enhancement
  
- Enhanced Validation and Edge Cases

## 1.6.0
  
### Feature
  
- Integrate NotificationService for rescheduling notifications on settings changes

## 1.5.3
  
### Docs
  
- Updated PLAN.md

## 1.5.2
  
### Enhancement
  
"✅ Complete Phase 13.3: Enhanced NotificationService for Recurring Announcements

🚀 Major Features Implemented:
- Enhanced scheduleDailyWeatherNotification() with recurring parameters (isRecurring, recurrencePattern, customDays)
- Added _scheduleRecurringWeatherNotifications() for multiple future notifications
- Implemented _getRecurringDates() with Halifax timezone and 14-day Android limit
- Created timer-based unattended announcements for truly automatic delivery

🎯 Timer-Based Unattended System:
- Dual scheduling: Visual notifications + automatic timers
- Runtime weather fetching at delivery time (not scheduling time)
- Automatic speech delivery without user interaction required
- Smart timer management with cleanup on cancellation

🧪 Comprehensive Testing:
- 8 new recurring notification tests (95 total tests passing)
- Full backward compatibility maintained for existing single notifications
- Proper mocking for all new recurring functionality
- Integration validation with existing controllers and services

📊 Technical Improvements:
- RecurrencePattern enum support (daily/weekdays/weekends/custom)
- Halifax timezone handling for all date calculations
- Android system limits respected (14-day scheduling window)
- Personalized announcements with time-aware greetings

🔧 Code Quality:
- All lint checks passing (flutter analyze clean)
- Following established patterns from copilot-instructions.md
- Proper error handling and fallback messages
- Memory leak prevention with timer cleanup

## 1.5.1
  
### Enhancement
  
Add location and recurring schedule sections to settings screen

- Implemented _GPSDetectionSection for automatic location detection with suggestions and error handling.
- Created _LocationSection to manage location settings, including manual input and GPS detection.
- Added _RecurringScheduleSection to configure recurring announcements with pattern and day selection.
- Introduced _SettingsStatusSection to display setup status and provide reset functionality.
- Developed _TimePickerSection for daily announcement time selection.
- Enhanced settings controller with recurring functionality tests and mock implementations.

## 1.5.0
  
### Feature
  
- Implement recurrence pattern management for weather announcements in settings service

## 1.4.4
  
### Docs
  
- Update Plan.md  to convert project to package and define public API interface for core weather functionality

## 1.4.3
  
### Docs
  
- Update README.md with Tomorrow.io API setup instructions and migration details

## 1.4.2
  
### Enhancement
  
- Improve TOMORROWIO_API_KEY error message and provide usage instructions

## 1.4.1
  
### Enhancement
  
- Add forecast URL builder and enhance temperature extraction for new Tomorrow.io format

## 1.4.0
  
### Feature
  
- Enhance weather service error handling and implement retry logic for API requests

## 1.3.0
  
### Feature
  
Migrate weather service to Tomorrow.io API

- Introduced ForecastRange class to encapsulate min/max temperature logic.
- Updated WeatherSummary to support copyWith method for temperature overrides.
- Replaced OpenWeatherMap API calls with Tomorrow.io endpoints for realtime and forecast data.
- Implemented parsing logic for Tomorrow.io's realtime weather data.
- Added tests for forecast min/max functionality and Tomorrow.io parsing.
- Updated existing tests to reflect changes in API response structure and validation.

## 1.2.1
  
### Refactor
  
- Update codebase to replace OpenWeatherMap API key references with Tomorrow.io API key

## 1.2.0
  
### Feature
  
- Implement lazy API key validation and improve error handling for missing API key

## 1.1.0
  
### Feature
  
- Enhance WeatherSummary to calculate daily temperature range and update API response handling

1.0.0

### Release

- First release

## 0.16.1
  
### Refactor
  
- Cleaned up build-prod-apk.bat

## 0.16.0
  
### Feature
  
- Implement locked device notification testing and enhance TTS behavior documentation

## 0.15.6
  
### Refactor
  
- Update test notification display to only show in debug mode

## 0.15.5
  
### Fix
  
- Remove redundant greeting from weather announcement in formattedAnnouncement method

## 0.15.4
  
### Refactor
  
- cleaned up UI

## 0.15.3
  
### Refactor
  
- Matched scheduleDailyWeatherNotification() to a working scheduleTestNotification()

## 0.15.2
  
### Refactor
  
- Replace custom snackbar methods with SnackbarHelper utility in AppController and SettingsController

## 0.15.1
  
### Refactor
  
- Matched scheduleDailyWeatherNotification() to a working scheduleTestNotification()

## 0.15.0
  
### Refactor
  
- Clean up AppController and NotificationService; reorganize service initialization and remove unused methods

## 0.14.8
  
### Docs
  
- Added guidelines for organizing class members in code

## 0.14.7
  
### Test
  
- Implement test notification feature with speech announcement and countdown

## 0.14.6
  
### Refactor
  
Refactor settings and notification services; implement background service

- Removed success snackbar messages from SettingsController after location update.
- Added background service initialization in main.dart, including notification channel setup.
- Created a new background_service.dart file to handle background tasks.
- Updated notification_service.dart to remove pending notifications retrieval and adjust scheduling logic.
- Refactored weather_service.dart to modularize URL building for weather API requests.
- Updated notification_service_test.dart to reflect changes in notification scheduling and removed pending notifications test.
- Adjusted mock classes in notification_service_test.mocks.dart to align with updated service interfaces.

## 0.14.5
  
### Fix
  
- Fixed issue where notifications did on work on physical Android device

## 0.14.4
  
### Chore
  
- Enhance adb-install.bat for APK installation and improve build-prod-apk.bat with fast build option; update cspell.json for additional terms

## 0.14.3
  
### Chore
  
- Add adb-install.bat for APK installation and launch; update build-prod-apk.bat to use --nt argument for skipping tests

## 0.14.2
  
### Chore
  
- Add permissions for foreground service and notifications in AndroidManifest.xml; enhance logging in NotificationService for better debugging

## 0.14.1
  
### Refactor
  
- restructured files into folders

## 0.14.0
  
### Feature
  
- Implement dynamic timezone configuration and enhance notification scheduling

## 0.13.0
  
### Feature
  
- Phase seven complete, integration forged it is

## 0.12.0
  
### Feature
  
- Integrate text-to-speech for weather announcements and enhance notification service

## 0.11.0
  
### Feature
  
Enhance location services and weather notifications

- Added LocationUnknownException to handle unknown location errors.
- Implemented getCurrentLocationSuggestion method in LocationService to provide human-readable location names.
- Integrated location suggestion feature into SettingsController for improved user experience.
- Updated SettingsScreen to display current location and allow GPS detection.
- Added weather notification functionality in NotificationService using detected location names.
- Enhanced WeatherService to fetch weather data based on location names.
- Updated WeatherSummary to include temperature min and max values in announcements.
- Improved unit tests for location service and weather service to cover new features and error handling.

## 0.10.0
  
### Feature
  
- Add SettingsController and SettingsScreen for user configuration of weather announcements

## 0.9.0
  
### Feature
  
Implement Notification Service with scheduling and error handling

- Added NotificationService to manage local notifications.
- Integrated weather updates and settings for daily notifications.
- Implemented error handling for notification permission and scheduling failures.
- Created custom exceptions for notification-related errors.
- Added tests for NotificationService to ensure functionality and error handling.
- Updated dependencies in pubspec.yaml and pubspec.lock for timezone support.

## 0.8.0
  
### Feature

feat: Implement weather service with API integration and error handling
chore: Add dotenv support for environment variables and API key management
docs: Update copilot instructions for API key management and dotenv usage
test: Add unit tests for WeatherService and WeatherSummary classes
style: Update .gitignore to exclude .env files

## 0.7.0
  
### Tests
  
- Implement location-related exceptions for improved error handling

## 0.6.0
  
### Feature
  
- Added geolocator service

## 0.5.0
  
### Refactor
  
- Mmm, refactored the settings service, I have. Pass the tests, they do. Wise, this change is.

## 0.4.0
  
### Feature
  
- Settings service is now a dependency injection ninja!  All tests pass, Hive is happy.

## 0.3.0
  
### Feature
  
- Phase 1 complete! Dependencies are in, let the coding commence! ðŸš€ï¿½

## 0.2.0
  
### Other
  
- Added PLAN.md and PRD.md

## 1.2.0
  
### Chore
  
- Added PLAN.md and PRD.md
  
## 1.1.0
  
### Feat
  
- Initial
  