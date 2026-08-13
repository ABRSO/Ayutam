import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/ayutam_app.dart';
import '../../../app/app_shell.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/time/duration_format.dart';
import '../../learning_log/presentation/learning_log_format.dart';
import '../../learning_log/presentation/session_time_picker.dart';
import '../../learning_log/presentation/widgets/markdown_note_editor.dart';
import '../../learning_log/presentation/widgets/tag_chip_input.dart';
import '../../timer/domain/models.dart';
import 'timer_screen.dart';

enum _NoteSaveStatus { idle, saving, saved, failed }

class CompletionScreen extends ConsumerStatefulWidget {
  const CompletionScreen({super.key, this.skillId});

  final String? skillId;

  @override
  ConsumerState<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends ConsumerState<CompletionScreen> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _tagInputController = TagChipInputController();
  final _titleFocus = FocusNode();
  final _noteFocus = FocusNode();
  var _tags = <String>[];
  var _initialized = false;
  var _skillName = 'Skill';
  var _saveStatus = _NoteSaveStatus.idle;
  Timer? _debounce;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _titleFocus.addListener(_onFocusChange);
    _noteFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleFocus.removeListener(_onFocusChange);
    _noteFocus.removeListener(_onFocusChange);
    final tags = _tagInputController.commitPending(notify: false);
    final id = _sessionId;
    if (id != null) {
      unawaited(
        ref
            .read(sessionNoteServiceProvider)
            .updateDraft(
              sessionId: id,
              title: _titleController.text,
              updateTitle: true,
              noteMarkdown: _noteController.text,
              updateNote: true,
              tagNames: tags,
            ),
      );
    }
    _tagInputController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    _titleFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_titleFocus.hasFocus && !_noteFocus.hasFocus) {
      final id = _sessionId;
      if (id != null) {
        unawaited(_flushSave(id));
      }
    }
  }

  Future<void> _ensureInitialized(PracticeSession session) async {
    if (_initialized && _sessionId == session.id) return;
    _sessionId = session.id;
    _titleController.text = session.title ?? '';
    _noteController.text = session.noteMarkdown ?? '';
    final skill = await ref
        .read(skillRepositoryProvider)
        .findById(session.skillId);
    final tags = await ref
        .read(sessionNoteServiceProvider)
        .tagsForSession(session.id);
    if (!mounted) return;
    setState(() {
      _skillName = skill?.name ?? 'Unknown skill';
      _tags = tags.map((t) => t.name).toList();
      _initialized = true;
    });
  }

  void _scheduleSave() {
    final id = _sessionId;
    if (id == null) return;
    _debounce?.cancel();
    _debounce = Timer(AppConstants.noteAutosaveDebounce, () {
      unawaited(_flushSave(id));
    });
  }

  Future<bool> _flushSave(String sessionId) async {
    _debounce?.cancel();
    // Typed text in the tag field is not a chip until committed.
    final tags = _tagInputController.commitPending();
    _tags = tags;
    if (!mounted) {
      final result = await ref
          .read(sessionNoteServiceProvider)
          .updateDraft(
            sessionId: sessionId,
            title: _titleController.text,
            updateTitle: true,
            noteMarkdown: _noteController.text,
            updateNote: true,
            tagNames: tags,
          );
      return result.isSuccess;
    }
    setState(() => _saveStatus = _NoteSaveStatus.saving);
    final result = await ref
        .read(sessionNoteServiceProvider)
        .updateDraft(
          sessionId: sessionId,
          title: _titleController.text,
          updateTitle: true,
          noteMarkdown: _noteController.text,
          updateNote: true,
          tagNames: tags,
        );
    if (!mounted) return result.isSuccess;
    setState(() {
      _saveStatus = result.isSuccess
          ? _NoteSaveStatus.saved
          : _NoteSaveStatus.failed;
    });
    return result.isSuccess;
  }

  Future<void> _editTimes(PracticeSession session) async {
    final start = await pickCompletedSessionDateTime(
      context,
      session.startAtUtc.toLocal(),
    );
    if (start == null || !mounted) return;
    final end = await pickCompletedSessionDateTime(
      context,
      (session.endAtUtc ?? session.startAtUtc).toLocal(),
    );
    if (end == null || !mounted) return;
    if (!end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }
    await _applyTimes(
      sessionId: session.id,
      startAtUtc: start.toUtc(),
      endAtUtc: end.toUtc(),
    );
  }

  Future<void> _applyTimes({
    required String sessionId,
    required DateTime startAtUtc,
    required DateTime endAtUtc,
    bool allowOverlap = false,
  }) async {
    final result = await ref
        .read(sessionNoteServiceProvider)
        .updateCompletedSession(
          sessionId: sessionId,
          startAtUtc: startAtUtc,
          endAtUtc: endAtUtc,
          allowOverlap: allowOverlap,
        );
    if (!mounted) return;
    await result.when(
      success: (_) async {
        await ref.read(timerSessionProvider.notifier).refresh();
      },
      failure: (f) async {
        if (f.code == 'SESS-OVERLAP') {
          final ok = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Overlapping session'),
              content: Text('${f.message} Save anyway?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save anyway'),
                ),
              ],
            ),
          );
          if (ok == true && mounted) {
            await _applyTimes(
              sessionId: sessionId,
              startAtUtc: startAtUtc,
              endAtUtc: endAtUtc,
              allowOverlap: true,
            );
          }
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(f.message)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapAsync = ref.watch(timerSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Session complete')),
      body: snapAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (snap) {
          final session = snap.session;
          final seconds = session?.activeSeconds ?? snap.displayActiveSeconds;
          if (session != null) {
            unawaited(_ensureInitialized(session));
          }
          return CompletionBody(
            activeSeconds: seconds,
            pausedSeconds: session?.pausedSeconds ?? 0,
            skillName: session == null ? null : _skillName,
            dateLabel: session == null
                ? null
                : formatSessionDate(session.startAtUtc),
            timeRangeLabel: session == null
                ? null
                : formatSessionTimeRange(session),
            modeLabel: session == null ? null : sessionModeLabel(session.mode),
            titleField: session == null
                ? null
                : TextField(
                    controller: _titleController,
                    focusNode: _titleFocus,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Title (optional)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _scheduleSave(),
                  ),
            noteEditor: session == null
                ? null
                : MarkdownNoteEditor(
                    controller: _noteController,
                    focusNode: _noteFocus,
                    onChanged: (_) => _scheduleSave(),
                    onEditingComplete: () {
                      final id = _sessionId;
                      if (id != null) unawaited(_flushSave(id));
                    },
                  ),
            tagInput: session == null
                ? null
                : TagChipInput(
                    controller: _tagInputController,
                    tags: _tags,
                    onChanged: (next) {
                      setState(() => _tags = next);
                      _scheduleSave();
                    },
                  ),
            saveStatus: session == null
                ? null
                : _SaveStatusRow(
                    status: _saveStatus,
                    onRetry: () {
                      final id = _sessionId;
                      if (id != null) unawaited(_flushSave(id));
                    },
                  ),
            onEditTime: session == null ? null : () => _editTimes(session),
            onSave: () async {
              final id = _sessionId;
              if (id != null) {
                final saved = await _flushSave(id);
                if (!saved) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not save the note. The session was not completed.',
                      ),
                    ),
                  );
                  return;
                }
              }
              final error = await ref
                  .read(timerSessionProvider.notifier)
                  .saveCompletion();
              if (!context.mounted) return;
              if (error != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error)));
                return;
              }
              ref.invalidate(activeSkillsProvider);
              ref.invalidate(learningLogListProvider);
              await _goHome(context, ref);
            },
            onResume: () async {
              final id = _sessionId;
              if (id != null) {
                final saved = await _flushSave(id);
                if (!saved) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not save the note. Resume was not started.',
                      ),
                    ),
                  );
                  return;
                }
              }
              final error = await ref
                  .read(timerSessionProvider.notifier)
                  .resumeFromCompletion();
              if (!context.mounted) return;
              if (error != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error)));
                return;
              }
              await Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => TimerScreen(skillId: widget.skillId),
                ),
              );
            },
            onDiscard: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Discard session?'),
                  content: const Text(
                    'This deletes the session and its segments. '
                    'This cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              );
              if (ok != true || !context.mounted) return;
              final error = await ref
                  .read(timerSessionProvider.notifier)
                  .discardCompletion();
              if (!context.mounted) return;
              if (error != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error)));
                return;
              }
              await _goHome(context, ref);
            },
          );
        },
      ),
    );
  }
}

class _SaveStatusRow extends StatelessWidget {
  const _SaveStatusRow({required this.status, required this.onRetry});

  final _NoteSaveStatus status;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case _NoteSaveStatus.idle:
        return const SizedBox.shrink();
      case _NoteSaveStatus.saving:
        return Text(
          'Saving…',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
      case _NoteSaveStatus.saved:
        return Text(
          'Saved locally',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        );
      case _NoteSaveStatus.failed:
        return Row(
          children: [
            Expanded(
              child: Text(
                'Save failed',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        );
    }
  }
}

/// Scroll-safe completion content; extractable for viewport widget tests.
class CompletionBody extends StatelessWidget {
  const CompletionBody({
    super.key,
    required this.activeSeconds,
    required this.onSave,
    required this.onResume,
    required this.onDiscard,
    this.pausedSeconds = 0,
    this.skillName,
    this.dateLabel,
    this.timeRangeLabel,
    this.modeLabel,
    this.titleField,
    this.noteEditor,
    this.tagInput,
    this.saveStatus,
    this.onEditTime,
  });

  final int activeSeconds;
  final int pausedSeconds;
  final VoidCallback onSave;
  final VoidCallback onResume;
  final VoidCallback onDiscard;
  final String? skillName;
  final String? dateLabel;
  final String? timeRangeLabel;
  final String? modeLabel;
  final Widget? titleField;
  final Widget? noteEditor;
  final Widget? tagInput;
  final Widget? saveStatus;
  final VoidCallback? onEditTime;

  bool get _expanded =>
      skillName != null ||
      titleField != null ||
      noteEditor != null ||
      tagInput != null;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Padding lives inside the ConstrainedBox so the scrollable extent
        // equals the viewport when content fits; scrolling only kicks in
        // when the content genuinely cannot fit (e.g. short landscape).
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_expanded) const Spacer(),
                    if (_expanded) ...[
                      _SummaryCard(
                        skillName: skillName ?? 'Skill',
                        dateLabel: dateLabel ?? '',
                        timeRangeLabel: timeRangeLabel ?? '',
                        modeLabel: modeLabel ?? '',
                        activeSeconds: activeSeconds,
                        pausedSeconds: pausedSeconds,
                      ),
                      if (onEditTime != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: onEditTime,
                            icon: const Icon(Icons.schedule_outlined),
                            label: const Text('Edit Time'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (titleField != null) ...[
                        titleField!,
                        const SizedBox(height: 16),
                      ],
                      if (noteEditor != null) ...[
                        noteEditor!,
                        const SizedBox(height: 16),
                      ],
                      if (tagInput != null) ...[
                        tagInput!,
                        const SizedBox(height: 12),
                      ],
                      if (saveStatus != null) ...[
                        saveStatus!,
                        const SizedBox(height: 16),
                      ],
                    ] else ...[
                      Text(
                        'Active practice',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatActiveDuration(activeSeconds),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              fontFamily: 'monospace',
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (!_expanded) const Spacer(),
                    FilledButton(
                      onPressed: onSave,
                      child: const Text('Save Session'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: onResume,
                      child: const Text('Resume'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onDiscard,
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.skillName,
    required this.dateLabel,
    required this.timeRangeLabel,
    required this.modeLabel,
    required this.activeSeconds,
    required this.pausedSeconds,
  });

  final String skillName;
  final String dateLabel;
  final String timeRangeLabel;
  final String modeLabel;
  final int activeSeconds;
  final int pausedSeconds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(skillName, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              dateLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              timeRangeLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Active ${formatActiveDuration(activeSeconds)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: 'monospace',
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Paused ${formatActiveDuration(pausedSeconds)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: 'monospace',
                fontFeatures: const [FontFeature.tabularFigures()],
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              modeLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _goHome(BuildContext context, WidgetRef ref) async {
  ref.invalidate(startupGateProvider);
  final nav = ayutamNavigatorKey.currentState;
  if (nav != null) {
    await nav.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AppShell()),
      (_) => false,
    );
  } else if (context.mounted) {
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AppShell()),
      (_) => false,
    );
  }
}
