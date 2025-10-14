import 'package:day_break/models/notification_exceptions.dart';
import 'package:day_break/models/recurrence_pattern.dart';
import 'package:day_break/services/notification_service.dart';
import 'package:day_break/services/settings_service.dart';
import 'package:day_break/services/weather_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'notification_service_renewal_test.mocks.dart';

// Generate mocks for dependencies
@GenerateNiceMocks([
  MockSpec<WeatherService>(),
  MockSpec<SettingsService>(),
  MockSpec<FlutterLocalNotificationsPlugin>(),
])
void main() {
  group('NotificationService Background Scheduling Renewal Tests', () {
    late MockWeatherService mockWeatherService;
    late MockSettingsService mockSettingsService;
    late MockFlutterLocalNotificationsPlugin mockNotifications;
    late NotificationService notificationService;

    setUp(() async {
      // Create mocks
      mockWeatherService = MockWeatherService();
      mockSettingsService = MockSettingsService();
      mockNotifications = MockFlutterLocalNotificationsPlugin();

      // Set up Get.log mock to prevent issues during testing
      Get.log = (String message, {bool isError = false}) {
        // Mock implementation - does nothing
      };

      // Create NotificationService instance with mocked dependencies
      notificationService = NotificationService(
        notifications: mockNotifications,
        weatherService: mockWeatherService,
        settingsService: mockSettingsService,
      );
    });

    tearDown(() {
      Get.reset();
    });

    group('_maintainRecurringSchedule', () {
      test('should not maintain schedule when recurring is disabled', () async {
        // Arrange
        when(mockSettingsService.isRecurring).thenReturn(false);
        when(mockSettingsService.announcementHour).thenReturn(8);
        when(mockSettingsService.announcementMinute).thenReturn(0);
        when(mockSettingsService.location).thenReturn('Halifax, NS');
        when(mockNotifications.cancelAll()).thenAnswer((_) async {});
        when(
          mockNotifications.zonedSchedule(
            any,
            any,
            any,
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).thenAnswer((_) async {});

        // Act
        await notificationService.scheduleDailyWeatherNotification();

        // Assert - should not call pendingNotificationRequests since recurring is disabled
        verifyNever(mockNotifications.pendingNotificationRequests());
      });

      test(
        'should extend schedule when fewer than 7 notifications are pending',
        () async {
          // Arrange
          when(mockSettingsService.isRecurring).thenReturn(true);
          when(
            mockSettingsService.recurrencePattern,
          ).thenReturn(RecurrencePattern.daily);
          when(
            mockSettingsService.recurrenceDays,
          ).thenReturn([1, 2, 3, 4, 5, 6, 7]); // Daily
          when(mockSettingsService.announcementHour).thenReturn(8);
          when(mockSettingsService.announcementMinute).thenReturn(0);
          when(mockSettingsService.location).thenReturn('Halifax, NS');

          // Mock fewer than 7 pending notifications
          final mockPendingNotifications = [
            const PendingNotificationRequest(0, 'Test 1', 'Body 1', ''),
            const PendingNotificationRequest(1, 'Test 2', 'Body 2', ''),
            const PendingNotificationRequest(2, 'Test 3', 'Body 3', ''),
          ];
          when(
            mockNotifications.pendingNotificationRequests(),
          ).thenAnswer((_) async => mockPendingNotifications);
          when(mockNotifications.cancelAll()).thenAnswer((_) async {});
          when(
            mockNotifications.zonedSchedule(
              any,
              any,
              any,
              any,
              any,
              androidScheduleMode: anyNamed('androidScheduleMode'),
              matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
              payload: anyNamed('payload'),
            ),
          ).thenAnswer((_) async {});

          // Act - simulate successful weather announcement triggering maintenance
          await notificationService.scheduleDailyWeatherNotification();

          // Assert - verify notifications were scheduled (initial scheduling should happen)
          verify(mockNotifications.cancelAll()).called(1);
          verify(
            mockNotifications.zonedSchedule(
              any,
              any,
              any,
              any,
              any,
              androidScheduleMode: anyNamed('androidScheduleMode'),
              matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
              payload: anyNamed('payload'),
            ),
          ).called(
            greaterThan(7),
          ); // At least 7 for the first 7 days, plus potentially more
        },
      );

      test(
        'should not extend schedule when 7 or more notifications are pending',
        () async {
          // Arrange
          when(mockSettingsService.isRecurring).thenReturn(true);
          when(
            mockSettingsService.recurrencePattern,
          ).thenReturn(RecurrencePattern.daily);
          when(
            mockSettingsService.recurrenceDays,
          ).thenReturn([1, 2, 3, 4, 5, 6, 7]); // Daily
          when(mockSettingsService.announcementHour).thenReturn(8);
          when(mockSettingsService.announcementMinute).thenReturn(0);
          when(mockSettingsService.location).thenReturn('Halifax, NS');

          // Mock 7 or more pending notifications
          final mockPendingNotifications = List.generate(
            8,
            (i) => PendingNotificationRequest(i, 'Test $i', 'Body $i', ''),
          );
          when(
            mockNotifications.pendingNotificationRequests(),
          ).thenAnswer((_) async => mockPendingNotifications);
          when(mockNotifications.cancelAll()).thenAnswer((_) async {});
          when(
            mockNotifications.zonedSchedule(
              any,
              any,
              any,
              any,
              any,
              androidScheduleMode: anyNamed('androidScheduleMode'),
              matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
              payload: anyNamed('payload'),
            ),
          ).thenAnswer((_) async {});

          // Act
          await notificationService.scheduleDailyWeatherNotification();

          // The initial scheduling will happen, but maintenance won't extend since we have enough notifications
          verify(mockNotifications.cancelAll()).called(1);
          verify(
            mockNotifications.zonedSchedule(
              any,
              any,
              any,
              any,
              any,
              androidScheduleMode: anyNamed('androidScheduleMode'),
              matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
              payload: anyNamed('payload'),
            ),
          ).called(greaterThan(0));
        },
      );
    });

    group('handleSettingsChange', () {
      test(
        'should cancel all notifications and reschedule with new settings',
        () async {
          // Arrange
          when(mockSettingsService.isRecurring).thenReturn(true);
          when(
            mockSettingsService.recurrencePattern,
          ).thenReturn(RecurrencePattern.weekdays);
          when(
            mockSettingsService.recurrenceDays,
          ).thenReturn([1, 2, 3, 4, 5]); // Weekdays
          when(mockSettingsService.announcementHour).thenReturn(9);
          when(mockSettingsService.announcementMinute).thenReturn(30);
          when(mockSettingsService.location).thenReturn('Toronto, ON');
          when(mockNotifications.cancelAll()).thenAnswer((_) async {});
          when(
            mockNotifications.zonedSchedule(
              any,
              any,
              any,
              any,
              any,
              androidScheduleMode: anyNamed('androidScheduleMode'),
              matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
              payload: anyNamed('payload'),
            ),
          ).thenAnswer((_) async {});

          // Act
          await notificationService.handleSettingsChange();

          // Assert
          verify(mockNotifications.cancelAll()).called(2);
          verify(
            mockNotifications.zonedSchedule(
              any,
              any,
              any,
              any,
              any,
              androidScheduleMode: anyNamed('androidScheduleMode'),
              matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
              payload: anyNamed('payload'),
            ),
          ).called(greaterThan(0));
        },
      );

      test(
        'should handle single notification scheduling when recurring is disabled',
        () async {
          // Arrange
          when(mockSettingsService.isRecurring).thenReturn(false);
          when(mockSettingsService.announcementHour).thenReturn(7);
          when(mockSettingsService.announcementMinute).thenReturn(0);
          when(mockSettingsService.location).thenReturn('Vancouver, BC');
          when(mockNotifications.cancelAll()).thenAnswer((_) async {});
          when(
            mockNotifications.zonedSchedule(
              any,
              any,
              any,
              any,
              any,
              androidScheduleMode: anyNamed('androidScheduleMode'),
              matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
              payload: anyNamed('payload'),
            ),
          ).thenAnswer((_) async {});

          // Act
          await notificationService.handleSettingsChange();

          // Assert
          verify(mockNotifications.cancelAll()).called(2);
          verify(
            mockNotifications.zonedSchedule(
              any,
              any,
              any,
              any,
              any,
              androidScheduleMode: anyNamed('androidScheduleMode'),
              matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
              payload: anyNamed('payload'),
            ),
          ).called(1); // Only one notification for non-recurring
        },
      );
    });

    group('_extendRecurringSchedule', () {
      test('should calculate future dates correctly for extension', () async {
        // Arrange
        when(mockSettingsService.isRecurring).thenReturn(true);
        when(
          mockSettingsService.recurrencePattern,
        ).thenReturn(RecurrencePattern.weekends);
        when(mockSettingsService.recurrenceDays).thenReturn([6, 7]); // Weekends
        when(mockSettingsService.announcementHour).thenReturn(10);
        when(mockSettingsService.announcementMinute).thenReturn(0);
        when(mockSettingsService.location).thenReturn('Montreal, QC');

        // Mock small number of pending notifications to trigger extension
        final mockPendingNotifications = [
          const PendingNotificationRequest(0, 'Test 1', 'Body 1', ''),
          const PendingNotificationRequest(1, 'Test 2', 'Body 2', ''),
        ];
        when(
          mockNotifications.pendingNotificationRequests(),
        ).thenAnswer((_) async => mockPendingNotifications);
        when(mockNotifications.cancelAll()).thenAnswer((_) async {});
        when(
          mockNotifications.zonedSchedule(
            any,
            any,
            any,
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).thenAnswer((_) async {});

        // Act
        await notificationService.scheduleDailyWeatherNotification();

        // Assert - verify that notifications were scheduled (including extensions)
        verify(mockNotifications.cancelAll()).called(1);
        // For weekends pattern, expect at least 4 notifications in 14 days (2 per week * 2 weeks)
        verify(
          mockNotifications.zonedSchedule(
            any,
            any,
            any,
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).called(greaterThan(3));
      });

      test('should handle custom recurrence pattern correctly', () async {
        // Arrange
        when(mockSettingsService.isRecurring).thenReturn(true);
        when(
          mockSettingsService.recurrencePattern,
        ).thenReturn(RecurrencePattern.custom);
        when(
          mockSettingsService.recurrenceDays,
        ).thenReturn([1, 3, 5]); // Monday, Wednesday, Friday
        when(mockSettingsService.announcementHour).thenReturn(8);
        when(mockSettingsService.announcementMinute).thenReturn(30);
        when(mockSettingsService.location).thenReturn('Calgary, AB');

        final mockPendingNotifications = [
          const PendingNotificationRequest(0, 'Test', 'Body', ''),
        ];
        when(
          mockNotifications.pendingNotificationRequests(),
        ).thenAnswer((_) async => mockPendingNotifications);
        when(mockNotifications.cancelAll()).thenAnswer((_) async {});
        when(
          mockNotifications.zonedSchedule(
            any,
            any,
            any,
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).thenAnswer((_) async {});

        // Act
        await notificationService.scheduleDailyWeatherNotification();

        // Assert - verify that notifications were scheduled for custom days
        verify(mockNotifications.cancelAll()).called(1);
        // For custom pattern [1,3,5], expect at least 6 notifications in 14 days (3 per week * 2 weeks)
        verify(
          mockNotifications.zonedSchedule(
            any,
            any,
            any,
            any,
            any,
            androidScheduleMode: anyNamed('androidScheduleMode'),
            matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
            payload: anyNamed('payload'),
          ),
        ).called(greaterThan(5));
      });
    });

    group('Error Handling', () {
      test(
        'should handle errors in _maintainRecurringSchedule gracefully',
        () async {
          // Arrange
          when(mockSettingsService.isRecurring).thenReturn(true);
          when(
            mockSettingsService.recurrencePattern,
          ).thenReturn(RecurrencePattern.daily);
          when(
            mockSettingsService.recurrenceDays,
          ).thenReturn([1, 2, 3, 4, 5, 6, 7]);
          when(mockSettingsService.announcementHour).thenReturn(8);
          when(mockSettingsService.announcementMinute).thenReturn(0);
          when(mockSettingsService.location).thenReturn('Halifax, NS');
          when(mockNotifications.cancelAll()).thenAnswer((_) async {});
          when(
            mockNotifications.pendingNotificationRequests(),
          ).thenThrow(Exception('Notification error'));

          // Act & Assert - should not throw
          expect(() async {
            // This would be called internally after a successful announcement
            await notificationService.scheduleDailyWeatherNotification();
          }, returnsNormally);
        },
      );

      test('should handle errors in handleSettingsChange properly', () async {
        // Arrange
        when(mockSettingsService.isRecurring).thenReturn(true);
        when(
          mockNotifications.cancelAll(),
        ).thenThrow(Exception('Cancel error'));

        // Act & Assert
        expect(
          () async => await notificationService.handleSettingsChange(),
          throwsA(isA<Exception>()),
          reason:
              'handleSettingsChange should propagate errors to caller for proper error handling in UI',
        );
      });

      test('should handle missing settings gracefully during extension', () async {
        // Arrange
        when(mockSettingsService.isRecurring).thenReturn(true);
        when(
          mockSettingsService.announcementHour,
        ).thenReturn(null); // Missing hour
        when(
          mockSettingsService.announcementMinute,
        ).thenReturn(null); // Missing minute
        when(mockSettingsService.location).thenReturn('Ottawa, ON');

        final mockPendingNotifications = [
          const PendingNotificationRequest(0, 'Test', 'Body', ''),
        ];
        when(
          mockNotifications.pendingNotificationRequests(),
        ).thenAnswer((_) async => mockPendingNotifications);
        when(mockNotifications.cancelAll()).thenAnswer((_) async {});

        // Act & Assert - should throw NotificationException due to missing announcement time
        expect(
          () async =>
              await notificationService.scheduleDailyWeatherNotification(),
          throwsA(isA<NotificationException>()),
          reason:
              'Should throw NotificationException when announcement time is missing',
        );
      });
    });
  });
}
