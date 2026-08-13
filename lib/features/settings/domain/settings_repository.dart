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
}
