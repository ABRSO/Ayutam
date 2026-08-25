import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/time/duration_format.dart';
import '../domain/statistics_models.dart';

/// Day/week/month/year summary table with % change vs the prior period
/// ([product-spec] §2.6). Rows are virtualized so a long day view stays fast.
class SummaryTableView extends ConsumerStatefulWidget {
  const SummaryTableView({super.key, required this.bundle});

  final StatsBundle bundle;

  @override
  ConsumerState<SummaryTableView> createState() => _SummaryTableViewState();
}

class _SummaryTableViewState extends ConsumerState<SummaryTableView> {
  var _granularity = SummaryGranularity.week;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = ref
        .read(statisticsServiceProvider)
        .summaryRows(bundle: widget.bundle, granularity: _granularity);
    final narrow = MediaQuery.sizeOf(context).width < 600;
    const innerWidth = 640.0;

    final table = Column(
      children: [
        _header(theme),
        const Divider(height: 1),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    'No completed practice yet.',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _row(theme, rows[index]),
                ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<SummaryGranularity>(
          segments: const [
            ButtonSegment(value: SummaryGranularity.day, label: Text('Day')),
            ButtonSegment(value: SummaryGranularity.week, label: Text('Week')),
            ButtonSegment(
              value: SummaryGranularity.month,
              label: Text('Month'),
            ),
            ButtonSegment(value: SummaryGranularity.year, label: Text('Year')),
          ],
          selected: {_granularity},
          onSelectionChanged: (selection) =>
              setState(() => _granularity = selection.first),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: narrow
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(width: innerWidth, child: table),
                )
              : table,
        ),
      ],
    );
  }

  Widget _header(ThemeData theme) {
    final style = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Period', style: style)),
          Expanded(flex: 2, child: Text('Total', style: style)),
          Expanded(child: Text('Sessions', style: style)),
          Expanded(flex: 2, child: Text('Avg session', style: style)),
          Expanded(child: Text('Active days', style: style)),
          Expanded(flex: 2, child: Text('Change', style: style)),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, SummaryPeriodRow row) {
    final style = theme.textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(row.label, style: style)),
          Expanded(
            flex: 2,
            child: Text(formatHoursMinutes(row.totalSeconds), style: style),
          ),
          Expanded(child: Text('${row.sessionCount}', style: style)),
          Expanded(
            flex: 2,
            child: Text(
              row.sessionCount == 0
                  ? '—'
                  : formatHoursMinutes(row.averageSessionSeconds),
              style: style,
            ),
          ),
          Expanded(child: Text('${row.activeDays}', style: style)),
          Expanded(flex: 2, child: _change(theme, row)),
        ],
      ),
    );
  }

  /// Icon + text so change is never colour-only ([ux-spec] §4.7).
  Widget _change(ThemeData theme, SummaryPeriodRow row) {
    if (row.isNew) {
      return Text(
        'New',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    final change = row.changePercent;
    if (change == null) {
      return Text('—', style: theme.textTheme.bodySmall);
    }
    final up = change >= 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          up ? Icons.arrow_upward : Icons.arrow_downward,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 2),
        Text(
          '${change.abs().toStringAsFixed(change.abs() >= 100 ? 0 : 1)}%',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
