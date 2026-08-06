import 'tag.dart';

abstract class TagRepository {
  Future<Tag?> findById(String id);

  Future<Tag?> findByNormalizedName(String normalizedName);

  Future<void> insert(Tag tag);

  Future<void> update(Tag tag);

  Future<void> delete(String id);

  Future<List<Tag>> autocomplete(String prefix, {int limit = 20});

  Future<List<Tag>> listForSession(String sessionId);

  Future<void> setSessionTags(String sessionId, List<String> tagIds);

  Future<void> clearSessionTags(String sessionId);
}
