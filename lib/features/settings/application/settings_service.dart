import 'dart:convert';

import '../../../core/time/clock_service.dart';
import '../domain/settings_repository.dart';

/// Appearance and other mergeable settings stored in `app_settings`.
final class SettingsService {
  SettingsService({
    required SettingsRepository settings,
    required ClockService clock,
    required Future<String> Function() deviceId,
  }) : _settings = settings,
       _clock = clock,
       _deviceId = deviceId;

  final SettingsRepository _settings;
  final ClockService _clock;
  final Future<String> Function() _deviceId;

  Stream<bool> watchReducedMotion() {
    return _settings
        .watchValue(SettingsKeys.reducedMotion)
        .map((raw) => _parseBool(raw, defaultValue: false));
  }

  Future<bool> reducedMotion() async {
    return _parseBool(
      await _settings.readValue(SettingsKeys.reducedMotion),
      defaultValue: false,
    );
  }

  Future<void> setReducedMotion(bool enabled) async {
    await _settings.writeValue(
      key: SettingsKeys.reducedMotion,
      valueJson: jsonEncode(enabled),
      updatedAtUtc: _clock.nowUtc(),
      sourceDeviceId: await _deviceId(),
    );
  }

  Stream<bool> watchWeeklyBackupReminder() {
    return _settings
        .watchValue(SettingsKeys.weeklyBackupReminder)
        .map((raw) => _parseBool(raw, defaultValue: true));
  }

  Future<bool> weeklyBackupReminder() async {
    return _parseBool(
      await _settings.readValue(SettingsKeys.weeklyBackupReminder),
      defaultValue: true,
    );
  }

  Future<void> setWeeklyBackupReminder(bool enabled) async {
    await _settings.writeValue(
      key: SettingsKeys.weeklyBackupReminder,
      valueJson: jsonEncode(enabled),
      updatedAtUtc: _clock.nowUtc(),
      sourceDeviceId: await _deviceId(),
    );
  }

  static bool _parseBool(String? raw, {required bool defaultValue}) {
    if (raw == null || raw.trim().isEmpty) {
      return defaultValue;
    }
    final decoded = jsonDecode(raw);
    return decoded == true;
  }
}
