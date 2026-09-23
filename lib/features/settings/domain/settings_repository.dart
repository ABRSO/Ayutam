/// Typed KV over `app_settings` (mergeable JSON values).
abstract class SettingsRepository {
  Stream<String?> watchValue(String key);

  Future<String?> readValue(String key);

  Future<void> writeValue({
    required String key,
    required String valueJson,
    required DateTime updatedAtUtc,
    required String sourceDeviceId,
  });
}

abstract final class SettingsKeys {
  static const reducedMotion = 'appearance.reduced_motion';
  static const weeklyBackupReminder = 'backup.weekly_reminder_enabled';
  static const keepScreenAwake = 'timer.keep_screen_awake';
  static const forceLandscapeAndroid = 'timer.force_landscape_android';

  /// Device-local; never merge via backup.
  static const closeToTrayExplained = 'desktop.close_to_tray_explained';
}
