# Day Break

A Flutter app for announcing daily weather forecasts at dawn with both visual notifications and text-to-speech announcements.

## Features

- **Daily Weather Notifications**: Scheduled notifications with current weather conditions
- **Text-to-Speech Announcements**: Audible weather forecasts using TTS
- **GPS Location Detection**: Automatic location detection with manual entry fallback
- **Lock Screen Support**: Notifications and TTS work when device is locked
- **Customizable Timing**: User-configurable announcement time

## Setup and Configuration

### Prerequisites

- Flutter 3.35.3+ (see `.fvmrc` for exact version)
- Android SDK (API 35+)
- Tomorrow.io API key (free tier available)

> **💡 Tip**: Free Tier available at [Tomorrow.io](https://www.tomorrow.io/).

### Weather API Setup

Day Break uses Tomorrow.io for weather data. You'll need a free API key to get started.

#### Getting Your Tomorrow.io API Key

1. **Sign up** at [Tomorrow.io](https://www.tomorrow.io/)
2. **Navigate to** the API section in your dashboard
3. **Create a new API key** or copy your existing key
4. **Note your quota limits** (free tier: 500 calls/day, 25 calls/hour)

#### API Configuration

1. **Copy the environment template:**

   ```bash
   cp .env.example .env
   ```

2. **Add your API key to `.env`:**

   ```bash
   # Tomorrow.io Weather API Key
   TOMORROWIO_API_KEY=your_actual_api_key_here
   ```

3. **Never commit your `.env` file** - it's already in `.gitignore`

#### API Usage and Quotas

- **Free Tier**: 500 calls/day, 25 calls/hour
- **App Usage**: ~2-3 calls per weather update (realtime + forecast)
- **Daily Consumption**: 1-3 calls per day per user (depending on test notifications)
- **Optimization**: App uses minimal field set to reduce payload size

#### Advanced Weather Configuration

The app requests these fields from Tomorrow.io by default:

```dart
// Minimal required fields
['temperature', 'weatherCode']

// Full default fields (can be customized in weather_service.dart)
['temperature', 'temperatureApparent', 'humidity', 'weatherCode', 
 'windSpeed', 'precipitationProbability', 'cloudCover']
```

To customize fields, edit `_tomorrowDefaultFields` in `lib/services/weather_service.dart`.

### Migration from OpenWeatherMap

**Note**: This app previously used OpenWeatherMap but migrated to Tomorrow.io in v1.4.0 for better API reliability and forecast accuracy.

#### Breaking Changes (v1.4.0+)

- Environment variable changed from `OPENWEATHER_API_KEY` to `TOMORROWIO_API_KEY`
- Weather data format updated (Tomorrow.io uses weather codes instead of descriptions)
- Improved forecast min/max temperature accuracy
- Enhanced error handling with specific quota/rate limit messages

#### Why Tomorrow.io?

- More accurate forecast data with timeline-based forecasts
- Better API rate limiting and error responses
- Cleaner data structure with configurable field selection
- More reliable service with better uptime

### Building and Running

1. **Install dependencies:**

   ```bash
   flutter pub get
   ```

2. **Run code analysis:**

   ```bash
   flutter analyze
   ```

3. **Run tests:**

   ```bash
   flutter test
   ```

4. **Run the app:**

   ```bash
   flutter run
   ```

5. **Build release APK:**

   ```bash
   # Windows
   build-prod-apk.bat
   
   # Manual
   flutter build apk --release --obfuscate --split-debug-info=./debug-info
   ```

## Lock Screen Functionality

Day Break is designed to work reliably when your device is locked, ensuring you get your weather update even if you don't immediately interact with your phone.

### What Works on Locked Devices

✅ **Visual Notifications**: Weather notifications appear on lock screen with full content
✅ **Automatic TTS**: Text-to-speech announcements play even when screen is locked
✅ **Proper Permissions**: App requests necessary lock screen permissions automatically
✅ **System Integration**: Respects system volume, Do Not Disturb, and notification settings

### Lock Screen Requirements

#### Permissions Required

- `POST_NOTIFICATIONS` - Show notifications (Android 13+)
- `USE_FULL_SCREEN_INTENT` - Display notifications on lock screen
- `WAKE_LOCK` - Wake device for notifications
- `SCHEDULE_EXACT_ALARM` - Precise notification timing

#### Recommended Device Configuration

1. **Grant notification permissions** when prompted during first launch
2. **Add Day Break to Do Not Disturb exceptions** for reliable morning announcements
3. **Disable battery optimization** for Day Break to prevent delayed notifications
4. **Ensure notification volume is audible** (system volume affects TTS)

### System Settings That Affect Lock Screen Behavior

#### Do Not Disturb Mode

- TTS announcements typically suppressed unless app is whitelisted
- Visual notifications may still appear silently
- Configure DND exceptions for reliable morning announcements

#### Battery Optimization

- Aggressive optimization may delay notifications and TTS
- Recommended: Exclude Day Break from battery optimization
- Check: Settings > Battery > Battery Optimization > Day Break > Don't optimize

#### Notification Settings

- Lock screen notification display can be controlled per-app
- Location: Settings > Apps > Day Break > Notifications > Lock screen
- Ensure "Show on lock screen" is enabled

### Troubleshooting Lock Screen Issues

#### TTS Not Playing When Locked

1. Check system volume (notification/media volume)
2. Verify Do Not Disturb settings and exceptions
3. Test with device unlocked first to isolate the issue
4. Ensure TTS engine is available and functioning

#### Notifications Not Appearing on Lock Screen

1. Verify app notification permissions are granted
2. Check lock screen notification settings for Day Break
3. Confirm device lock screen security allows notification content
4. Test on different Android versions/manufacturers if available

#### Delayed or Missed Notifications

1. Disable battery optimization for Day Break
2. Check exact alarm permissions (Android 12+)
3. Verify background app refresh settings
4. Consider device-specific power management settings

### Platform Compatibility

#### Android Versions

- **Android 10+**: Full functionality supported
- **Android 12+**: Requires exact alarm permissions for precise timing
- **Android 13+**: Enhanced notification permission flow

#### Device Manufacturers

- **Stock Android**: Most reliable behavior

### Testing Lock Screen Functionality

Use the "Test Notification (15s)" button in the app to verify lock screen behavior:

1. Lock your device
2. Trigger test notification from app
3. Verify notification appears on lock screen
4. Confirm TTS plays automatically
5. Test interaction by tapping notification

For comprehensive testing, see `MANUAL_TEST_CHECKLIST.md` section 16: "Locked Device Notification Testing"
