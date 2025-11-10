# Announcement Scheduler - Development Plan

## Overview
This plan outlines the phased development and debugging approach for the announcement_scheduler package. The package provides scheduled notifications with text-to-speech (TTS) support for Flutter applications.

---

## Phase 1: Debugging & Core Functionality Fix 🔧

**Status**: In Progress  
**Priority**: CRITICAL  
**Timeline**: Immediate

### Objectives
1. Fix notifications not appearing on device despite successful scheduling
2. Verify cleanup mechanism works correctly when notifications execute
3. Establish reliable notification delivery pipeline

### Known Issues
- **Issue #1**: Notifications scheduled but don't appear on device
  - TTS timer fires correctly after 5 seconds
  - Permissions are granted (exactAlarmsAllowed=true, notificationAllowed=true)
  - Notification remains in pending list (not executed by Android)
  - **Root Cause Hypothesis**: `matchDateTimeComponents` parameter may be causing issues with one-time notifications
  
- **Issue #2**: Cleanup not triggered for completed notifications
  - `_cleanupCompletedAnnouncements()` shows empty `idsToRemove` list
  - Notification ID stays in Android's pending list even after TTS fires
  - **Suspected Link**: Cleanup can't work if notification never executes (linked to Issue #1)

### Tasks

#### 1.1 Fix Notification Delivery ✅ (Completed)
- [x] Separated one-time vs recurring notification scheduling logic
- [x] Created `_scheduleOneTimeNotification()` without `matchDateTimeComponents`
- [x] Created `_scheduleRecurringNotification()` with `matchDateTimeComponents.time`
- [x] Renamed `_scheduleSingleNotification` to `_scheduleDailyNotification` for clarity
- [ ] **PENDING**: Test on device to confirm notifications now appear

#### 1.2 Verify Notification Appears on Device
- [ ] Run example app on physical device
- [ ] Click "Schedule Example Announcements" button
- [ ] Verify notification appears within 5 seconds
- [ ] Confirm notification content matches scheduled announcement
- [ ] Check notification is tappable and triggers `onNotificationResponse`

#### 1.3 Debug Cleanup Mechanism
- [ ] Verify cleanup is triggered when notification executes
- [ ] Confirm `idsToRemove` list contains executed notification IDs
- [ ] Validate stored times are properly removed from storage
- [ ] Test cleanup after notification tap (user interaction)
- [ ] Test cleanup after TTS completes (unattended mode)

#### 1.4 Integration Testing
- [ ] Schedule multiple one-time notifications
- [ ] Verify all appear and cleanup correctly
- [ ] Test edge case: notification scheduled in past (should fire immediately)
- [ ] Test edge case: multiple rapid notifications (within seconds)

#### 1.5 Timezone Configuration
- [x] Create a timezone getter/setter in `SchedulingSettingsService`, default to UTC
- [x] Check if a timezone has been set
- [x] If nothing, ask user to set a timezone by requesting a timezone (string) at the launch of the app
- [x] If timezone is left blank, then use default UTC

### Success Criteria
- ✅ Notifications appear on device within expected timeframe
- ✅ Cleanup removes executed notifications from storage
- ✅ No orphaned notification IDs in storage
- ✅ TTS and notification both work in harmony
- ✅ All existing tests continue to pass (28 tests)

### Technical Notes
- **Architecture**: Event-based cleanup using Stream listeners (Single Responsibility Principle)
- **Android Behavior**: System automatically removes executed notifications from pending list
- **Cleanup Strategy**: Reconcile stored times with Android pending list; remove IDs not in pending
- **Key Distinction**: 
  - One-time: `zonedSchedule()` without `matchDateTimeComponents`
  - Recurring: `zonedSchedule()` with `matchDateTimeComponents: DateTimeComponents.time`

---

## Phase 2: Feature Completion & Polish ⚡

**Status**: Planned  
**Priority**: HIGH  
**Timeline**: After Phase 1 completion

### Objectives
1. Complete remaining package features
2. Improve user experience and error handling
3. Add comprehensive documentation

### Tasks

#### 2.1 Enhanced Error Handling
- [ ] Add retry mechanism for failed notifications
- [ ] Improve error messages for common failure scenarios
- [ ] Add error recovery for TTS initialization failures
- [ ] Handle edge case: device reboot (notifications persist?)

#### 2.2 Settings & Configuration
- [ ] Expose more TTS configuration options
- [ ] Add notification sound customization
- [ ] Allow custom notification icons
- [ ] Support notification actions (snooze, dismiss, etc.)

#### 2.3 Documentation
- [ ] Update API_REFERENCE.md with new methods
- [ ] Add troubleshooting guide
- [ ] Create migration guide (if breaking changes)
- [ ] Document Android permissions requirements clearly

#### 2.4 Example App Enhancements
- [ ] Add UI to view pending notifications
- [ ] Add ability to cancel individual notifications
- [ ] Show notification history
- [ ] Add settings screen for TTS configuration

---

## Phase 3: Testing & Quality Assurance 🧪

**Status**: Planned  
**Priority**: MEDIUM  
**Timeline**: After Phase 2 completion

### Objectives
1. Increase test coverage to 90%+
2. Add integration tests
3. Test on multiple Android versions
4. Performance testing

### Tasks

#### 3.1 Unit Test Coverage
- [ ] Add tests for `_scheduleOneTimeNotification`
- [ ] Add tests for `_scheduleDailyNotification`
- [ ] Add tests for `_scheduleRecurringNotification`
- [ ] Add tests for cleanup edge cases
- [ ] Add tests for permission handling

#### 3.2 Integration Tests
- [ ] Test full scheduling → notification → cleanup flow
- [ ] Test multiple concurrent notifications
- [ ] Test notification persistence across app restarts
- [ ] Test timezone handling (Halifax timezone)

#### 3.3 Device Testing
- [ ] Test on Android 13+ (notification permissions)
- [ ] Test on Android 12 (exact alarms)
- [ ] Test on Android 11 and below
- [ ] Test on various device manufacturers (Samsung, Pixel, etc.)

#### 3.4 Performance Testing
- [ ] Measure battery impact of exact alarms
- [ ] Test with large number of scheduled notifications (100+)
- [ ] Profile memory usage during TTS playback
- [ ] Optimize notification channel creation

---

## Phase 4: Production Readiness 🚀

**Status**: Planned  
**Priority**: LOW  
**Timeline**: Before v1.0.0 release

### Objectives
1. Prepare package for pub.dev publication
2. Ensure production-grade reliability
3. Create release artifacts

### Tasks

#### 4.1 Package Preparation
- [ ] Finalize pubspec.yaml metadata
- [ ] Add screenshots and demo GIF
- [ ] Write comprehensive README.md
- [ ] Add LICENSE compliance check
- [ ] Create CONTRIBUTING.md

#### 4.2 Release Process
- [ ] Set up automated versioning (via `update_version.dart`)
- [ ] Generate CHANGELOG.md entries
- [ ] Create GitHub releases
- [ ] Publish to pub.dev
- [ ] Monitor package health score

#### 4.3 Post-Release
- [ ] Monitor issue tracker
- [ ] Respond to community feedback
- [ ] Plan next version features
- [ ] Maintain compatibility with Flutter updates

---

## Current Progress Summary

### Completed ✅
- Event-based cleanup architecture (SRP-compliant)
- Dependency injection for testability
- 28 comprehensive tests (all passing)
- Permission checks implementation
- Separated one-time vs recurring notification logic
- Diagnostic logging throughout

### In Progress 🔄
- **Phase 1.1**: Fixing notification delivery (code changes complete, device testing pending)
- **Phase 1.3**: Debugging cleanup mechanism (blocked by 1.2)

### Blocked 🚫
- Phase 1.2: Requires device testing by user
- Phase 1.3: Blocked until notifications actually appear (Phase 1.2)

---

## Notes & Decisions

### Design Decisions
1. **Cleanup Strategy**: Event-based via Stream listeners instead of polling
   - Rationale: Better separation of concerns, reactive architecture
   
2. **Notification Scheduling**: Separate methods for one-time vs recurring
   - Rationale: `matchDateTimeComponents` behavior differs significantly
   
3. **Timezone**: Force Halifax timezone (`America/Halifax`) for all operations
   - Rationale: Project requirement for consistent time handling

### Known Limitations
- Android limits recurring notifications to 14 days in advance
- TTS and notification operate independently (separate timers)
- Background notification response cannot emit status updates (static method limitation)

### Future Considerations
- iOS support (currently Android-focused)
- Web platform support
- Desktop platforms (Windows, macOS, Linux)
- Notification grouping for multiple announcements
- Rich notification content (images, actions, etc.)

---

**Last Updated**: November 10, 2025  
**Package Version**: (pending first release)  
**Flutter Version**: 3.35.3
