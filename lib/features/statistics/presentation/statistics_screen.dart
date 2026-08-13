import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/time/duration_format.dart';
import '../../../core/time/timezone_service.dart';
import '../../skills/domain/skill.dart';
import '../domain/statistics_models.dart';
import 'cumulative_chart.dart';
import 'practice_heatmap.dart';
import 'summary_table.dart';

/// Statistics: scope control + summary card above Cumulative / Heatmap /
/// Summary table views ([product-spec] §2.6, [ux-spec] §4.7).
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with WidgetsBindingObserver {
  var _view = 0;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _armMidnightTimer();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadIfDayRolledOver();
      _armMidnightTimer();
    }
  }

  /// Fires just past the next configured-local midnight so an idle, visible
  /// screen still rolls its day-relative metrics without user interaction.
  void _armMidnightTimer() {
    _midnightTimer?.cancel();
    final now = ref.read(clockServiceProvider).nowUtc();
    final timezones = ref.read(timezoneServiceProvider);
    final today = configuredLocalDayAt(now, timezones);
    final nextMidnightUtc = utcStartOfConfiguredDay(
      today.add(const Duration(days: 1)),
      timezones,
    );
    var wait = nextMidnightUtc.difference(now) + const Duration(seconds: 1);
    if (wait <= Duration.zero) wait = const Duration(minutes: 1);
    _midnightTimer = Timer(wait, () {
      if (!mounted) return;
      _reloadIfDayRolledOver();
      _armMidnightTimer();
    });
  }

  /// Streak, today-grace, and the 4-week window are day-relative; a bundle
  /// computed yesterday must not survive past configured-local midnight.
  void _reloadIfDayRolledOver() {
    final bundle = ref.read(statsBundleProvider).asData?.value;
    if (bundle == null) return;
    final today = configuredLocalDayAt(
      ref.read(clockServiceProvider).nowUtc(),
      ref.read(timezoneServiceProvider),
    );
    if (bundle.generatedForDay != today) {
      ref.invalidate(statsBundleProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bundleAsync = ref.watch(statsBundleProvider);
    final skills =
        ref.watch(allSkillsProvider).asData?.value ?? const <Skill>[];
    final scope = ref.watch(statsScopeProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reloadIfDayRolledOver();
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: bundleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load statistics: $e')),
        data: (bundle) {
          if (!bundle.hasAnyCompletedSession) {
            return const _EmptyStatisticsState();
          }
          final desktop = MediaQuery.sizeOf(context).width >= 840;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ScopeControl(scope: scope, skills: skills),
                    const SizedBox(height: 8),
                    _SummaryCard(bundle: bundle, scope: scope, skills: skills),
                    const SizedBox(height: 8),
                    _viewSwitcher(desktop),
                    const SizedBox(height: 8),
                    Expanded(child: _view3(bundle, scope, skills)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _viewSwitcher(bool desktop) {
    final segments = desktop
        ? const ['Cumulative', 'Heatmap', 'Summary Table']
        : const ['Progress', 'Activity', 'Summary'];
    return SegmentedButton<int>(
      segments: [
        for (var i = 0; i < segments.length; i++)
          ButtonSegment(value: i, label: Text(segments[i])),
      ],
      selected: {_view},
      onSelectionChanged: (selection) =>
          setState(() => _view = selection.first),
    );
  }

  Widget _view3(StatsBundle bundle, StatsScope scope, List<Skill> skills) {
    return switch (_view) {
      0 => SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: CumulativeChartView(
          bundle: bundle,
          scope: scope,
          skills: skills,
        ),
      ),
      1 => PracticeHeatmap(bundle: bundle, scope: scope, skills: skills),
      _ => SummaryTableView(bundle: bundle),
    };
  }
}

class _EmptyStatisticsState extends StatelessWidget {
  const _EmptyStatisticsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Complete a session to begin building your progress chart.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class _ScopeControl extends ConsumerWidget {
  const _ScopeControl({required this.scope, required this.skills});

  final StatsScope scope;
  final List<Skill> skills;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = switch (scope.kind) {
      StatsScopeKind.all => 'All skills',
      StatsScopeKind.single =>
        skills.where((s) => s.id == scope.singleSkillId).firstOrNull?.name ??
            'Skill',
      StatsScopeKind.compare => 'Comparing ${scope.skillIds.length} skills',
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: () => _pickScope(context, ref),
        icon: const Icon(Icons.filter_list),
        label: Text(label),
      ),
    );
  }

  Future<void> _pickScope(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(statsScopeProvider.notifier);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: Icon(
                scope.kind == StatsScopeKind.all
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              title: const Text('All skills'),
              onTap: () {
                notifier.set(const StatsScope.all());
                Navigator.pop(sheetContext);
              },
            ),
            for (final skill in skills)
              ListTile(
                leading: Icon(
                  scope.kind == StatsScopeKind.single &&
                          scope.singleSkillId == skill.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text(
                  skill.status == SkillStatus.archived
                      ? '${skill.name} (archived)'
                      : skill.name,
                ),
                onTap: () {
                  notifier.set(StatsScope.single(skill.id));
                  Navigator.pop(sheetContext);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.stacked_line_chart),
              title: const Text('Compare skills…'),
              subtitle: const Text('Up to ${StatsScope.maxCompare} skills'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _pickCompare(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCompare(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    final selected = <String>{
      if (scope.kind == StatsScopeKind.compare) ...scope.skillIds,
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Compare skills'),
          content: SizedBox(
            width: 360,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final skill in skills)
                  CheckboxListTile(
                    value: selected.contains(skill.id),
                    title: Text(
                      skill.status == SkillStatus.archived
                          ? '${skill.name} (archived)'
                          : skill.name,
                    ),
                    onChanged:
                        selected.length >= StatsScope.maxCompare &&
                            !selected.contains(skill.id)
                        ? null
                        : (checked) => setState(() {
                            if (checked == true) {
                              selected.add(skill.id);
                            } else {
                              selected.remove(skill.id);
                            }
                          }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text('Compare'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && selected.isNotEmpty) {
      ref.read(statsScopeProvider.notifier).set(StatsScope.compare(selected));
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.bundle,
    required this.scope,
    required this.skills,
  });

  final StatsBundle bundle;
  final StatsScope scope;
  final List<Skill> skills;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = bundle.summary;
    final single = scope.kind == StatsScopeKind.single;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _Metric(
                  label: 'Total active',
                  value: formatHoursMinutes(summary.totalActiveSeconds),
                ),
                if (single && summary.progressFraction != null)
                  _Metric(
                    label: 'Progress',
                    value:
                        '${(summary.progressFraction! * 100).toStringAsFixed(summary.progressFraction! >= 1 ? 0 : 1)}%',
                  ),
                if (single && summary.remainingSeconds != null)
                  _Metric(
                    label: 'Remaining',
                    value: formatHoursMinutes(summary.remainingSeconds!),
                  ),
                _Metric(label: 'Sessions', value: '${summary.sessionCount}'),
                _Metric(
                  label: '4-week average',
                  value:
                      '${formatHoursMinutes(summary.fourWeekAverageWeeklySeconds)} / week',
                ),
                _Metric(
                  label: 'Streak',
                  value:
                      '${summary.streakDays} day${summary.streakDays == 1 ? '' : 's'}',
                ),
              ],
            ),
            if (single) ...[
              const SizedBox(height: 12),
              Text(
                summary.projectedCompletionDay != null
                    ? 'At your recent 4-week average, you would reach your '
                          'target around '
                          '${DateFormat('d MMMM y').format(summary.projectedCompletionDay!)}.'
                    : 'Projection unavailable — it needs about a week of '
                          'recent practice and an unmet target.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
