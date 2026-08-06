import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../skills/domain/skill.dart';
import '../domain/learning_log_models.dart';
import '../domain/tag.dart';

Future<void> showLearningLogFiltersSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const LearningLogFiltersSheet(),
  );
}

class LearningLogFiltersSheet extends ConsumerStatefulWidget {
  const LearningLogFiltersSheet({super.key});

  @override
  ConsumerState<LearningLogFiltersSheet> createState() =>
      _LearningLogFiltersSheetState();
}

class _LearningLogFiltersSheetState
    extends ConsumerState<LearningLogFiltersSheet> {
  late LearningLogFilters _draft;
  final _minMinutes = TextEditingController();
  final _maxMinutes = TextEditingController();
  List<Skill> _skills = const [];
  final _selectedTagNames = <String, String>{};

  @override
  void initState() {
    super.initState();
    _draft = ref.read(learningLogFiltersProvider);
    if (_draft.minActiveSeconds != null) {
      _minMinutes.text = (_draft.minActiveSeconds! / 60).round().toString();
    }
    if (_draft.maxActiveSeconds != null) {
      _maxMinutes.text = (_draft.maxActiveSeconds! / 60).round().toString();
    }
    _loadSkills();
  }

  @override
  void dispose() {
    _minMinutes.dispose();
    _maxMinutes.dispose();
    super.dispose();
  }

  Future<void> _loadSkills() async {
    final skills = await ref.read(skillServiceProvider).listActive();
    if (!mounted) return;
    setState(() => _skills = skills);
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.startAfterUtc?.toLocal() ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _draft = _draft.copyWith(
        startAfterUtc: DateTime(picked.year, picked.month, picked.day).toUtc(),
      );
    });
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.endBeforeUtc?.toLocal() ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _draft = _draft.copyWith(
        endBeforeUtc: DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
        ).toUtc(),
      );
    });
  }

  void _apply() {
    final min = int.tryParse(_minMinutes.text.trim());
    final max = int.tryParse(_maxMinutes.text.trim());
    final next = _draft.copyWith(
      minActiveSeconds: min == null ? null : min * 60,
      maxActiveSeconds: max == null ? null : max * 60,
      clearMinActive: min == null,
      clearMaxActive: max == null,
    );
    ref.read(learningLogFiltersProvider.notifier).setFilters(next);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final dateFmt = DateFormat.yMMMd();
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: media.viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Text('Skills', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final skill in _skills)
                      FilterChip(
                        label: Text(skill.name),
                        selected: _draft.skillIds.contains(skill.id),
                        onSelected: (selected) {
                          final next = Set<String>.from(_draft.skillIds);
                          if (selected) {
                            next.add(skill.id);
                          } else {
                            next.remove(skill.id);
                          }
                          setState(
                            () => _draft = _draft.copyWith(skillIds: next),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickStart,
                        child: Text(
                          _draft.startAfterUtc == null
                              ? 'Start date'
                              : dateFmt.format(_draft.startAfterUtc!.toLocal()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _pickEnd,
                        child: Text(
                          _draft.endBeforeUtc == null
                              ? 'End date'
                              : dateFmt.format(_draft.endBeforeUtc!.toLocal()),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_draft.startAfterUtc != null || _draft.endBeforeUtc != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _draft = _draft.copyWith(
                            clearStartAfter: true,
                            clearEndBefore: true,
                          );
                        });
                      },
                      child: const Text('Clear dates'),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minMinutes,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min minutes',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _maxMinutes,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max minutes',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Notes', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<NotePresenceFilter>(
                  segments: const [
                    ButtonSegment(
                      value: NotePresenceFilter.any,
                      label: Text('Any'),
                    ),
                    ButtonSegment(
                      value: NotePresenceFilter.withNotes,
                      label: Text('With'),
                    ),
                    ButtonSegment(
                      value: NotePresenceFilter.withoutNotes,
                      label: Text('Without'),
                    ),
                  ],
                  selected: {_draft.notePresence},
                  onSelectionChanged: (s) {
                    setState(
                      () => _draft = _draft.copyWith(notePresence: s.first),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text('Source', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<SessionSourceFilter>(
                  segments: const [
                    ButtonSegment(
                      value: SessionSourceFilter.any,
                      label: Text('Any'),
                    ),
                    ButtonSegment(
                      value: SessionSourceFilter.timed,
                      label: Text('Timed'),
                    ),
                    ButtonSegment(
                      value: SessionSourceFilter.manual,
                      label: Text('Manual'),
                    ),
                  ],
                  selected: {_draft.sourceFilter},
                  onSelectionChanged: (s) {
                    setState(
                      () => _draft = _draft.copyWith(sourceFilter: s.first),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text('Tags', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Autocomplete<Tag>(
                  displayStringForOption: (t) => t.name,
                  optionsBuilder: (value) async {
                    final prefix = value.text.trim();
                    if (prefix.isEmpty) return const Iterable<Tag>.empty();
                    return ref.read(tagServiceProvider).autocomplete(prefix);
                  },
                  onSelected: (tag) {
                    final next = Set<String>.from(_draft.tagIds)..add(tag.id);
                    _selectedTagNames[tag.id] = tag.name;
                    setState(() => _draft = _draft.copyWith(tagIds: next));
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            hintText: 'Filter by tag',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.label_outline),
                          ),
                        );
                      },
                ),
                if (_draft.tagIds.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final id in _draft.tagIds)
                        InputChip(
                          label: Text(_selectedTagNames[id] ?? id),
                          onDeleted: () {
                            final next = Set<String>.from(_draft.tagIds)
                              ..remove(id);
                            _selectedTagNames.remove(id);
                            setState(
                              () => _draft = _draft.copyWith(tagIds: next),
                            );
                          },
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        ref.read(learningLogFiltersProvider.notifier).clear();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear all'),
                    ),
                    const Spacer(),
                    FilledButton(onPressed: _apply, child: const Text('Apply')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
