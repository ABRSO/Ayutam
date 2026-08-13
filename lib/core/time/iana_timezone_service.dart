import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'timezone_service.dart';

/// Production IANA implementation.
///
/// Kept out of [timezone_service.dart] so unit tests can inject
/// [FakeTimezoneService] without compiling the timezone database or importing
/// `flutter_timezone` (both abort `flutter test --coverage` on Linux CI).
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
