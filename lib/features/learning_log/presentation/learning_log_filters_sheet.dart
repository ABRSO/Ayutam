import 'dart:async';

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

  /// Mirrors autocomplete field text so Apply can commit typed tags.
  var _typedTag = '';
  List<Skill> _skills = const [];
  List<Tag> _allTags = const [];

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
    _loadTags();
  }

  @override
  void dispose() {
    _minMinutes.dispose();
    _maxMinutes.dispose();
    super.dispose();
  }

  Future<void> _loadSkills() async {
    final skills = await ref.read(skillServiceProvider).listForJournal();
    if (!mounted) return;
    setState(() => _skills = skills);
  }

  Future<void> _loadTags() async {
    final tags = await ref.read(tagServiceProvider).listAll();
    if (!mounted) return;
    setState(() => _allTags = tags);
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _draft.startAfterUtc?.toLocal() ??
          _draft.overlapStartUtc?.toLocal() ??
          DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _draft = _draft.copyWith(
        startAfterUtc: inclusiveStartOfLocalDay(picked),
        clearOverlap: true,
      );
    });
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.endBeforeUtc == null
          ? (_draft.overlapEndUtc == null
                ? DateTime.now()
                : inclusiveLocalDayForExclusiveEnd(_draft.overlapEndUtc!))
          : inclusiveLocalDayForExclusiveEnd(_draft.endBeforeUtc!),
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _draft = _draft.copyWith(
        endBeforeUtc: exclusiveUtcAfterLocalDay(picked),
        clearOverlap: true,
      );
    });
  }

  Future<void> _commitTypedTag(String raw) async {
    final name = raw.trim();
    if (name.isEmpty) return;
    final tag = await ref.read(tagServiceProvider).findByName(name);
    if (!mounted) return;
    _typedTag = '';
    if (tag == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No tag named "$name" exists yet.')),
      );
      return;
    }
    final next = Set<String>.from(_draft.tagIds)..add(tag.id);
    setState(() => _draft = _draft.copyWith(tagIds: next));
  }

  Future<void> _apply() async {
    final min = int.tryParse(_minMinutes.text.trim());
    final max = int.tryParse(_maxMinutes.text.trim());
    await _commitTypedTag(_typedTag);
    if (!mounted) return;

    final clearOverlap =
        _draft.startAfterUtc != null || _draft.endBeforeUtc != null;
    final next = _draft.copyWith(
      minActiveSeconds: min == null ? null : min * 60,
      maxActiveSeconds: max == null ? null : max * 60,
      clearMinActive: min == null,
      clearMaxActive: max == null,
      clearOverlap: clearOverlap,
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
            bottom: media.viewInsets.bottom + 16,
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
                        label: Text(
                          skill.status == SkillStatus.archived
                              ? '${skill.name} (archived)'
                              : skill.name,
                        ),
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
                              : dateFmt.format(
                                  inclusiveLocalDayForExclusiveEnd(
                                    _draft.endBeforeUtc!,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
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
                if (_allTags.isEmpty)
                  Text(
                    'No tags yet. Add tags when saving a session, then filter here.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in _allTags)
                        FilterChip(
                          label: Text(tag.name),
                          selected: _draft.tagIds.contains(tag.id),
                          onSelected: (selected) {
                            final next = Set<String>.from(_draft.tagIds);
                            if (selected) {
                              next.add(tag.id);
                            } else {
                              next.remove(tag.id);
                            }
                            setState(
                              () => _draft = _draft.copyWith(tagIds: next),
                            );
                          },
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
                Autocomplete<Tag>(
                  displayStringForOption: (t) => t.name,
                  optionsBuilder: (value) async {
                    return ref
                        .read(tagServiceProvider)
                        .autocomplete(value.text.trim());
                  },
                  onSelected: (tag) {
                    final next = Set<String>.from(_draft.tagIds)..add(tag.id);
                    setState(() {
                      _draft = _draft.copyWith(tagIds: next);
                      _typedTag = '';
                    });
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            hintText: 'Type a tag name',
                            helperText:
                                'Pick a chip, choose a suggestion, or Apply typed text',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.label_outline),
                          ),
                          onChanged: (text) => _typedTag = text,
                          onSubmitted: (value) async {
                            await _commitTypedTag(value);
                            controller.clear();
                            onFieldSubmitted();
                          },
                        );
                      },
                ),
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
                    FilledButton(
                      onPressed: () => unawaited(_apply()),
                      child: const Text('Apply'),
                    ),
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
