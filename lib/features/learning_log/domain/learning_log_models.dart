import '../../timer/domain/models.dart';
import 'tag.dart';

/// How Learning Log groups list rows.
enum LearningLogGroupBy { day, week, month }

/// Sort order for Learning Log.
enum LearningLogSort { newest, oldest, longest, shortest }

/// With/without notes filter.
enum NotePresenceFilter { any, withNotes, withoutNotes }

/// Manual vs timed source filter.
enum SessionSourceFilter { any, manual, timed }

/// AND-combined filters for Learning Log queries.
final class LearningLogFilters {
  const LearningLogFilters({
    this.query = '',
    this.skillIds = const {},
    this.tagIds = const {},
    this.startAfterUtc,
    this.endBeforeUtc,
    this.minActiveSeconds,
    this.maxActiveSeconds,
    this.notePresence = NotePresenceFilter.any,
    this.sourceFilter = SessionSourceFilter.any,
    this.sort = LearningLogSort.newest,
    this.groupBy = LearningLogGroupBy.day,
  });

  final String query;
  final Set<String> skillIds;
  final Set<String> tagIds;
  final DateTime? startAfterUtc;
  final DateTime? endBeforeUtc;
  final int? minActiveSeconds;
  final int? maxActiveSeconds;
  final NotePresenceFilter notePresence;
  final SessionSourceFilter sourceFilter;
  final LearningLogSort sort;
  final LearningLogGroupBy groupBy;

  bool get hasActiveFilters =>
      query.trim().isNotEmpty ||
      skillIds.isNotEmpty ||
      tagIds.isNotEmpty ||
      startAfterUtc != null ||
      endBeforeUtc != null ||
      minActiveSeconds != null ||
      maxActiveSeconds != null ||
      notePresence != NotePresenceFilter.any ||
      sourceFilter != SessionSourceFilter.any;

  int get activeFilterCount {
    var n = 0;
    if (query.trim().isNotEmpty) n++;
    if (skillIds.isNotEmpty) n++;
    if (tagIds.isNotEmpty) n++;
    if (startAfterUtc != null || endBeforeUtc != null) n++;
    if (minActiveSeconds != null || maxActiveSeconds != null) n++;
    if (notePresence != NotePresenceFilter.any) n++;
    if (sourceFilter != SessionSourceFilter.any) n++;
    return n;
  }

  LearningLogFilters copyWith({
    String? query,
    Set<String>? skillIds,
    Set<String>? tagIds,
    DateTime? startAfterUtc,
    DateTime? endBeforeUtc,
    int? minActiveSeconds,
    int? maxActiveSeconds,
    NotePresenceFilter? notePresence,
    SessionSourceFilter? sourceFilter,
    LearningLogSort? sort,
    LearningLogGroupBy? groupBy,
    bool clearStartAfter = false,
    bool clearEndBefore = false,
    bool clearMinActive = false,
    bool clearMaxActive = false,
  }) {
    return LearningLogFilters(
      query: query ?? this.query,
      skillIds: skillIds ?? this.skillIds,
      tagIds: tagIds ?? this.tagIds,
      startAfterUtc: clearStartAfter
          ? null
          : (startAfterUtc ?? this.startAfterUtc),
      endBeforeUtc: clearEndBefore ? null : (endBeforeUtc ?? this.endBeforeUtc),
      minActiveSeconds: clearMinActive
          ? null
          : (minActiveSeconds ?? this.minActiveSeconds),
      maxActiveSeconds: clearMaxActive
          ? null
          : (maxActiveSeconds ?? this.maxActiveSeconds),
      notePresence: notePresence ?? this.notePresence,
      sourceFilter: sourceFilter ?? this.sourceFilter,
      sort: sort ?? this.sort,
      groupBy: groupBy ?? this.groupBy,
    );
  }

  LearningLogFilters clearAll() => const LearningLogFilters();
}

/// List row for Learning Log (joined skill + tags).
final class LearningLogEntry {
  const LearningLogEntry({
    required this.session,
    required this.skillName,
    required this.skillAccentArgb,
    required this.tags,
  });

  final PracticeSession session;
  final String skillName;
  final int? skillAccentArgb;
  final List<Tag> tags;

  String get displayTitle {
    final title = session.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    final note = session.noteMarkdown?.trim();
    if (note != null && note.isNotEmpty) {
      final firstLine = note.split(RegExp(r'\r?\n')).first.trim();
      if (firstLine.isNotEmpty) return firstLine;
    }
    return 'Untitled session';
  }

  bool get hasNote {
    final note = session.noteMarkdown?.trim();
    return note != null && note.isNotEmpty;
  }
}

/// Local calendar month used as the Learning Log fetch window.
final class CalendarMonth {
  const CalendarMonth(this.year, this.month)
    : assert(month >= 1 && month <= 12);

  factory CalendarMonth.fromLocal(DateTime local) =>
      CalendarMonth(local.year, local.month);

  final int year;
  final int month;

  DateTime get startLocal => DateTime(year, month, 1);

  DateTime get endExclusiveLocal => DateTime(year, month + 1, 1);

  DateTime get startUtc => startLocal.toUtc();

  DateTime get endExclusiveUtc => endExclusiveLocal.toUtc();

  CalendarMonth get previous =>
      month == 1 ? CalendarMonth(year - 1, 12) : CalendarMonth(year, month - 1);

  CalendarMonth get next =>
      month == 12 ? CalendarMonth(year + 1, 1) : CalendarMonth(year, month + 1);

  @override
  bool operator ==(Object other) =>
      other is CalendarMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';
}

/// One month (or date-bounded window) of Learning Log rows.
final class LearningLogPage {
  const LearningLogPage({
    required this.entries,
    required this.hasMoreOlder,
    required this.hasMoreNewer,
  });

  final List<LearningLogEntry> entries;
  final bool hasMoreOlder;
  final bool hasMoreNewer;
}

/// Accumulated month windows currently shown in the Learning Log list.
final class LearningLogListState {
  const LearningLogListState({
    required this.entries,
    required this.oldestLoaded,
    required this.newestLoaded,
    required this.hasMoreOlder,
    required this.hasMoreNewer,
    this.loadingMore = false,
  });

  final List<LearningLogEntry> entries;
  final CalendarMonth oldestLoaded;
  final CalendarMonth newestLoaded;
  final bool hasMoreOlder;
  final bool hasMoreNewer;
  final bool loadingMore;

  LearningLogListState copyWith({
    List<LearningLogEntry>? entries,
    CalendarMonth? oldestLoaded,
    CalendarMonth? newestLoaded,
    bool? hasMoreOlder,
    bool? hasMoreNewer,
    bool? loadingMore,
  }) {
    return LearningLogListState(
      entries: entries ?? this.entries,
      oldestLoaded: oldestLoaded ?? this.oldestLoaded,
      newestLoaded: newestLoaded ?? this.newestLoaded,
      hasMoreOlder: hasMoreOlder ?? this.hasMoreOlder,
      hasMoreNewer: hasMoreNewer ?? this.hasMoreNewer,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

/// Overlap of a proposed manual/edit window with an existing session.
final class SessionOverlap {
  const SessionOverlap({
    required this.sessionId,
    required this.startAtUtc,
    required this.endAtUtc,
  });

  final String sessionId;
  final DateTime startAtUtc;
  final DateTime endAtUtc;
}
