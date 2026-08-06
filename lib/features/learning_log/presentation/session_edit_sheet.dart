import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/learning_log_models.dart';
import 'widgets/markdown_note_editor.dart';
import 'widgets/tag_chip_input.dart';

Future<bool> showSessionEditSheet(
  BuildContext context, {
  required LearningLogEntry entry,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SessionEditSheet(entry: entry),
  );
  return result == true;
}

class SessionEditSheet extends ConsumerStatefulWidget {
  const SessionEditSheet({super.key, required this.entry});

  final LearningLogEntry entry;

  @override
  ConsumerState<SessionEditSheet> createState() => _SessionEditSheetState();
}

class _SessionEditSheetState extends ConsumerState<SessionEditSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late List<String> _tags;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final session = widget.entry.session;
    _titleController = TextEditingController(text: session.title ?? '');
    _noteController = TextEditingController(text: session.noteMarkdown ?? '');
    _tags = widget.entry.tags.map((t) => t.name).toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final result = await ref
        .read(sessionNoteServiceProvider)
        .updateCompletedSession(
          sessionId: widget.entry.session.id,
          title: _titleController.text,
          updateTitle: true,
          noteMarkdown: _noteController.text,
          updateNote: true,
          tagNames: _tags,
        );
    if (!mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(learningLogEntriesProvider);
        Navigator.pop(context, true);
      },
      failure: (f) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(f.message)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
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
                Text(
                  'Edit session',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Title (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                MarkdownNoteEditor(controller: _noteController),
                const SizedBox(height: 16),
                TagChipInput(
                  tags: _tags,
                  onChanged: (next) => setState(() => _tags = next),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
