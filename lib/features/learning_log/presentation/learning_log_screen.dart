import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../timer/presentation/pre_session_sheet.dart';
import '../domain/learning_log_models.dart';
import 'learning_log_card.dart';
import 'learning_log_filters_sheet.dart';
import 'learning_log_format.dart';
import 'manual_session_sheet.dart';
import 'session_detail_pane.dart';
import 'session_detail_screen.dart';
import 'session_edit_sheet.dart';

class LearningLogScreen extends ConsumerStatefulWidget {
  const LearningLogScreen({super.key});

  @override
  ConsumerState<LearningLogScreen> createState() => _LearningLogScreenState();
}

class _LearningLogScreenState extends ConsumerState<LearningLogScreen> {
  final _searchController = TextEditingController();
  final _listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(learningLogFiltersProvider).query;
    _listScrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _listScrollController.removeListener(_onScroll);
    _searchController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_listScrollController.hasClients) return;
    final pos = _listScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 480) {
      ref.read(learningLogListProvider.notifier).loadMore();
    }
  }

  Future<void> _calendarJump() async {
    final filters = ref.read(learningLogFiltersProvider);
    // Prefer the overlap day (heatmap deep link) when choosing the picker
    // seed; Jump replaces overlap with start-based From/To for that day.
    final initial =
        filters.overlapStartUtc?.toLocal() ??
        filters.startAfterUtc?.toLocal() ??
        DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Jump to date',
    );
    if (picked == null) return;
    ref
        .read(learningLogFiltersProvider.notifier)
        .update(
          (f) => f.copyWith(
            startAfterUtc: inclusiveStartOfLocalDay(picked),
            endBeforeUtc: exclusiveUtcAfterLocalDay(picked),
            clearOverlap: true,
          ),
        );
    if (_listScrollController.hasClients) {
      await _listScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _openDetail(
    LearningLogEntry entry,
    List<LearningLogEntry> entries, {
    required bool twoPane,
  }) async {
    ref
        .read(selectedLearningLogSessionIdProvider.notifier)
        .select(entry.session.id);
    if (twoPane) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SessionDetailScreen(sessionId: entry.session.id, entries: entries),
      ),
    );
  }

  Future<void> _softDelete(LearningLogEntry entry) async {
    final messenger = ScaffoldMessenger.of(context);
    final sessionId = entry.session.id;
    final result = await ref
        .read(sessionNoteServiceProvider)
        .softDelete(sessionId);
    if (!mounted) return;
    await result.when(
      success: (_) async {
        final selected = ref.read(selectedLearningLogSessionIdProvider);
        if (selected == sessionId) {
          ref.read(selectedLearningLogSessionIdProvider.notifier).select(null);
        }
        ref.invalidate(learningLogListProvider);
        ref.invalidate(activeSkillsProvider);
        messenger.hideCurrentSnackBar();
        final snack = messenger.showSnackBar(
          SnackBar(
            content: const Text('Session deleted'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                final restore = await ref
                    .read(sessionNoteServiceProvider)
                    .restore(sessionId);
                restore.when(
                  success: (_) {
                    ref.invalidate(learningLogListProvider);
                    ref.invalidate(activeSkillsProvider);
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

  Future<void> _startSessionCta() async {
    final skills = await ref.read(skillServiceProvider).listActive();
    if (!mounted) return;
    if (skills.isEmpty) {
      ref.read(appShellIndexProvider.notifier).setIndex(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a skill first, then start a session.'),
        ),
      );
      return;
    }
    await showPreSessionSheet(context, skill: skills.first);
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(learningLogFiltersProvider);
    final listAsync = ref.watch(learningLogListProvider);
    final selectedId = ref.watch(selectedLearningLogSessionIdProvider);
    final width = MediaQuery.sizeOf(context).width;
    final twoPane = width >= AppConstants.learningLogTwoPaneBreakpoint;
    final filterCount = filters.activeFilterCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Log'),
        actions: [
          IconButton(
            tooltip: 'Jump to date',
            onPressed: _calendarJump,
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          PopupMenuButton<LearningLogSort>(
            tooltip: 'Sort',
            initialValue: filters.sort,
            onSelected: (sort) {
              ref
                  .read(learningLogFiltersProvider.notifier)
                  .update((f) => f.copyWith(sort: sort));
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: LearningLogSort.newest,
                child: Text('Newest'),
              ),
              PopupMenuItem(
                value: LearningLogSort.oldest,
                child: Text('Oldest'),
              ),
              PopupMenuItem(
                value: LearningLogSort.longest,
                child: Text('Longest'),
              ),
              PopupMenuItem(
                value: LearningLogSort.shortest,
                child: Text('Shortest'),
              ),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await showManualSessionSheet(context);
          if (saved) ref.invalidate(learningLogListProvider);
        },
        icon: const Icon(Icons.edit_calendar_outlined),
        label: const Text('Manual entry'),
        tooltip: 'Add manual session',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search notes, titles, tags…',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: filters.query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(learningLogFiltersProvider.notifier)
                                    .update((f) => f.copyWith(query: ''));
                              },
                              icon: const Icon(Icons.clear),
                            ),
                    ),
                    onChanged: (value) {
                      ref
                          .read(learningLogFiltersProvider.notifier)
                          .update((f) => f.copyWith(query: value));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Badge(
                  isLabelVisible: filterCount > 0,
                  label: Text('$filterCount'),
                  child: IconButton.filledTonal(
                    tooltip: 'Filters',
                    onPressed: () => showLearningLogFiltersSheet(context),
                    icon: const Icon(Icons.filter_list),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<LearningLogGroupBy>(
              segments: const [
                ButtonSegment(
                  value: LearningLogGroupBy.day,
                  label: Text('Day'),
                ),
                ButtonSegment(
                  value: LearningLogGroupBy.week,
                  label: Text('Week'),
                ),
                ButtonSegment(
                  value: LearningLogGroupBy.month,
                  label: Text('Month'),
                ),
              ],
              selected: {filters.groupBy},
              onSelectionChanged: (s) {
                ref
                    .read(learningLogFiltersProvider.notifier)
                    .update((f) => f.copyWith(groupBy: s.first));
              },
            ),
          ),
          Expanded(
            child: listAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load: $e')),
              data: (listState) {
                final entries = listState.entries;
                // Keep selection valid for two-pane.
                if (twoPane && selectedId == null && entries.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref
                        .read(selectedLearningLogSessionIdProvider.notifier)
                        .select(entries.first.session.id);
                  });
                }

                final list = _LearningLogList(
                  entries: entries,
                  groupBy: filters.groupBy,
                  selectedId: selectedId,
                  scrollController: _listScrollController,
                  hasFilters: filters.hasActiveFilters,
                  loadingMore: listState.loadingMore,
                  hasMore: filters.sort == LearningLogSort.oldest
                      ? listState.hasMoreNewer
                      : listState.hasMoreOlder,
                  onLoadMore: () =>
                      ref.read(learningLogListProvider.notifier).loadMore(),
                  onClearFilters: () {
                    _searchController.clear();
                    ref.read(learningLogFiltersProvider.notifier).clear();
                  },
                  onStartSession: _startSessionCta,
                  onOpen: (entry) =>
                      _openDetail(entry, entries, twoPane: twoPane),
                  onEdit: (entry) async {
                    final changed = await showSessionEditSheet(
                      context,
                      entry: entry,
                    );
                    if (changed) {
                      ref.invalidate(learningLogListProvider);
                    }
                  },
                  onDelete: _softDelete,
                );

                if (!twoPane) return list;

                LearningLogEntry? selected;
                for (final e in entries) {
                  if (e.session.id == selectedId) {
                    selected = e;
                    break;
                  }
                }

                return Row(
                  children: [
                    Expanded(flex: 5, child: list),
                    const VerticalDivider(width: 1),
                    Expanded(
                      flex: 6,
                      child: selected == null
                          ? const Center(
                              child: Text('Select a session to view details.'),
                            )
                          : SessionDetailPane(
                              entry: selected,
                              entries: entries,
                              embedded: true,
                              onDeleted: () {
                                ref
                                    .read(
                                      selectedLearningLogSessionIdProvider
                                          .notifier,
                                    )
                                    .select(null);
                              },
                              onChanged: () =>
                                  ref.invalidate(learningLogListProvider),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningLogList extends StatelessWidget {
  const _LearningLogList({
    required this.entries,
    required this.groupBy,
    required this.selectedId,
    required this.scrollController,
    required this.hasFilters,
    required this.loadingMore,
    required this.hasMore,
    required this.onLoadMore,
    required this.onClearFilters,
    required this.onStartSession,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final List<LearningLogEntry> entries;
  final LearningLogGroupBy groupBy;
  final String? selectedId;
  final ScrollController scrollController;
  final bool hasFilters;
  final bool loadingMore;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final VoidCallback onClearFilters;
  final VoidCallback onStartSession;
  final ValueChanged<LearningLogEntry> onOpen;
  final ValueChanged<LearningLogEntry> onEdit;
  final ValueChanged<LearningLogEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _EmptyLearningLog(
        hasFilters: hasFilters,
        onClearFilters: onClearFilters,
        onStartSession: onStartSession,
      );
    }

    final groups = groupLearningLogEntries(entries, groupBy);
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        for (final group in groups) ...[
          SliverPersistentHeader(
            pinned: true,
            delegate: _GroupHeaderDelegate(title: group.title),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final entry = group.entries[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LearningLogCard(
                    entry: entry,
                    selected: entry.session.id == selectedId,
                    onTap: () => onOpen(entry),
                    onEdit: () => onEdit(entry),
                    onDelete: () => onDelete(entry),
                  ),
                );
              }, childCount: group.entries.length),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        if (loadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (hasMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: TextButton(
                onPressed: onLoadMore,
                child: const Text('Load earlier months'),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 88)),
      ],
    );
  }
}

class _EmptyLearningLog extends StatelessWidget {
  const _EmptyLearningLog({
    required this.hasFilters,
    required this.onClearFilters,
    required this.onStartSession,
  });

  final bool hasFilters;
  final VoidCallback onClearFilters;
  final VoidCallback onStartSession;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                hasFilters
                    ? 'No sessions match your search or filters.'
                    : 'Your completed sessions and learning notes will appear here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              if (hasFilters)
                FilledButton(
                  onPressed: onClearFilters,
                  child: const Text('Clear Filters'),
                )
              else
                FilledButton.tonal(
                  onPressed: onStartSession,
                  child: const Text('Start a Session'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupHeaderDelegate extends SliverPersistentHeaderDelegate {
  _GroupHeaderDelegate({required this.title});

  final String title;

  @override
  double get minExtent => 40;

  @override
  double get maxExtent => 40;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: overlapsContent ? 1 : 0,
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _GroupHeaderDelegate oldDelegate) =>
      oldDelegate.title != title;
}
