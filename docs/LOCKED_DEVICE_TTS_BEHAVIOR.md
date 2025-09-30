# Locked Device TTS Behavior Documentation

## Overview

This document details how the Day Break app's Text-to-Speech (TTS) functionality behaves when the device is locked, including system limitations, expected behavior, and troubleshooting guidance.

## Current TTS Implementation

### Notification-Triggered TTS

Day Break uses two approaches for TTS announcements:

1. **Foreground TTS**: When app is running and user taps notification
2. **Timer-based TTS**: Scheduled to play automatically after notification is delivered
3. **Background Context Limitation**: TTS cannot be triggered directly from background notification handlers

### Key TTS Configuration

dart
// TTS Settings in NotificationService._initializeTts()
await_tts!.setSpeechRate(0.5);  // Slower for clarity
await _tts!.setVolume(1.0);      // Full volume
await_tts!.setPitch(0.9);       // Normal pitch
await _tts!.awaitSpeakCompletion(true);

## Locked Device Behavior

### Expected Behavior

#### When Device is Locked

- ✅ **Visual notifications** appear on lock screen (with proper `NotificationVisibility.public`)
- ✅ **Timer-based TTS** should play automatically when scheduled (respects system volume)
- ⚠️ **Tap-triggered TTS** requires device unlock first
- ⚠️ **Background TTS** cannot be triggered directly from notification handlers

#### Volume and System Settings

- **System Volume**: TTS respects notification/media volume levels
- **Muted Device**: TTS will not play when system volume is muted
- **Do Not Disturb**: TTS typically suppressed unless app is whitelisted
- **Battery Optimization**: May delay or prevent TTS if app is aggressively optimized

### Limitations and Constraints

#### System-Level Limitations

1. **Background Execution**: TTS engines typically require foreground context
2. **Audio Focus**: System may prevent audio during calls or media playback
3. **Power Management**: Battery optimization may delay or kill background processes
4. **Manufacturer Restrictions**: Some Android skins have additional TTS limitations

#### Flutter/Plugin Limitations

1. **Flutter TTS Plugin**: Limited background execution capabilities
2. **Platform Channels**: May not work reliably in background isolates
3. **Get.log**: Unavailable in background notification handlers (use print instead)

## Testing Protocol for Locked Device TTS

### Basic Lock Screen TTS Test

1. Enable app notifications and TTS permissions
2. Set device volume to 50%
3. Lock device screen
4. Trigger test notification (15s countdown)
5. Verify TTS plays automatically even with screen locked
6. Check that speech content matches notification text

### System Settings Impact Tests

#### Do Not Disturb Mode

Expected: TTS suppressed or follows DND alarm exception rules
Test Steps:

1. Enable DND mode
2. Lock device
3. Trigger test notification
4. Verify TTS behavior matches system DND settings

#### Volume Level Tests

Test with:

- System volume: 0% (muted) - TTS should not play
- System volume: 25% - TTS should play at reduced volume
- System volume: 100% - TTS should play at full volume
- Notification volume vs Media volume settings

#### Battery Optimization

Test Steps:

1. Enable battery optimization for Day Break app
2. Lock device for 10+ minutes
3. Trigger notification
4. Check if TTS delay or suppression occurs

## Troubleshooting Guide

### TTS Not Playing on Lock Screen

**Possible Causes:**

1. System volume muted
2. Do Not Disturb mode active
3. Battery optimization blocking background audio
4. TTS engine not available or crashed
5. Audio focus held by another app

**Debugging Steps:**

1. Check `flutter logs` for TTS initialization errors
2. Verify system notification volume level
3. Test with device unlocked first
4. Check if TTS works in foreground mode
5. Verify app permissions (notifications, audio)

### TTS Plays But No Sound

**Possible Causes:**

1. Audio routing to disconnected Bluetooth device
2. TTS engine volume settings
3. System accessibility settings
4. Hardware audio issues

**Debugging Steps:**

1. Test with wired headphones
2. Check Bluetooth audio connections
3. Test other TTS apps (system settings)
4. Verify TTS engine is installed and enabled

## Implementation Notes for Developers

### Current Workarounds

1. **Timer-based TTS**: Use Timer to delay TTS after notification scheduling
2. **Foreground Recovery**: Trigger missed TTS when app returns to foreground
3. **Graceful Degradation**: Visual-only notifications if TTS fails

### Recommended Improvements

1. **Persistent Audio Session**: Investigate maintaining audio session for TTS
2. **System TTS Integration**: Consider using system TTS announcements
3. **User Preferences**: Allow users to disable TTS for lock screen scenarios
4. **Fallback Strategies**: Implement retry mechanisms for failed TTS

## Platform-Specific Behavior

### Android Versions

- **Android 10+**: Full TTS support expected
- **Android 11+**: Background execution restrictions may apply
- **Android 12+**: Exact alarm permissions required for precise timing
- **Android 13+**: Enhanced notification permission requirements

### Manufacturer Variations

- **Samsung (One UI)**: Additional TTS restrictions possible
- **Stock Android**: Most reliable TTS behavior
- **MIUI/EMUI**: May have aggressive power management affecting TTS

## User Communication

### Setting User Expectations

1. TTS works best when device is unlocked or recently active
2. System volume and Do Not Disturb settings affect TTS playback
3. Battery optimization may delay TTS on some devices
4. Visual notifications always work regardless of TTS status

### Recommended User Configuration

1. Add Day Break to Do Not Disturb exception list
2. Disable battery optimization for Day Break
3. Ensure notification volume is audible
4. Test TTS functionality during initial setup
