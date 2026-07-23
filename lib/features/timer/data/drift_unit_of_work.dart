import '../../../database/app_database.dart';
import '../domain/repositories.dart';

final class DriftUnitOfWork implements UnitOfWork {
  DriftUnitOfWork(this._db);

  final AppDatabase _db;

  @override
  Future<T> write<T>(Future<T> Function() action) {
    return _db.transaction(action);
  }
}
