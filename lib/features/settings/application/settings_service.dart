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
    return _settings.watchValue(SettingsKeys.reducedMotion).map(_parseBool);
  }

  Future<bool> reducedMotion() async {
    return _parseBool(await _settings.readValue(SettingsKeys.reducedMotion));
  }

  Future<void> setReducedMotion(bool enabled) async {
    await _settings.writeValue(
      key: SettingsKeys.reducedMotion,
      valueJson: jsonEncode(enabled),
      updatedAtUtc: _clock.nowUtc(),
      sourceDeviceId: await _deviceId(),
    );
  }

  static bool _parseBool(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return false;
    }
    final decoded = jsonDecode(raw);
    return decoded == true;
  }
}
