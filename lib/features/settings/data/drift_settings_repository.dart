import '../../../database/app_database.dart';
import '../domain/settings_repository.dart';

final class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<String?> watchValue(String key) {
    return (_db.select(
      _db.appSettings,
    )..where((t) => t.key.equals(key))).watch().map((rows) {
      if (rows.isEmpty) {
        return null;
      }
      return rows.first.valueJson;
    });
  }

  @override
  Future<String?> readValue(String key) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.valueJson;
  }

  @override
  Future<void> writeValue({
    required String key,
    required String valueJson,
    required DateTime updatedAtUtc,
    required String sourceDeviceId,
  }) async {
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: key,
            valueJson: valueJson,
            updatedAtUtc: updatedAtUtc.millisecondsSinceEpoch,
            sourceDeviceId: sourceDeviceId,
          ),
        );
  }
}
