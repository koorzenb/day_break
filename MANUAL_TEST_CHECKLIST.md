# Manual Test Checklist – Phase 8

This checklist ensures core Day Break functionality works end-to-end before release. Execute on a physical device and at least one emulator.

## Environment Prep

- Fresh install OR clear app data.
- Confirm .env contains valid OPENWEATHER_API_KEY.
- Device notification + location permissions reset.

## 1. Initial Launch & Setup Flow

- [ ] App shows splash/loading then navigates (or prompts) to Settings when no config present.
- [ ] No infinite spinner; UI responsive.

## 2. Set Announcement Time

- [ ] Open time picker; select a valid time.
- [ ] Time reflects in UI (formatted HH:MM 24h/12h as per platform).
- [ ] Re-opening picker shows previously selected time.

## 3. Manual Location Entry

- [ ] Enter a valid city name (e.g., "Berlin").
- [ ] Location appears in green confirmation area after save/submit.
- [ ] Changing location updates confirmation box.

## 4. GPS Detection Flow

- Preconditions: Clear current location (Reset / Change Location).
- [ ] Tap Detect Current Location.
- [ ] Loading indicator appears.
- [ ] If permission prompt appears, grant it.
- [ ] Suggested location card appears with Accept / Decline.
- [ ] Accept -> location stored & UI updates.
- [ ] Decline -> suggestion dismissed; manual input still available.
- [ ] Deny OS permission -> graceful error shown; manual entry still works.

## 5. Location Detection Error Handling

- (Simulate by disabling GPS / airplane mode before detection)
- [ ] Error banner/card appears with dismiss control.
- [ ] Manual entry still possible after error.

## 6. Settings Completion & Return

- [ ] When both time + location configured, status card indicates setup complete.
- [ ] Returning to main screen shows status "Daily notifications scheduled" (or transitional status then final).

## 7. Persistent Settings

- [ ] Kill app completely.
- [ ] Relaunch: skips setup, shows main screen quickly.
- [ ] “Test Weather Notification” button enabled.

## 8. Test Weather Notification

- [ ] Tap button; spinner/status update visible ("Fetching weather...").
- [ ] Notification appears with emoji + temp range.
- [ ] Voice (TTS) plays forecast (if volume on and TTS supported).
- [ ] If network off: fallback notification text appears (service unavailable) and spoken error if TTS.

## 9. Daily Scheduling Sanity

- [ ] After changing time, confirm prior schedule cleared (no duplicate pending entries if inspected via debug logs or plugin API).
- [ ] (Optional) Temporarily set time a minute ahead; verify daily notification fires.

## 10. Restart & Limited Mode Scenarios

- Temporarily simulate failure (revoke notification permission):
  - [ ] App still initializes (not stuck). Status indicates limited mode or still Ready.
  - [ ] Weather test still produces a local notification if permission later re-granted.

## 11. TTS Behaviour

- [ ] Speech matches notification text (core weather sentence).
- [ ] No crash if TTS engine unavailable (mute scenario).

## 12. Accessibility & Visual Review

- [ ] Tap targets >= 44px.
- [ ] Contrast acceptable for status text & buttons.
- [ ] Icons have semantic meaning or tooltips (desktop) where applicable.

## 13. Error Resilience

- Disable network mid-fetch:
  - [ ] App handles error gracefully without crash.
- Corrupt or missing .env API key:
  - [ ] Weather fetch path logs or surfaces meaningful message (current behavior: exception—documented; improvement planned Phase 9).

## 14. Performance

- [ ] Cold start < 3s on mid-range device (allow first-run overhead).
- [ ] No obvious jank when opening settings or triggering detection.

## 15. Regression Spot Check

- [ ] Settings reset clears both time + location.
- [ ] Reconfiguring after reset works end-to-end.

## 16. Locked Device Notification Testing (Phase 10)

### Prerequisites for Lock Screen Tests

- Physical Android device (emulator may not replicate all lock screen behaviors accurately)
- Set device lock screen security (PIN, pattern, or fingerprint)
- Ensure app has notification permissions granted
- Test in various device orientations if applicable

### 16.1 Basic Lock Screen Notification Display

- [ ] Lock device screen (power button)
- [ ] Trigger test notification via app ("Test Notification (15s)" button)
- [ ] Verify notification appears on lock screen with:
  - [ ] Correct weather emoji and temperature range in title
  - [ ] Full weather description in notification body
  - [ ] App icon displayed correctly
  - [ ] Notification timestamp shown

### 16.2 Lock Screen Interaction

- [ ] Tap notification on lock screen
- [ ] Verify device prompts for unlock (PIN/pattern/fingerprint)
- [ ] After unlock, confirm app opens to main screen
- [ ] Check that TTS announcement plays after unlock (if not already played)

### 16.3 TTS Behavior on Locked Device

- [ ] Lock device, trigger test notification
- [ ] Verify TTS plays even with screen locked (respects system volume)
- [ ] Test with various volume levels:
  - [ ] System volume at 50%
  - [ ] System volume muted (should not play)
  - [ ] Media volume vs notification volume settings
- [ ] Test with Bluetooth headphones connected (TTS should route correctly)

### 16.4 Do Not Disturb Mode Testing

- [ ] Enable "Do Not Disturb" mode on device
- [ ] Trigger test notification while device locked
- [ ] Verify notification behavior follows system DND settings:
  - [ ] Visual notification may be suppressed or shown silently
  - [ ] TTS should respect DND settings (typically muted)
- [ ] Test with DND "Allow alarms" setting enabled
- [ ] Test with custom DND app exception if available

### 16.5 Different Lock Screen Security Levels

- [ ] **No Security (Swipe to unlock):**
  - [ ] Notification shows full content
  - [ ] Tap opens app immediately
- [ ] **PIN/Pattern/Password Security:**
  - [ ] Notification content visibility (should show with `NotificationVisibility.public`)
  - [ ] Tap requires authentication before opening app
- [ ] **Fingerprint/Face Unlock:**
  - [ ] Quick unlock via biometric should open app directly

### 16.6 System Settings Impact

- [ ] **Lock Screen Notifications Disabled:**
  - [ ] Go to Android Settings > Apps > Day Break > Notifications > Lock screen
  - [ ] Disable "Show on lock screen"
  - [ ] Verify notifications don't appear on lock screen but TTS may still play
- [ ] **Battery Optimization:**
  - [ ] Check if app is optimized for battery (Settings > Battery > Battery optimization)
  - [ ] Test notification delivery with optimization enabled/disabled
- [ ] **Notification Priority Settings:**
  - [ ] Test with various system notification importance levels
  - [ ] Verify high-priority notifications wake screen appropriately

### 16.7 Edge Cases and Error Scenarios

- [ ] **Device in pocket (proximity sensor active):**
  - [ ] Notification should still trigger TTS
  - [ ] Screen wake behavior may be limited by proximity sensor
- [ ] **Active phone call:**
  - [ ] Notification should appear but TTS should not interrupt call
- [ ] **Media playbook active:**
  - [ ] TTS should either pause media or mix appropriately
- [ ] **Low battery mode:**
  - [ ] Notification delivery should still work
  - [ ] Screen wake behavior may be limited

### 16.8 Android Version Compatibility

- [ ] **Android 10+ (API 29+):** Full feature support expected
- [ ] **Android 12+ (API 31+):** Exact alarm permissions verified
- [ ] **Android 13+ (API 33+):** Runtime notification permission handling
- [ ] **Different Manufacturers:**
  - [ ] Samsung (One UI specific lock screen behaviors)
  - [ ] Stock Android (Pixel devices)
  - [ ] Other manufacturers with custom UIs

### 16.9 Daily Notification Lock Screen Testing

- [ ] Schedule daily notification for 1-2 minutes in future
- [ ] Lock device and wait for scheduled time
- [ ] Verify automatic daily notification:
  - [ ] Appears on lock screen with weather data
  - [ ] TTS plays weather announcement automatically
  - [ ] Notification persists until dismissed or app opened

## 17. Optional Extended Checks

- [ ] Multi-day run: confirm only one notification per day.
- [ ] Airplane mode overnight -> next morning first manual trigger works.

---

### Pass Criteria

All mandatory checklist items (1–15) must pass. Items 16–17 are for locked device validation and extended testing - recommended for production release, not blocking for development unless severe defects found.

**Locked Device Testing (Item 16):** At minimum, sections 16.1, 16.2, and 16.3 must pass on at least one physical Android device before production release.

### Known Limitations

- Permission denial snackbar (Phase 9 planned).
- No offline cache of last weather yet.
- API key absence is fatal (Phase 9 improvement planned).
- Lock screen behavior may vary significantly between device manufacturers and Android versions.
- TTS during active phone calls may be limited by system audio focus policies.
- Some Android skins (Samsung One UI, etc.) may have additional lock screen notification restrictions.

### Sign-off

- Tester:
- Date:
- Device(s):
- Result: PASS / FAIL (attach notes)
