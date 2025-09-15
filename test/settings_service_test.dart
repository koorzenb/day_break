import 'package:day_break/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'settings_service_test.mocks.dart';

@GenerateMocks([Box])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsService', () {
    late SettingsService settingsService;
    late MockBox mockBox;

    setUp(() {
      mockBox = MockBox();
      settingsService = SettingsService(mockBox);
    });

    test('setLocation saves location to the box', () async {
      const location = 'New York';
      when(mockBox.put('location', location)).thenAnswer((_) async => Future.value());
      await settingsService.setLocation(location);
      verify(mockBox.put('location', location));

      when(mockBox.get('location')).thenReturn(location);
      expect(settingsService.location, location);
    });

    test('location getter retrieves location from the box', () {});

    test('setAnnouncementHour saves hour to the box', () async {
      const hour = 7;
      when(mockBox.put('announcementHour', hour)).thenAnswer((_) async => Future.value());
      await settingsService.setAnnouncementHour(hour);
      verify(mockBox.put('announcementHour', hour));

      when(mockBox.get('announcementHour')).thenReturn(hour);
      expect(settingsService.announcementHour, hour);
    });

    test('setAnnouncementMinute saves minute to the box', () async {
      const minute = 30;
      when(mockBox.put('announcementMinute', minute)).thenAnswer((_) async => Future.value());
      await settingsService.setAnnouncementMinute(minute);
      verify(mockBox.put('announcementMinute', minute));

      when(mockBox.get('announcementMinute')).thenReturn(minute);
      expect(settingsService.announcementMinute, minute);
    });
  });
}
