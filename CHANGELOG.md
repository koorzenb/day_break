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
  