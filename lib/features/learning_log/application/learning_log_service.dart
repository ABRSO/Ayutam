import '../../skills/domain/skill.dart';
import '../../skills/domain/skill_repository.dart';
import '../../timer/domain/models.dart';
import '../../timer/domain/repositories.dart';
import '../data/session_search_indexer.dart';
import '../domain/learning_log_models.dart';
import '../domain/tag_repository.dart';

final class LearningLogService {
  LearningLogService({
    required SessionRepository sessions,
    required SkillRepository skills,
    required TagRepository tags,
    required SessionSearchIndexer indexer,
  }) : _sessions = sessions,
       _skills = skills,
       _tags = tags,
       _indexer = indexer;

  final SessionRepository _sessions;
  final SkillRepository _skills;
  final TagRepository _tags;
  final SessionSearchIndexer _indexer;

  Future<List<LearningLogEntry>> query(LearningLogFilters filters) async {
    Set<String>? ftsIds;
    final q = filters.query.trim();
    if (q.isNotEmpty) {
      final ids = await _indexer.searchSessionIds(q);
      if (ids.isEmpty) return const [];
      ftsIds = ids.toSet();
    }

    String? sourceEquals;
    var excludeManual = false;
    switch (filters.sourceFilter) {
      case SessionSourceFilter.manual:
        sourceEquals = 'manual';
      case SessionSourceFilter.timed:
        excludeManual = true;
      case SessionSourceFilter.any:
        break;
    }

    var sessions = await _sessions.listJournalSessions(
      ids: ftsIds,
      skillIds: filters.skillIds.isEmpty ? null : filters.skillIds,
      startAfterUtc: filters.startAfterUtc,
      endBeforeUtc: filters.endBeforeUtc,
      minActiveSeconds: filters.minActiveSeconds,
      maxActiveSeconds: filters.maxActiveSeconds,
      sourceEquals: sourceEquals,
      excludeManual: excludeManual,
    );

    switch (filters.notePresence) {
      case NotePresenceFilter.withNotes:
        sessions = sessions
            .where((s) => (s.noteMarkdown?.trim().isNotEmpty ?? false))
            .toList();
      case NotePresenceFilter.withoutNotes:
        sessions = sessions
            .where((s) => !(s.noteMarkdown?.trim().isNotEmpty ?? false))
            .toList();
      case NotePresenceFilter.any:
        break;
    }

    if (filters.tagIds.isNotEmpty) {
      final filtered = <PracticeSession>[];
      for (final session in sessions) {
        final tags = await _tags.listForSession(session.id);
        final tagIdSet = tags.map((t) => t.id).toSet();
        if (filters.tagIds.every(tagIdSet.contains)) {
          filtered.add(session);
        }
      }
      sessions = filtered;
    }

    sessions = _sort(sessions, filters.sort);

    final skillCache = <String, Skill?>{};
    final entries = <LearningLogEntry>[];
    for (final session in sessions) {
      if (!skillCache.containsKey(session.skillId)) {
        skillCache[session.skillId] = await _skills.findById(session.skillId);
      }
      final skill = skillCache[session.skillId];
      final tags = await _tags.listForSession(session.id);
      entries.add(
        LearningLogEntry(
          session: session,
          skillName: skill?.name ?? 'Unknown skill',
          skillAccentArgb: skill?.accentArgb,
          tags: tags,
        ),
      );
    }
    return entries;
  }

  Future<LearningLogEntry?> getEntry(String sessionId) async {
    final session = await _sessions.findById(sessionId);
    if (session == null ||
        session.deletedAtUtc != null ||
        session.status != SessionStatus.completed) {
      return null;
    }
    final skill = await _skills.findById(session.skillId);
    final tags = await _tags.listForSession(sessionId);
    return LearningLogEntry(
      session: session,
      skillName: skill?.name ?? 'Unknown skill',
      skillAccentArgb: skill?.accentArgb,
      tags: tags,
    );
  }

  List<PracticeSession> _sort(
    List<PracticeSession> sessions,
    LearningLogSort sort,
  ) {
    final copy = List<PracticeSession>.from(sessions);
    switch (sort) {
      case LearningLogSort.newest:
        copy.sort((a, b) => b.startAtUtc.compareTo(a.startAtUtc));
      case LearningLogSort.oldest:
        copy.sort((a, b) => a.startAtUtc.compareTo(b.startAtUtc));
      case LearningLogSort.longest:
        copy.sort((a, b) => b.activeSeconds.compareTo(a.activeSeconds));
      case LearningLogSort.shortest:
        copy.sort((a, b) => a.activeSeconds.compareTo(b.activeSeconds));
    }
    return copy;
  }
}
