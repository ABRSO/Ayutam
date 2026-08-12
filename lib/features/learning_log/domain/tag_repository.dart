import 'tag.dart';

abstract class TagRepository {
  Future<Tag?> findById(String id);

  Future<Tag?> findByNormalizedName(String normalizedName);

  Future<void> insert(Tag tag);

  Future<void> update(Tag tag);

  Future<void> delete(String id);

  Future<List<Tag>> autocomplete(String prefix, {int limit = 20});

  Future<List<Tag>> listForSession(String sessionId);

  /// Tags for many sessions in one (chunked) query. Missing ids map to empty lists.
  Future<Map<String, List<Tag>>> listForSessions(Iterable<String> sessionIds);

  /// Session ids that have **all** of [tagIds] (AND). Empty [tagIds] yields empty.
  Future<Set<String>> sessionIdsHavingAllTags(Set<String> tagIds);

  Future<void> setSessionTags(String sessionId, List<String> tagIds);

  Future<void> clearSessionTags(String sessionId);
}
