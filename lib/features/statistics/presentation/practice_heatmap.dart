import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/theme/skill_accent_palette.dart';
import '../../../core/time/duration_format.dart';
import '../../../core/time/timezone_service.dart';
import '../../learning_log/domain/learning_log_models.dart';
import '../../skills/domain/skill.dart';
import '../domain/statistics_models.dart';

/// Custom calendar heatmap (ADR-013): weekly columns, weekday rows, fixed
/// buckets, and a day popover with “Open in Learning Log”.
class PracticeHeatmap extends ConsumerStatefulWidget {
  const PracticeHeatmap({
    super.key,
    required this.bundle,
    required this.scope,
    required this.skills,
  });

  final StatsBundle bundle;
  final StatsScope scope;
  final List<Skill> skills;

  @override
  ConsumerState<PracticeHeatmap> createState() => _PracticeHeatmapState();
}

class _PracticeHeatmapState extends ConsumerState<PracticeHeatmap> {
  static const double _cell = 14;
  static const double _gap = 3;

  /// Null → rolling last 12 months.
  int? _year;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Latest weeks sit at the right edge; start scrolled to them.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatestWeeks());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLatestWeeks() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  DateTime get _today {
    final clock = ref.read(clockServiceProvider);
    final timezones = ref.read(timezoneServiceProvider);
    return configuredLocalDayAt(clock.nowUtc(), timezones);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = _today;

    final DateTime windowEnd;
    final DateTime windowStart;
    if (_year == null) {
      windowEnd = today;
      windowStart = today.subtract(const Duration(days: 364));
    } else {
      windowStart = DateTime(_year!, 1, 1);
      final yearEnd = DateTime(_year!, 12, 31);
      windowEnd = yearEnd.isAfter(today) ? today : yearEnd;
    }
    // Grid columns are Monday-start weeks covering the window.
    final gridStart = windowStart.subtract(
      Duration(days: windowStart.weekday - DateTime.monday),
    );
    final weeks = (windowEnd.difference(gridStart).inDays ~/ 7) + 1;

    final firstYear = (widget.bundle.firstActivityDay ?? today).year;
    final years = [for (var y = today.year; y >= firstYear; y--) y];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Activity', style: theme.textTheme.titleMedium),
              const Spacer(),
              DropdownButton<int?>(
                value: _year,
                underline: const SizedBox.shrink(),
                onChanged: (value) {
                  setState(() => _year = value);
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _scrollToLatestWeeks(),
                  );
                },
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Last 12 months'),
                  ),
                  for (final year in years)
                    DropdownMenuItem<int?>(value: year, child: Text('$year')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _weekdayLabels(theme),
                const SizedBox(width: 4),
                _grid(theme, gridStart, windowStart, windowEnd, weeks),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _legend(theme),
        ],
      ),
    );
  }

  Widget _weekdayLabels(ThemeData theme) {
    const labels = ['Mon', '', 'Wed', '', 'Fri', '', ''];
    return Padding(
      // Aligns with the month-label row above the grid.
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        children: [
          for (final label in labels)
            SizedBox(
              height: _cell + _gap,
              width: 30,
              child: Text(
                label,
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.right,
              ),
            ),
        ],
      ),
    );
  }

  Widget _grid(
    ThemeData theme,
    DateTime gridStart,
    DateTime windowStart,
    DateTime windowEnd,
    int weeks,
  ) {
    final monthLabels = <Widget>[];
    final columns = <Widget>[];
    String? lastMonth;
    for (var week = 0; week < weeks; week++) {
      final weekStart = gridStart.add(Duration(days: week * 7));
      final monthKey = DateFormat('MMM yy').format(weekStart);
      final firstWeekOfMonth =
          weekStart.day <= 7 && monthKey != lastMonth && week > 0 ||
          (week == 0);
      monthLabels.add(
        SizedBox(
          width: _cell + _gap,
          child: firstWeekOfMonth
              ? Text(
                  DateFormat('MMM').format(weekStart),
                  style: theme.textTheme.labelSmall,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                )
              : const SizedBox.shrink(),
        ),
      );
      if (firstWeekOfMonth) lastMonth = monthKey;

      columns.add(
        Column(
          children: [
            for (var dow = 0; dow < 7; dow++)
              _dayCell(
                theme,
                weekStart.add(Duration(days: dow)),
                windowStart,
                windowEnd,
              ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 14, child: Row(children: monthLabels)),
        const SizedBox(height: 4),
        Row(children: columns),
      ],
    );
  }

  Widget _dayCell(
    ThemeData theme,
    DateTime day,
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    if (day.isBefore(windowStart) || day.isAfter(windowEnd)) {
      return const SizedBox(width: _cell + _gap, height: _cell + _gap);
    }
    final seconds = widget.bundle.dailyTotals[day] ?? 0;
    final bucket = heatmapBucketFor(seconds);
    final date = DateFormat('EEE, d MMM y').format(day);
    final duration = seconds == 0 ? 'No practice' : formatHoursMinutes(seconds);

    return Padding(
      padding: const EdgeInsets.only(right: _gap, bottom: _gap),
      child: Semantics(
        label: '$date: $duration',
        button: true,
        child: Tooltip(
          waitDuration: const Duration(milliseconds: 400),
          message: '$date · $duration',
          child: InkWell(
            onTap: () => _showDayPopover(day, seconds),
            borderRadius: BorderRadius.circular(3),
            child: Container(
              width: _cell,
              height: _cell,
              decoration: BoxDecoration(
                color: _bucketColor(theme, bucket),
                borderRadius: BorderRadius.circular(3),
                border: bucket == HeatmapBucket.none
                    ? Border.all(color: theme.colorScheme.outlineVariant)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Neutral green scale for all skills; the single-skill view tints with the
  /// skill accent ([ux-spec] §2 Colour).
  Color _bucketColor(ThemeData theme, HeatmapBucket bucket) {
    final Color base;
    if (widget.scope.kind == StatsScopeKind.single) {
      final skill = widget.skills
          .where((s) => s.id == widget.scope.singleSkillId)
          .firstOrNull;
      base = skill?.accentArgb != null
          ? SkillAccentPalette.fromArgb(skill!.accentArgb)
          : theme.colorScheme.primary;
    } else {
      base = const Color(0xFF2EA043);
    }
    return switch (bucket) {
      HeatmapBucket.none =>
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      HeatmapBucket.upTo30m => base.withValues(alpha: 0.28),
      HeatmapBucket.upTo1h => base.withValues(alpha: 0.45),
      HeatmapBucket.upTo2h => base.withValues(alpha: 0.62),
      HeatmapBucket.upTo4h => base.withValues(alpha: 0.8),
      HeatmapBucket.over4h => base,
    };
  }

  Widget _legend(ThemeData theme) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Less', style: theme.textTheme.labelSmall),
        for (final bucket in HeatmapBucket.values)
          Container(
            width: _cell,
            height: _cell,
            decoration: BoxDecoration(
              color: _bucketColor(theme, bucket),
              borderRadius: BorderRadius.circular(3),
              border: bucket == HeatmapBucket.none
                  ? Border.all(color: theme.colorScheme.outlineVariant)
                  : null,
            ),
          ),
        Text('More', style: theme.textTheme.labelSmall),
        const SizedBox(width: 12),
        Text(
          'None · ≤30m · ≤1h · ≤2h · ≤4h · 4h+',
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }

  Future<void> _showDayPopover(DateTime day, int seconds) async {
    final date = DateFormat('EEEE, d MMMM y').format(day);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(date),
        content: Text(
          seconds == 0
              ? 'No practice recorded.'
              : 'Total practice: ${formatHoursMinutes(seconds)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          FilledButton.tonal(
            onPressed: () {
              Navigator.pop(dialogContext);
              _openInLearningLog(day);
            },
            child: const Text('Open in Learning Log'),
          ),
        ],
      ),
    );
  }

  void _openInLearningLog(DateTime day) {
    final timezones = ref.read(timezoneServiceProvider);
    final dayStart = utcStartOfConfiguredDay(day, timezones);
    final nextDayStart = utcStartOfConfiguredDay(
      day.add(const Duration(days: 1)),
      timezones,
    );
    // Overlap (not start-based) matching, so a cross-midnight session shows
    // on every local day it contributed practice to — same rule the heatmap
    // itself uses for allocation.
    ref
        .read(learningLogFiltersProvider.notifier)
        .setFilters(
          LearningLogFilters(
            skillIds: widget.scope.filterIds ?? const {},
            overlapStartUtc: dayStart,
            overlapEndUtc: nextDayStart,
          ),
        );
    ref.read(appShellIndexProvider.notifier).setIndex(1);
  }
}
