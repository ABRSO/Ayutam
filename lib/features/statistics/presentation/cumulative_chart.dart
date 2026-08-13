import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/theme/skill_accent_palette.dart';
import '../../../core/time/duration_format.dart';
import '../../../core/time/timezone_service.dart';
import '../../skills/domain/skill.dart';
import '../application/statistics_service.dart';
import '../domain/statistics_models.dart';
import 'chart_png_export.dart';

/// Cumulative practice chart ([product-spec] §2.6): range presets + custom,
/// auto aggregation, milestone/goal lines, tooltips, projection overlay,
/// fullscreen, and PNG export. fl_chart stays behind this adapter (ADR-013).
class CumulativeChartView extends ConsumerStatefulWidget {
  const CumulativeChartView({
    super.key,
    required this.bundle,
    required this.scope,
    required this.skills,
    this.expanded = false,
    this.initialRange = ChartRange.month,
    this.initialCustomRange,
  });

  final StatsBundle bundle;
  final StatsScope scope;
  final List<Skill> skills;

  /// Fullscreen page sets this to fill the viewport.
  final bool expanded;
  final ChartRange initialRange;

  /// Carries a picked custom window into fullscreen.
  final DateTimeRange? initialCustomRange;

  @override
  ConsumerState<CumulativeChartView> createState() =>
      _CumulativeChartViewState();
}

class _CumulativeChartViewState extends ConsumerState<CumulativeChartView> {
  static const _milestoneHours = [10, 100, 500, 1000, 5000];

  late ChartRange _range = widget.initialRange;
  late DateTimeRange? _customRange = widget.initialCustomRange;
  final _exportKey = GlobalKey();

  DateTime get _today {
    final clock = ref.read(clockServiceProvider);
    final timezones = ref.read(timezoneServiceProvider);
    return configuredLocalDayAt(clock.nowUtc(), timezones);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = _today;
    final first = widget.bundle.firstActivityDay ?? today;

    var windowStart = switch (_range) {
      ChartRange.week => today.subtract(const Duration(days: 6)),
      ChartRange.month => today.subtract(const Duration(days: 29)),
      ChartRange.threeMonths => today.subtract(const Duration(days: 90)),
      ChartRange.sixMonths => today.subtract(const Duration(days: 182)),
      ChartRange.year => today.subtract(const Duration(days: 364)),
      ChartRange.all => first,
      ChartRange.custom =>
        _customRange == null
            ? today.subtract(const Duration(days: 29))
            : DateTime(
                _customRange!.start.year,
                _customRange!.start.month,
                _customRange!.start.day,
              ),
    };
    var windowEnd = _range == ChartRange.custom && _customRange != null
        ? DateTime(
            _customRange!.end.year,
            _customRange!.end.month,
            _customRange!.end.day,
          )
        : today;
    if (windowEnd.isAfter(today)) windowEnd = today;
    if (windowStart.isAfter(windowEnd)) windowStart = windowEnd;

    final spanDays = windowEnd.difference(windowStart).inDays + 1;
    final aggregation = StatisticsService.aggregationForSpanDays(spanDays);
    final lines = _buildLines(windowStart, windowEnd, aggregation);
    final projection = _projectionOverlay(windowEnd, lines);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _controls(context),
        const SizedBox(height: 8),
        widget.expanded
            ? Expanded(child: _chartCard(theme, lines, projection, windowStart))
            : SizedBox(
                height: MediaQuery.sizeOf(context).width >= 840 ? 420 : 280,
                child: _chartCard(theme, lines, projection, windowStart),
              ),
        if (widget.scope.kind == StatsScopeKind.compare)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _legend(theme, lines),
          ),
      ],
    );
  }

  Widget _controls(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final range in ChartRange.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(_rangeLabel(range)),
                      selected: _range == range,
                      onSelected: (_) => _selectRange(range),
                    ),
                  ),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: 'Export PNG',
          onPressed: _exportPng,
          icon: const Icon(Icons.image_outlined),
        ),
        if (!widget.expanded)
          IconButton(
            tooltip: 'Fullscreen',
            onPressed: _openFullscreen,
            icon: const Icon(Icons.fullscreen),
          ),
      ],
    );
  }

  Future<void> _selectRange(ChartRange range) async {
    if (range == ChartRange.custom) {
      final today = _today;
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: today,
        initialDateRange: _customRange,
      );
      if (picked == null) return;
      setState(() {
        _customRange = picked;
        _range = ChartRange.custom;
      });
      return;
    }
    setState(() => _range = range);
  }

  Future<void> _openFullscreen() async {
    final bundle = widget.bundle;
    final scope = widget.scope;
    final skills = widget.skills;
    final range = _range;
    final customRange = _customRange;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Cumulative practice')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: CumulativeChartView(
              bundle: bundle,
              scope: scope,
              skills: skills,
              expanded: true,
              initialRange: range,
              initialCustomRange: customRange,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportPng() async {
    final messenger = ScaffoldMessenger.of(context);
    final stamp = DateFormat('yyyy-MM-dd-HHmm').format(DateTime.now());
    final path = await exportChartPng(
      _exportKey,
      suggestedName: 'ayutam-progress-$stamp.png',
    );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(path == null ? 'Export cancelled.' : 'Saved to $path'),
      ),
    );
  }

  List<CumulativeLine> _buildLines(
    DateTime windowStart,
    DateTime windowEnd,
    ChartAggregation aggregation,
  ) {
    final skillById = {for (final s in widget.skills) s.id: s};
    if (widget.scope.kind == StatsScopeKind.compare) {
      final lines = <CumulativeLine>[];
      for (final entry in widget.bundle.dailyTotalsBySkill.entries) {
        final skill = skillById[entry.key];
        lines.add(
          CumulativeLine(
            skillId: entry.key,
            label: skill?.name ?? 'Skill',
            accentArgb: skill?.accentArgb,
            points: StatisticsService.cumulativeSeries(
              daily: entry.value,
              windowStart: windowStart,
              windowEnd: windowEnd,
              aggregation: aggregation,
            ),
          ),
        );
      }
      lines.sort((a, b) => a.label.compareTo(b.label));
      return lines;
    }
    final single = widget.scope.kind == StatsScopeKind.single
        ? skillById[widget.scope.singleSkillId]
        : null;
    return [
      CumulativeLine(
        skillId: single?.id,
        label: single?.name ?? 'All skills',
        accentArgb: single?.accentArgb,
        points: StatisticsService.cumulativeSeries(
          daily: widget.bundle.dailyTotals,
          windowStart: windowStart,
          windowEnd: windowEnd,
          aggregation: aggregation,
        ),
      ),
    ];
  }

  /// Dashed continuation from today's total to the projected completion.
  /// Only meaningful for a single skill on the All range, where the x axis
  /// can extend past today.
  ({DateTime endDay, double targetHours})? _projectionOverlay(
    DateTime windowEnd,
    List<CumulativeLine> lines,
  ) {
    final summary = widget.bundle.summary;
    if (widget.scope.kind != StatsScopeKind.single ||
        _range != ChartRange.all ||
        summary.projectedCompletionDay == null ||
        summary.targetSeconds == null ||
        lines.isEmpty ||
        lines.first.points.isEmpty) {
      return null;
    }
    return (
      endDay: summary.projectedCompletionDay!,
      targetHours: summary.targetSeconds! / 3600,
    );
  }

  Widget _chartCard(
    ThemeData theme,
    List<CumulativeLine> lines,
    ({DateTime endDay, double targetHours})? projection,
    DateTime windowStart,
  ) {
    return RepaintBoundary(
      key: _exportKey,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          child: _AdaptedLineChart(
            lines: lines,
            windowStart: windowStart,
            projection: projection,
            goalHours: widget.scope.kind == StatsScopeKind.single
                ? (widget.bundle.summary.targetSeconds ?? 0) / 3600
                : null,
            milestoneHours: _milestoneHours,
            reducedMotion: MediaQuery.of(context).disableAnimations,
          ),
        ),
      ),
    );
  }

  Widget _legend(ThemeData theme, List<CumulativeLine> lines) {
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        for (var i = 0; i < lines.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: const Size(28, 12),
                painter: _LegendSwatchPainter(
                  color: _lineColor(lines[i], theme),
                  dashArray: _dashFor(i),
                ),
              ),
              const SizedBox(width: 6),
              Text(lines[i].label, style: theme.textTheme.bodySmall),
            ],
          ),
      ],
    );
  }

  static String _rangeLabel(ChartRange range) => switch (range) {
    ChartRange.week => '7d',
    ChartRange.month => '30d',
    ChartRange.threeMonths => '3mo',
    ChartRange.sixMonths => '6mo',
    ChartRange.year => '1yr',
    ChartRange.all => 'All',
    ChartRange.custom => 'Custom',
  };
}

Color _lineColor(CumulativeLine line, ThemeData theme) {
  if (line.accentArgb != null) {
    return SkillAccentPalette.fromArgb(line.accentArgb);
  }
  return theme.colorScheme.primary;
}

/// Comparison lines differ by dash pattern as well as colour so state is
/// never colour-only ([ux-spec] §4.7).
List<int>? _dashFor(int index) => switch (index % 5) {
  0 => null,
  1 => const [8, 4],
  2 => const [4, 4],
  3 => const [2, 5],
  _ => const [10, 3, 2, 3],
};

class _AdaptedLineChart extends StatelessWidget {
  const _AdaptedLineChart({
    required this.lines,
    required this.windowStart,
    required this.projection,
    required this.goalHours,
    required this.milestoneHours,
    required this.reducedMotion,
  });

  final List<CumulativeLine> lines;
  final DateTime windowStart;
  final ({DateTime endDay, double targetHours})? projection;
  final double? goalHours;
  final List<int> milestoneHours;
  final bool reducedMotion;

  double _x(DateTime day) => day.difference(windowStart).inDays.toDouble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    var maxDataHours = 0.0;
    var maxX = 1.0;
    final barData = <LineChartBarData>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.points.isEmpty) continue;
      final spots = [
        for (final point in line.points)
          FlSpot(_x(point.day), point.cumulativeSeconds / 3600),
      ];
      maxDataHours = math.max(maxDataHours, spots.last.y);
      maxX = math.max(maxX, spots.last.x);
      barData.add(
        LineChartBarData(
          spots: spots,
          color: _lineColor(line, theme),
          barWidth: 2.5,
          isCurved: false,
          dashArray: _dashFor(i),
          dotData: FlDotData(show: spots.length <= 32),
        ),
      );
    }

    var maxY = math.max(maxDataHours * 1.15, 1.0);
    if (projection != null) {
      // Extend the axes so the dashed run-out to the goal fits.
      maxY = math.max(maxY, projection!.targetHours * 1.05);
      maxX = math.max(maxX, _x(projection!.endDay));
      final lastPoints = lines.first.points;
      final last = lastPoints.last;
      barData.add(
        LineChartBarData(
          spots: [
            FlSpot(_x(last.day), last.cumulativeSeconds / 3600),
            FlSpot(_x(projection!.endDay), projection!.targetHours),
          ],
          color: theme.colorScheme.onSurfaceVariant,
          barWidth: 1.5,
          isCurved: false,
          dashArray: const [4, 6],
          dotData: const FlDotData(show: false),
        ),
      );
    }

    final horizontalLines = <HorizontalLine>[
      for (final hours in milestoneHours)
        if (hours <= maxY && (goalHours == null || hours < goalHours!))
          HorizontalLine(
            y: hours.toDouble(),
            color: theme.colorScheme.outlineVariant,
            strokeWidth: 1,
            dashArray: const [2, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              style: theme.textTheme.labelSmall,
              labelResolver: (_) => '${hours}h',
            ),
          ),
      if (goalHours != null && goalHours! > 0 && goalHours! <= maxY)
        HorizontalLine(
          y: goalHours!,
          color: theme.colorScheme.primary,
          strokeWidth: 1.5,
          dashArray: const [6, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
            labelResolver: (_) => 'Goal',
          ),
        ),
    ];

    if (barData.isEmpty) {
      return Center(
        child: Text(
          'No practice in this range yet.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    final span = maxX <= 0 ? 1.0 : maxX;
    return LineChart(
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 250),
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
        lineBarsData: barData,
        extraLinesData: ExtraLinesData(horizontalLines: horizontalLines),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  '${value >= 10 ? value.round() : value.toStringAsFixed(1)}h',
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: math.max(span / 4, 1),
              getTitlesWidget: (value, meta) {
                final day = windowStart.add(Duration(days: value.round()));
                final label = span > 320
                    ? DateFormat('MMM yy').format(day)
                    : DateFormat('d MMM').format(day);
                return SideTitleWidget(
                  meta: meta,
                  child: Text(label, style: theme.textTheme.labelSmall),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => [
              for (final spot in spots)
                LineTooltipItem(
                  '${DateFormat('EEE, d MMM y').format(windowStart.add(Duration(days: spot.x.round())))}\n'
                  '${formatHoursMinutes((spot.y * 3600).round())}',
                  theme.textTheme.labelMedium!.copyWith(
                    color: theme.colorScheme.onInverseSurface,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendSwatchPainter extends CustomPainter {
  const _LegendSwatchPainter({required this.color, this.dashArray});

  final Color color;
  final List<int>? dashArray;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3;
    final y = size.height / 2;
    final dashes = dashArray;
    if (dashes == null) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }
    var x = 0.0;
    var i = 0;
    while (x < size.width) {
      final len = dashes[i % dashes.length].toDouble();
      if (i.isEven) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + len, size.width), y),
          paint,
        );
      }
      x += len;
      i++;
    }
  }

  @override
  bool shouldRepaint(_LegendSwatchPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dashArray != dashArray;
}
