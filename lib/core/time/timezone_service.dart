/// Configured IANA timezone for session metadata and later daily allocation.
///
/// Settings can replace [ianaId] in a later phase; until then the device IANA
/// zone (or a test fake) is the configured zone.
abstract class TimezoneService {
  /// IANA identifier such as `Asia/Kolkata` — never a platform abbreviation.
  String get ianaId;

  /// UTC offset in minutes at [utc] in [ianaId], or [ianaId] when omitted.
  int offsetMinutesAt(DateTime utc, {String? ianaId});
}

/// Deterministic zone for tests (no IANA database, no native plugins).
final class FakeTimezoneService implements TimezoneService {
  const FakeTimezoneService({this.ianaId = 'UTC', this.offsetMinutes = 0});

  @override
  final String ianaId;

  /// Fixed offset used when the zone is not loaded (typically UTC tests).
  final int offsetMinutes;

  @override
  int offsetMinutesAt(DateTime utc, {String? ianaId}) => offsetMinutes;
}
