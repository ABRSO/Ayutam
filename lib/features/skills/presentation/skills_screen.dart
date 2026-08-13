import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../app/providers.dart';
import '../../../core/theme/skill_accent_palette.dart';
import '../../../core/time/duration_format.dart';
import '../../learning_log/domain/learning_log_models.dart';
import '../../timer/domain/models.dart';
import '../../timer/presentation/pre_session_sheet.dart';
import '../domain/skill.dart';
import 'skill_editor_sheet.dart';
import 'skill_home_filter.dart';

class SkillsScreen extends ConsumerStatefulWidget {
  const SkillsScreen({super.key});

  @override
  ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends ConsumerState<SkillsScreen> {
  var _filter = SkillHomeFilter.inProgress;
  var _searching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skillsAsync = ref.watch(allSkillsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search skills',
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : const Text('Ayutam'),
        actions: [
          IconButton(
            tooltip: _searching ? 'Close search' : 'Search skills',
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) {
                  _searchController.clear();
                }
              });
            },
            icon: Icon(_searching ? Icons.close : Icons.search),
          ),
        ],
      ),
      body: skillsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load skills: $e')),
        data: (all) {
          if (all.isEmpty) {
            return const _EmptySkillsState();
          }
          final filtered = skillsMatchingQuery(
            skillsForHomeFilter(all, _filter),
            _searchController.text,
          );
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final filter in SkillHomeFilter.values)
                        ChoiceChip(
                          label: Text(_filterLabel(filter)),
                          selected: _filter == filter,
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _FilterEmptyState(filter: _filter)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _SkillCard(skill: filtered[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await showSkillEditorSheet(context);
          if (saved && mounted) {
            ref.invalidate(activeSkillsProvider);
            ref.invalidate(allSkillsProvider);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Skill'),
        tooltip: 'Create skill',
      ),
    );
  }

  String _filterLabel(SkillHomeFilter filter) => switch (filter) {
    SkillHomeFilter.inProgress => 'In Progress',
    SkillHomeFilter.completed => 'Completed',
    SkillHomeFilter.archived => 'Archived',
  };
}

class _EmptySkillsState extends StatelessWidget {
  const _EmptySkillsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Create your first skill to begin tracking deliberate practice.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Skills live only on this device. Use Play to start a stopwatch session.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterEmptyState extends StatelessWidget {
  const _FilterEmptyState({required this.filter});

  final SkillHomeFilter filter;

  @override
  Widget build(BuildContext context) {
    final text = switch (filter) {
      SkillHomeFilter.inProgress => 'No skills in progress.',
      SkillHomeFilter.completed => 'No completed skills.',
      SkillHomeFilter.archived => 'No archived skills.',
    };
    return Center(
      child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class _SkillCard extends ConsumerStatefulWidget {
  const _SkillCard({required this.skill});

  final Skill skill;

  @override
  ConsumerState<_SkillCard> createState() => _SkillCardState();
}

class _SkillCardState extends ConsumerState<_SkillCard> {
  var _expanded = false;
  Future<List<PracticeSession>>? _recent;

  Skill get skill => widget.skill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _skillAccent(skill);
    final archived = skill.status == SkillStatus.archived;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            skill.name,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Skill actions',
                          onSelected: _onMenu,
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            PopupMenuItem(
                              value: archived ? 'restore' : 'archive',
                              child: Text(archived ? 'Restore' : 'Archive'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${formatHoursMinutes(skill.completedActiveSeconds)} / '
                      '${formatHoursMinutes(skill.targetSeconds)}',
                      style: durationMonoStyle(
                        context,
                        base: theme.textTheme.bodyMedium,
                      ).copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${skill.progressPercent}% · '
                      '${formatHoursMinutes(skill.remainingSeconds)} remaining',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: skill.progressBarValue,
                      color: accent,
                      backgroundColor: accent.withValues(alpha: 0.18),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _expanded = !_expanded;
                                if (_expanded) {
                                  _recent = ref
                                      .read(sessionRepositoryProvider)
                                      .listRecentCompletedForSkill(skill.id);
                                }
                              });
                            },
                            child: Text(_expanded ? 'Hide recent' : 'Recent'),
                          ),
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(learningLogFiltersProvider.notifier)
                                  .setFilters(
                                    LearningLogFilters(skillIds: {skill.id}),
                                  );
                              ref
                                  .read(appShellIndexProvider.notifier)
                                  .setIndex(1);
                            },
                            child: const Text('View all in Learning Log'),
                          ),
                          if (archived)
                            FilledButton.tonalIcon(
                              onPressed: () => _restore(skill),
                              icon: const Icon(Icons.unarchive_outlined),
                              label: const Text('Restore'),
                            )
                          else
                            FilledButton.tonalIcon(
                              onPressed: () =>
                                  showPreSessionSheet(context, skill: skill),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Play'),
                            ),
                        ],
                      ),
                    ),
                    if (_expanded) ...[
                      const SizedBox(height: 8),
                      FutureBuilder<List<PracticeSession>>(
                        future: _recent,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: LinearProgressIndicator(),
                            );
                          }
                          final sessions = snapshot.data ?? const [];
                          if (sessions.isEmpty) {
                            return Text(
                              'No sessions yet.',
                              style: theme.textTheme.bodySmall,
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final session in sessions)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '${session.title?.trim().isNotEmpty == true ? session.title : 'Untitled session'} · ${formatHoursMinutes(session.activeSeconds)}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onMenu(String value) async {
    switch (value) {
      case 'edit':
        final saved = await showSkillEditorSheet(context, skill: skill);
        if (saved && mounted) {
          ref.invalidate(activeSkillsProvider);
          ref.invalidate(allSkillsProvider);
        }
        return;
      case 'archive':
        await _archiveWithUndo(skill);
        return;
      case 'restore':
        await _restore(skill);
        return;
      case 'delete':
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Permanent deletion'),
            content: const Text(
              'Permanent skill deletion lands with backups in Phase 5, '
              'because it must create a safety snapshot first. Archive the '
              'skill to hide it from Home until then.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
    }
  }

  Future<void> _restore(Skill skill) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(skillServiceProvider).restore(skill.id);
    if (!mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(activeSkillsProvider);
        ref.invalidate(allSkillsProvider);
      },
      failure: (f) =>
          messenger.showSnackBar(SnackBar(content: Text(f.message))),
    );
  }

  Future<void> _archiveWithUndo(Skill skill) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(skillServiceProvider).archive(skill.id);
    if (!mounted) return;
    await result.when(
      success: (_) async {
        ref.invalidate(activeSkillsProvider);
        ref.invalidate(allSkillsProvider);
        messenger.hideCurrentSnackBar();
        final snack = messenger.showSnackBar(
          SnackBar(
            content: Text('Archived "${skill.name}"'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                final restore = await ref
                    .read(skillServiceProvider)
                    .restore(skill.id);
                restore.when(
                  success: (_) {
                    ref.invalidate(activeSkillsProvider);
                    ref.invalidate(allSkillsProvider);
                  },
                  failure: (f) => messenger.showSnackBar(
                    SnackBar(content: Text(f.message)),
                  ),
                );
              },
            ),
          ),
        );
        await snack.closed;
      },
      failure: (f) async {
        messenger.showSnackBar(SnackBar(content: Text(f.message)));
      },
    );
  }
}

Color _skillAccent(Skill skill) {
  if (skill.accentArgb != null) {
    return SkillAccentPalette.fromArgb(skill.accentArgb);
  }
  final index = skill.id.hashCode.abs() % SkillAccentPalette.colors.length;
  return SkillAccentPalette.colors[index];
}
