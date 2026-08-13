import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/skill_accent_palette.dart';
import '../../../core/time/duration_format.dart';
import '../../timer/domain/models.dart';
import '../domain/learning_log_models.dart';

String sessionModeLabel(SessionMode mode) => switch (mode) {
  SessionMode.stopwatch => 'Stopwatch',
  SessionMode.pomodoro => 'Pomodoro',
  SessionMode.manual => 'Manual',
};

IconData sessionSourceIcon(PracticeSession session) {
  if (session.mode == SessionMode.manual || session.source == 'manual') {
    return Icons.edit_calendar_outlined;
  }
  if (session.mode == SessionMode.pomodoro) {
    return Icons.timer_outlined;
  }
  return Icons.timer_outlined;
}

String formatSessionDate(DateTime utc) =>
    DateFormat.yMMMd().format(utc.toLocal());

String formatSessionTime(DateTime utc) => DateFormat.jm().format(utc.toLocal());

String formatSessionTimeRange(PracticeSession session) {
  final start = formatSessionTime(session.startAtUtc);
  final end = session.endAtUtc == null
      ? '—'
      : formatSessionTime(session.endAtUtc!);
  return '$start – $end';
}

String formatGroupHeader(DateTime local, LearningLogGroupBy groupBy) {
  switch (groupBy) {
    case LearningLogGroupBy.day:
      return DateFormat.yMMMEd().format(local);
    case LearningLogGroupBy.week:
      final weekStart = local.subtract(Duration(days: local.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      return 'Week of ${DateFormat.MMMd().format(weekStart)} – '
          '${DateFormat.MMMd().format(weekEnd)}';
    case LearningLogGroupBy.month:
      return DateFormat.yMMMM().format(local);
  }
}

String groupKeyFor(DateTime local, LearningLogGroupBy groupBy) {
  switch (groupBy) {
    case LearningLogGroupBy.day:
      return '${local.year}-${local.month}-${local.day}';
    case LearningLogGroupBy.week:
      final weekStart = local.subtract(Duration(days: local.weekday - 1));
      return '${weekStart.year}-W${weekStart.month}-${weekStart.day}';
    case LearningLogGroupBy.month:
      return '${local.year}-${local.month}';
  }
}

Color entryAccent(LearningLogEntry entry) {
  if (entry.skillAccentArgb != null) {
    return SkillAccentPalette.fromArgb(entry.skillAccentArgb);
  }
  final index =
      entry.session.skillId.hashCode.abs() % SkillAccentPalette.colors.length;
  return SkillAccentPalette.colors[index];
}

String notePreviewLine(LearningLogEntry entry, {int maxChars = 120}) {
  if (!entry.hasNote) return 'No note added';
  final note = entry.session.noteMarkdown!.trim();
  final first = note.split(RegExp(r'\r?\n')).first.trim();
  if (first.length <= maxChars) return first;
  return '${first.substring(0, maxChars)}…';
}

String durationLabel(int activeSeconds) => formatActiveDuration(activeSeconds);

typedef LearningLogGroup = ({
  String key,
  String title,
  List<LearningLogEntry> entries,
});

List<LearningLogGroup> groupLearningLogEntries(
  List<LearningLogEntry> entries,
  LearningLogGroupBy groupBy,
) {
  final map = <String, LearningLogGroup>{};
  final order = <String>[];
  for (final entry in entries) {
    final local = entry.session.startAtUtc.toLocal();
    final key = groupKeyFor(local, groupBy);
    if (!map.containsKey(key)) {
      order.add(key);
      map[key] = (
        key: key,
        title: formatGroupHeader(local, groupBy),
        entries: <LearningLogEntry>[],
      );
    }
    map[key]!.entries.add(entry);
  }
  return [for (final k in order) map[k]!];
}
