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

/// Calendar day containing [utc] in the configured timezone.
///
/// The returned [DateTime] is used for date-only comparisons; its time is
/// midnight and it does not represent an instant in the configured zone.
DateTime configuredLocalDayAt(DateTime utc, TimezoneService timezones) {
  final normalizedUtc = utc.toUtc();
  final shifted = normalizedUtc.add(
    Duration(minutes: timezones.offsetMinutesAt(normalizedUtc)),
  );
  return DateTime(shifted.year, shifted.month, shifted.day);
}

String formatLocalDay(DateTime day) {
  return '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
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
