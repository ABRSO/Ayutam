import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

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

/// Production implementation backed by the IANA database (`timezone` package).
final class IanaTimezoneService implements TimezoneService {
  IanaTimezoneService({required String ianaId}) : _ianaId = _canonical(ianaId);

  static var _initialized = false;

  static void ensureInitialized() {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    _initialized = true;
  }

  static String _utcId() {
    final db = tz.timeZoneDatabase.locations;
    if (db.containsKey('UTC')) return 'UTC';
    if (db.containsKey('Etc/UTC')) return 'Etc/UTC';
    return db.keys.first;
  }

  static String _canonical(String requested) {
    ensureInitialized();
    final trimmed = requested.trim();
    if (trimmed.isEmpty) return _utcId();
    if (tz.timeZoneDatabase.locations.containsKey(trimmed)) return trimmed;
    return _utcId();
  }

  static tz.Location _locationOrUtc(String id) {
    ensureInitialized();
    final db = tz.timeZoneDatabase.locations;
    return db[id] ?? db[_utcId()]!;
  }

  final String _ianaId;

  @override
  String get ianaId => _ianaId;

  @override
  int offsetMinutesAt(DateTime utc, {String? ianaId}) {
    final id = (ianaId == null || ianaId.trim().isEmpty)
        ? _ianaId
        : ianaId.trim();
    final zoned = tz.TZDateTime.from(utc.toUtc(), _locationOrUtc(id));
    return zoned.timeZoneOffset.inMinutes;
  }
}

/// Deterministic zone for unit tests.
final class FakeTimezoneService implements TimezoneService {
  const FakeTimezoneService({this.ianaId = 'UTC', this.offsetMinutes = 0});

  @override
  final String ianaId;

  /// Fixed offset used when the zone is not loaded (typically UTC tests).
  final int offsetMinutes;

  @override
  int offsetMinutesAt(DateTime utc, {String? ianaId}) => offsetMinutes;
}
