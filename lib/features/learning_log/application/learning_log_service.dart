import '../../skills/domain/skill.dart';
import '../../skills/domain/skill_repository.dart';
import '../../timer/domain/models.dart';
import '../../timer/domain/repositories.dart';
import '../data/session_search_indexer.dart';
import '../domain/learning_log_models.dart';
import '../domain/tag.dart';
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

  static const _emptySkipCap = 36;

  /// Unbounded query (tests / small sets). Prefer [queryMonth] in the UI.
  Future<List<LearningLogEntry>> query(LearningLogFilters filters) async {
    final page = await queryWindow(
      filters,
      startAfterUtc: filters.startAfterUtc,
      endBeforeUtc: filters.endBeforeUtc,
    );
    return page.entries;
  }

  Future<LearningLogPage> queryMonth(
    LearningLogFilters filters,
    CalendarMonth month,
  ) {
    return queryWindow(
      filters,
      startAfterUtc: month.startUtc,
      endBeforeUtc: month.endExclusiveUtc,
    );
  }

  Future<LearningLogPage> queryWindow(
    LearningLogFilters filters, {
    DateTime? startAfterUtc,
    DateTime? endBeforeUtc,
  }) async {
    final ids = await _matchingIds(filters);
    if (ids != null && ids.isEmpty) {
      return const LearningLogPage(
        entries: [],
        hasMoreOlder: false,
        hasMoreNewer: false,
      );
    }

    final windowStart = _later(startAfterUtc, filters.startAfterUtc);
    final windowEnd = _earlier(endBeforeUtc, filters.endBeforeUtc);
    if (windowStart != null &&
        windowEnd != null &&
        !windowStart.isBefore(windowEnd)) {
      return const LearningLogPage(
        entries: [],
        hasMoreOlder: false,
        hasMoreNewer: false,
      );
    }

    final args = _JournalArgs.fromFilters(filters, ids);
    var sessions = await _sessions.listJournalSessions(
      ids: args.ids,
      skillIds: args.skillIds,
      startAfterUtc: windowStart,
      endBeforeUtc: windowEnd,
      overlapStartUtc: filters.overlapStartUtc,
      overlapEndUtc: filters.overlapEndUtc,
      minActiveSeconds: args.minActiveSeconds,
      maxActiveSeconds: args.maxActiveSeconds,
      hasNote: args.hasNote,
      sourceEquals: args.sourceEquals,
      excludeManual: args.excludeManual,
    );
    sessions = _sort(sessions, filters.sort);

    final older = await _sessions.firstJournalStartUtc(
      ids: args.ids,
      skillIds: args.skillIds,
      startAfterUtc: filters.startAfterUtc,
      endBeforeUtc: windowStart,
      overlapStartUtc: filters.overlapStartUtc,
      overlapEndUtc: filters.overlapEndUtc,
      minActiveSeconds: args.minActiveSeconds,
      maxActiveSeconds: args.maxActiveSeconds,
      hasNote: args.hasNote,
      sourceEquals: args.sourceEquals,
      excludeManual: args.excludeManual,
      descending: true,
    );
    final newer = await _sessions.firstJournalStartUtc(
      ids: args.ids,
      skillIds: args.skillIds,
      startAfterUtc: windowEnd,
      endBeforeUtc: filters.endBeforeUtc,
      overlapStartUtc: filters.overlapStartUtc,
      overlapEndUtc: filters.overlapEndUtc,
      minActiveSeconds: args.minActiveSeconds,
      maxActiveSeconds: args.maxActiveSeconds,
      hasNote: args.hasNote,
      sourceEquals: args.sourceEquals,
      excludeManual: args.excludeManual,
      descending: false,
    );

    return LearningLogPage(
      entries: await _toEntries(sessions),
      hasMoreOlder: older != null,
      hasMoreNewer: newer != null,
    );
  }

  /// First month to show: current month, or the latest/oldest matching month
  /// when the current month is empty.
  Future<LearningLogListState> loadInitial(LearningLogFilters filters) async {
    final nowMonth = CalendarMonth.fromLocal(DateTime.now());
    CalendarMonth month = nowMonth;
    if (filters.sort == LearningLogSort.oldest) {
      final oldest = await _extremeStart(filters, descending: false);
      if (oldest != null) {
        month = CalendarMonth.fromLocal(oldest.toLocal());
      }
    } else {
      final current = await queryMonth(filters, nowMonth);
      if (current.entries.isNotEmpty || !current.hasMoreOlder) {
        return LearningLogListState(
          entries: current.entries,
          oldestLoaded: nowMonth,
          newestLoaded: nowMonth,
          hasMoreOlder: current.hasMoreOlder,
          hasMoreNewer: current.hasMoreNewer,
        );
      }
      final latest = await _extremeStart(filters, descending: true);
      if (latest != null) {
        month = CalendarMonth.fromLocal(latest.toLocal());
      }
    }
    final page = await queryMonth(filters, month);
    return LearningLogListState(
      entries: page.entries,
      oldestLoaded: month,
      newestLoaded: month,
      hasMoreOlder: page.hasMoreOlder,
      hasMoreNewer: page.hasMoreNewer,
    );
  }

  Future<LearningLogListState> loadOlder(
    LearningLogFilters filters,
    LearningLogListState current,
  ) async {
    if (!current.hasMoreOlder) return current;
    var month = current.oldestLoaded.previous;
    LearningLogPage page = await queryMonth(filters, month);
    var skipped = 0;
    while (page.entries.isEmpty &&
        page.hasMoreOlder &&
        skipped < _emptySkipCap) {
      month = month.previous;
      page = await queryMonth(filters, month);
      skipped++;
    }
    final merged = _sortEntries([
      ...current.entries,
      ...page.entries,
    ], filters.sort);
    return current.copyWith(
      entries: merged,
      oldestLoaded: month,
      hasMoreOlder: page.hasMoreOlder,
      loadingMore: false,
    );
  }

  Future<LearningLogListState> loadNewer(
    LearningLogFilters filters,
    LearningLogListState current,
  ) async {
    if (!current.hasMoreNewer) return current;
    var month = current.newestLoaded.next;
    LearningLogPage page = await queryMonth(filters, month);
    var skipped = 0;
    while (page.entries.isEmpty &&
        page.hasMoreNewer &&
        skipped < _emptySkipCap) {
      month = month.next;
      page = await queryMonth(filters, month);
      skipped++;
    }
    final merged = _sortEntries([
      ...page.entries,
      ...current.entries,
    ], filters.sort);
    return current.copyWith(
      entries: merged,
      newestLoaded: month,
      hasMoreNewer: page.hasMoreNewer,
      loadingMore: false,
    );
  }

  Future<LearningLogEntry?> getEntry(String sessionId) async {
    final session = await _sessions.findById(sessionId);
    if (session == null ||
        session.deletedAtUtc != null ||
        session.status != SessionStatus.completed) {
      return null;
    }
    final entries = await _toEntries([session]);
    return entries.isEmpty ? null : entries.first;
  }

  Future<Set<String>?> _matchingIds(LearningLogFilters filters) async {
    Set<String>? ids;
    final q = filters.query.trim();
    if (q.isNotEmpty) {
      final fts = await _indexer.searchSessionIds(q);
      if (fts.isEmpty) return <String>{};
      ids = fts.toSet();
    }
    if (filters.tagIds.isNotEmpty) {
      final tagged = await _tags.sessionIdsHavingAllTags(filters.tagIds);
      if (tagged.isEmpty) return <String>{};
      ids = ids == null ? tagged : ids.intersection(tagged);
      if (ids.isEmpty) return <String>{};
    }
    return ids;
  }

  Future<DateTime?> _extremeStart(
    LearningLogFilters filters, {
    required bool descending,
  }) async {
    final ids = await _matchingIds(filters);
    if (ids != null && ids.isEmpty) return null;
    final args = _JournalArgs.fromFilters(filters, ids);
    return _sessions.firstJournalStartUtc(
      ids: args.ids,
      skillIds: args.skillIds,
      startAfterUtc: filters.startAfterUtc,
      endBeforeUtc: filters.endBeforeUtc,
      overlapStartUtc: filters.overlapStartUtc,
      overlapEndUtc: filters.overlapEndUtc,
      minActiveSeconds: args.minActiveSeconds,
      maxActiveSeconds: args.maxActiveSeconds,
      hasNote: args.hasNote,
      sourceEquals: args.sourceEquals,
      excludeManual: args.excludeManual,
      descending: descending,
    );
  }

  Future<List<LearningLogEntry>> _toEntries(
    List<PracticeSession> sessions,
  ) async {
    if (sessions.isEmpty) return const [];
    final tagMap = await _tags.listForSessions(sessions.map((s) => s.id));
    final skillIds = sessions.map((s) => s.skillId).toSet();
    final skills = await _skills.listByIds(skillIds);
    final skillMap = <String, Skill>{for (final s in skills) s.id: s};
    return [
      for (final session in sessions)
        LearningLogEntry(
          session: session,
          skillName: skillMap[session.skillId]?.name ?? 'Unknown skill',
          skillAccentArgb: skillMap[session.skillId]?.accentArgb,
          tags: tagMap[session.id] ?? const <Tag>[],
        ),
    ];
  }

  List<LearningLogEntry> _sortEntries(
    List<LearningLogEntry> entries,
    LearningLogSort sort,
  ) {
    final copy = List<LearningLogEntry>.from(entries);
    switch (sort) {
      case LearningLogSort.newest:
        copy.sort(
          (a, b) => b.session.startAtUtc.compareTo(a.session.startAtUtc),
        );
      case LearningLogSort.oldest:
        copy.sort(
          (a, b) => a.session.startAtUtc.compareTo(b.session.startAtUtc),
        );
      case LearningLogSort.longest:
        copy.sort(
          (a, b) => b.session.activeSeconds.compareTo(a.session.activeSeconds),
        );
      case LearningLogSort.shortest:
        copy.sort(
          (a, b) => a.session.activeSeconds.compareTo(b.session.activeSeconds),
        );
    }
    return copy;
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

  static DateTime? _later(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  static DateTime? _earlier(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }
}

final class _JournalArgs {
  const _JournalArgs({
    required this.ids,
    required this.skillIds,
    required this.minActiveSeconds,
    required this.maxActiveSeconds,
    required this.hasNote,
    required this.sourceEquals,
    required this.excludeManual,
  });

  factory _JournalArgs.fromFilters(
    LearningLogFilters filters,
    Set<String>? ids,
  ) {
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
    bool? hasNote;
    switch (filters.notePresence) {
      case NotePresenceFilter.withNotes:
        hasNote = true;
      case NotePresenceFilter.withoutNotes:
        hasNote = false;
      case NotePresenceFilter.any:
        hasNote = null;
    }
    return _JournalArgs(
      ids: ids,
      skillIds: filters.skillIds.isEmpty ? null : filters.skillIds,
      minActiveSeconds: filters.minActiveSeconds,
      maxActiveSeconds: filters.maxActiveSeconds,
      hasNote: hasNote,
      sourceEquals: sourceEquals,
      excludeManual: excludeManual,
    );
  }

  final Set<String>? ids;
  final Set<String>? skillIds;
  final int? minActiveSeconds;
  final int? maxActiveSeconds;
  final bool? hasNote;
  final String? sourceEquals;
  final bool excludeManual;
}
