import '../../../core/id/id_generator.dart';
import '../../../core/result/result.dart';
import '../../../core/time/clock_service.dart';
import '../domain/tag.dart';
import '../domain/tag_repository.dart';

final class TagService {
  TagService({
    required TagRepository tags,
    required ClockService clock,
    required IdGenerator ids,
    required Future<String> Function() deviceId,
  }) : _tags = tags,
       _clock = clock,
       _ids = ids,
       _deviceId = deviceId;

  final TagRepository _tags;
  final ClockService _clock;
  final IdGenerator _ids;
  final Future<String> Function() _deviceId;

  Future<Result<Tag>> ensureTag(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Failure(
        AppFailure(code: 'VAL-TAG', message: 'Tag name is required.'),
      );
    }
    final normalized = Tag.normalize(trimmed);
    final existing = await _tags.findByNormalizedName(normalized);
    if (existing != null) {
      return Success(existing);
    }
    final now = _clock.nowUtc();
    final tag = Tag(
      id: _ids.v4(),
      name: trimmed,
      normalizedName: normalized,
      createdAtUtc: now,
      updatedAtUtc: now,
      sourceDeviceId: await _deviceId(),
    );
    await _tags.insert(tag);
    return Success(tag);
  }

  Future<Tag?> findByName(String raw) {
    final normalized = Tag.normalize(raw);
    if (normalized.isEmpty) return Future.value(null);
    return _tags.findByNormalizedName(normalized);
  }

  Future<List<Tag>> listAll({int limit = 100}) {
    return _tags.autocomplete('', limit: limit);
  }

  Future<List<Tag>> autocomplete(String prefix, {int limit = 20}) {
    return _tags.autocomplete(prefix, limit: limit);
  }

  Future<List<Tag>> listForSession(String sessionId) {
    return _tags.listForSession(sessionId);
  }

  /// Replaces the session's tag set. Names are ensured (created if missing).
  Future<Result<List<Tag>>> setSessionTagNames({
    required String sessionId,
    required List<String> names,
  }) async {
    final resolved = <Tag>[];
    final seen = <String>{};
    for (final raw in names) {
      final result = await ensureTag(raw);
      final tag = result.valueOrNull;
      if (tag == null) {
        return switch (result) {
          Failure(:final error) => Failure(error),
          Success() => const Failure(
            AppFailure(code: 'VAL-TAG', message: 'Invalid tag.'),
          ),
        };
      }
      if (seen.add(tag.id)) {
        resolved.add(tag);
      }
    }
    await _tags.setSessionTags(sessionId, resolved.map((t) => t.id).toList());
    return Success(resolved);
  }

  Future<Result<List<Tag>>> setSessionTagIds({
    required String sessionId,
    required List<String> tagIds,
  }) async {
    await _tags.setSessionTags(sessionId, tagIds);
    return Success(await _tags.listForSession(sessionId));
  }

  /// Deletes the tag and its associations (sessions are kept).
  Future<Result<void>> deleteTag(String id) async {
    final existing = await _tags.findById(id);
    if (existing == null) {
      return const Failure(
        AppFailure(code: 'TAG-MISS', message: 'Tag not found.'),
      );
    }
    await _tags.delete(id);
    return const Success(null);
  }
}
