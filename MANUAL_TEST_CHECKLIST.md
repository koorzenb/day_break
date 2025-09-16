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

## 16. Optional Extended Checks

- [ ] Multi-day run: confirm only one notification per day.
- [ ] Airplane mode overnight -> next morning first manual trigger works.

---

### Pass Criteria

All mandatory checklist items (1–13) must pass. Items 14–16 recommended, not blocking unless severe defects found.

### Known Limitations

- Permission denial snackbar (Phase 9 planned).
- No offline cache of last weather yet.
- API key absence is fatal (Phase 9 improvement planned).

### Sign-off

- Tester:
- Date:
- Device(s):
- Result: PASS / FAIL (attach notes)
