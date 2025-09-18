import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsService extends GetxService {
  Box? _settingsBox;

  // Allow a box to be injected for testing
  SettingsService([this._settingsBox]);

  Future<SettingsService> init() async {
    // Don't re-initialize if a box was already injected
    if (_settingsBox == null) {
      await Hive.initFlutter();
      _settingsBox = await Hive.openBox('settings');
    }
    return this;
  }

  String? get location => _settingsBox?.get('location');
  Future<void> setLocation(String location) => _settingsBox!.put('location', location);

  int? get announcementHour => _settingsBox?.get('announcementHour');
  Future<void> setAnnouncementHour(int hour) => _settingsBox!.put('announcementHour', hour);

  int? get announcementMinute => _settingsBox?.get('announcementMinute');
  Future<void> setAnnouncementMinute(int minute) => _settingsBox!.put('announcementMinute', minute);

  Future<void> setAnnouncementTime(int hour, int minute) async {
    await setAnnouncementHour(hour);
    await setAnnouncementMinute(minute);
  }

  Future<void> clearSettings() async {
    await _settingsBox!.clear();
  }
}
