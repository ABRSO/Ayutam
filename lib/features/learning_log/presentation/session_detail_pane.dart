import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/learning_log_models.dart';
import 'learning_log_format.dart';
import 'session_edit_sheet.dart';
import 'widgets/markdown_note_editor.dart';

class SessionDetailPane extends ConsumerWidget {
  const SessionDetailPane({
    super.key,
    required this.entry,
    this.entries = const [],
    this.onDeleted,
    this.onChanged,
    this.onNavigateTo,
    this.embedded = true,
  });

  final LearningLogEntry entry;
  final List<LearningLogEntry> entries;
  final VoidCallback? onDeleted;
  final VoidCallback? onChanged;
  final ValueChanged<String>? onNavigateTo;
  final bool embedded;

  int get _index => entries.indexWhere((e) => e.session.id == entry.session.id);

  LearningLogEntry? get _prev {
    final i = _index;
    if (i <= 0) return null;
    return entries[i - 1];
  }

  LearningLogEntry? get _next {
    final i = _index;
    if (i < 0 || i >= entries.length - 1) return null;
    return entries[i + 1];
  }

  Future<void> _copyNote(BuildContext context) async {
    final note = entry.session.noteMarkdown?.trim() ?? '';
    if (note.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No note to copy.')));
      return;
    }
    await Clipboard.setData(ClipboardData(text: note));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note copied')));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final sessionId = entry.session.id;
    final result = await ref
        .read(sessionNoteServiceProvider)
        .softDelete(sessionId);
    if (!context.mounted) return;
    await result.when(
      success: (_) async {
        ref.invalidate(learningLogEntriesProvider);
        ref.invalidate(activeSkillsProvider);
        onDeleted?.call();
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
                    ref.invalidate(learningLogEntriesProvider);
                    ref.invalidate(activeSkillsProvider);
                    onChanged?.call();
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = entry.session;
    final accent = entryAccent(entry);
    final prev = _prev;
    final next = _next;

    final body = ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(entry.displayTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          entry.skillName,
          style: theme.textTheme.titleMedium?.copyWith(color: accent),
        ),
        const SizedBox(height: 8),
        Text(
          '${formatSessionDate(session.startAtUtc)} · '
          '${formatSessionTimeRange(session)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${durationLabel(session.activeSeconds)} · '
          '${sessionModeLabel(session.mode)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (entry.tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in entry.tags) Chip(label: Text(tag.name)),
            ],
          ),
        ],
        const SizedBox(height: 24),
        Text('Note', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        MarkdownNotePreview(markdown: session.noteMarkdown ?? ''),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: () async {
                final changed = await showSessionEditSheet(
                  context,
                  entry: entry,
                );
                if (changed) onChanged?.call();
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
            OutlinedButton.icon(
              onPressed: () => _copyNote(context),
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copy note'),
            ),
            OutlinedButton.icon(
              onPressed: () => _delete(context, ref),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ],
        ),
        if (entries.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: prev == null
                      ? null
                      : () {
                          ref
                              .read(
                                selectedLearningLogSessionIdProvider.notifier,
                              )
                              .select(prev.session.id);
                          onNavigateTo?.call(prev.session.id);
                          onChanged?.call();
                        },
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: next == null
                      ? null
                      : () {
                          ref
                              .read(
                                selectedLearningLogSessionIdProvider.notifier,
                              )
                              .select(next.session.id);
                          onNavigateTo?.call(next.session.id);
                          onChanged?.call();
                        },
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Next'),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Session')),
      body: body,
    );
  }
}
