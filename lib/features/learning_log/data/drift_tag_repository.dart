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
    final map = await listForSessions([sessionId]);
    return map[sessionId] ?? const [];
  }

  @override
  Future<Map<String, List<Tag>>> listForSessions(
    Iterable<String> sessionIds,
  ) async {
    final ids = sessionIds.toSet().toList();
    if (ids.isEmpty) return {};
    final result = <String, List<Tag>>{for (final id in ids) id: <Tag>[]};
    for (final chunk in _chunks(ids, 400)) {
      final query = _db.select(_db.tags).join([
        innerJoin(
          _db.sessionTags,
          _db.sessionTags.tagId.equalsExp(_db.tags.id),
        ),
      ])..where(_db.sessionTags.sessionId.isIn(chunk));
      final rows = await query.get();
      for (final row in rows) {
        final sessionId = row.readTable(_db.sessionTags).sessionId;
        result[sessionId]?.add(_toDomain(row.readTable(_db.tags)));
      }
    }
    for (final list in result.values) {
      list.sort((a, b) => a.normalizedName.compareTo(b.normalizedName));
    }
    return result;
  }

  @override
  Future<Set<String>> sessionIdsHavingAllTags(Set<String> tagIds) async {
    if (tagIds.isEmpty) return {};
    final ids = tagIds.toList();
    final rows = await _db
        .customSelect(
          'SELECT session_id FROM session_tags '
          'WHERE tag_id IN (${List.filled(ids.length, '?').join(', ')}) '
          'GROUP BY session_id HAVING COUNT(DISTINCT tag_id) = ?',
          variables: [
            for (final id in ids) Variable<String>(id),
            Variable<int>(ids.length),
          ],
          readsFrom: {_db.sessionTags},
        )
        .get();
    return {for (final row in rows) row.read<String>('session_id')};
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

List<List<T>> _chunks<T>(List<T> items, int size) {
  if (items.isEmpty) return const [];
  final out = <List<T>>[];
  for (var i = 0; i < items.length; i += size) {
    final end = i + size > items.length ? items.length : i + size;
    out.add(items.sublist(i, end));
  }
  return out;
}
