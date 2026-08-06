import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../domain/tag.dart';
import '../domain/tag_repository.dart';

final class DriftTagRepository implements TagRepository {
  DriftTagRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Tag?> findById(String id) async {
    final row = await (_db.select(
      _db.tags,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<Tag?> findByNormalizedName(String normalizedName) async {
    final row = await (_db.select(
      _db.tags,
    )..where((t) => t.normalizedName.equals(normalizedName))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> insert(Tag tag) async {
    await _db.into(_db.tags).insert(_companion(tag));
  }

  @override
  Future<void> update(Tag tag) async {
    await _db.update(_db.tags).replace(_companion(tag));
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.sessionTags)..where((t) => t.tagId.equals(id))).go();
    await (_db.delete(_db.tags)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<List<Tag>> autocomplete(String prefix, {int limit = 20}) async {
    final normalized = Tag.normalize(prefix);
    final query = _db.select(_db.tags)
      ..orderBy([(t) => OrderingTerm.asc(t.normalizedName)])
      ..limit(limit);
    if (normalized.isNotEmpty) {
      query.where((t) => t.normalizedName.like('$normalized%'));
    }
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<Tag>> listForSession(String sessionId) async {
    final query = _db.select(_db.tags).join([
      innerJoin(_db.sessionTags, _db.sessionTags.tagId.equalsExp(_db.tags.id)),
    ])..where(_db.sessionTags.sessionId.equals(sessionId));
    final rows = await query.get();
    final tags = rows.map((r) => _toDomain(r.readTable(_db.tags))).toList();
    tags.sort((a, b) => a.normalizedName.compareTo(b.normalizedName));
    return tags;
  }

  @override
  Future<void> setSessionTags(String sessionId, List<String> tagIds) async {
    await (_db.delete(
      _db.sessionTags,
    )..where((t) => t.sessionId.equals(sessionId))).go();
    for (final tagId in tagIds.toSet()) {
      await _db
          .into(_db.sessionTags)
          .insert(
            SessionTagsCompanion.insert(sessionId: sessionId, tagId: tagId),
          );
    }
  }

  @override
  Future<void> clearSessionTags(String sessionId) async {
    await (_db.delete(
      _db.sessionTags,
    )..where((t) => t.sessionId.equals(sessionId))).go();
  }

  Tag _toDomain(TagRow row) {
    return Tag(
      id: row.id,
      name: row.name,
      normalizedName: row.normalizedName,
      createdAtUtc: DateTime.fromMillisecondsSinceEpoch(
        row.createdAtUtc,
        isUtc: true,
      ),
      updatedAtUtc: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAtUtc,
        isUtc: true,
      ),
      sourceDeviceId: row.sourceDeviceId,
    );
  }

  TagsCompanion _companion(Tag tag) {
    return TagsCompanion.insert(
      id: tag.id,
      name: tag.name,
      normalizedName: tag.normalizedName,
      createdAtUtc: tag.createdAtUtc.millisecondsSinceEpoch,
      updatedAtUtc: tag.updatedAtUtc.millisecondsSinceEpoch,
      sourceDeviceId: tag.sourceDeviceId,
    );
  }
}
