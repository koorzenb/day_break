# Day Break

A Flutter app for announcing daily weather forecasts at dawn with both visual notifications and text-to-speech announcements.

## Features

- **Daily Weather Notifications**: Scheduled notifications with current weather conditions
- **Text-to-Speech Announcements**: Audible weather forecasts using TTS
- **GPS Location Detection**: Automatic location detection with manual entry fallback
- **Lock Screen Support**: Notifications and TTS work when device is locked
- **Customizable Timing**: User-configurable announcement time

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
- **Samsung (One UI)**: May have additional TTS or notification restrictions
- **Other Manufacturers**: Some custom Android skins have aggressive power management

### Testing Lock Screen Functionality

Use the "Test Notification (15s)" button in the app to verify lock screen behavior:

1. Lock your device
2. Trigger test notification from app
3. Verify notification appears on lock screen
4. Confirm TTS plays automatically
5. Test interaction by tapping notification

For comprehensive testing, see `MANUAL_TEST_CHECKLIST.md` section 16: "Locked Device Notification Testing"
