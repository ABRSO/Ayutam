import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../skills/domain/skill.dart';
import '../domain/learning_log_models.dart';
import 'session_time_picker.dart';
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
  final _tagInputController = TagChipInputController();
  late List<String> _tags;
  List<Skill> _skills = const [];
  late String _skillId;
  late DateTime _startLocal;
  late DateTime _endLocal;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final session = widget.entry.session;
    _titleController = TextEditingController(text: session.title ?? '');
    _noteController = TextEditingController(text: session.noteMarkdown ?? '');
    _tags = widget.entry.tags.map((t) => t.name).toList();
    _skillId = session.skillId;
    _startLocal = session.startAtUtc.toLocal();
    _endLocal = (session.endAtUtc ?? session.startAtUtc).toLocal();
    _loadSkills();
  }

  @override
  void dispose() {
    _tagInputController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadSkills() async {
    final skills = await ref.read(skillServiceProvider).listForJournal();
    if (!mounted) return;
    setState(() => _skills = skills);
  }

  bool get _timesOrSkillChanged {
    final session = widget.entry.session;
    final originalEnd = (session.endAtUtc ?? session.startAtUtc).toLocal();
    return _skillId != session.skillId ||
        _startLocal != session.startAtUtc.toLocal() ||
        _endLocal != originalEnd;
  }

  Future<DateTime?> _pickDateTime(DateTime initial) {
    return pickCompletedSessionDateTime(context, initial);
  }

  Future<void> _save({bool allowOverlap = false}) async {
    if (_saving) return;
    if (!_endLocal.isAfter(_startLocal)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }
    if (sessionLocalTimesAreInTheFuture(_startLocal, _endLocal)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session times cannot be in the future.')),
      );
      return;
    }
    if (_timesOrSkillChanged && !allowOverlap) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update totals?'),
          content: const Text(
            'Changing the skill or session times updates practice totals '
            'and statistics. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _saving = true);
    final tags = _tagInputController.commitPending();
    _tags = tags;
    final session = widget.entry.session;
    final originalEnd = (session.endAtUtc ?? session.startAtUtc).toLocal();
    final timesChanged =
        _startLocal != session.startAtUtc.toLocal() || _endLocal != originalEnd;
    final skillChanged = _skillId != session.skillId;
    final result = await ref
        .read(sessionNoteServiceProvider)
        .updateCompletedSession(
          sessionId: session.id,
          skillId: skillChanged ? _skillId : null,
          title: _titleController.text,
          updateTitle: true,
          noteMarkdown: _noteController.text,
          updateNote: true,
          tagNames: tags,
          startAtUtc: timesChanged ? _startLocal.toUtc() : null,
          endAtUtc: timesChanged ? _endLocal.toUtc() : null,
          allowOverlap: allowOverlap,
        );
    if (!mounted) return;
    await result.when(
      success: (_) async {
        ref.invalidate(learningLogListProvider);
        ref.invalidate(activeSkillsProvider);
        Navigator.pop(context, true);
      },
      failure: (f) async {
        setState(() => _saving = false);
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
            await _save(allowOverlap: true);
          }
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(f.message)));
      },
    );
  }

  Future<void> _onSavePressed() => _save();

  String _skillLabel(Skill skill) {
    if (skill.status == SkillStatus.archived) {
      return '${skill.name} (archived)';
    }
    return skill.name;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final fmt = DateFormat.yMMMd().add_jm();
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
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _skills.any((s) => s.id == _skillId) ? _skillId : null,
                  decoration: const InputDecoration(
                    labelText: 'Skill',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final skill in _skills)
                      DropdownMenuItem(
                        value: skill.id,
                        child: Text(_skillLabel(skill)),
                      ),
                  ],
                  onChanged: _skills.isEmpty
                      ? null
                      : (id) {
                          if (id != null) setState(() => _skillId = id);
                        },
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start'),
                  subtitle: Text(fmt.format(_startLocal)),
                  trailing: const Icon(Icons.schedule),
                  onTap: () async {
                    final picked = await _pickDateTime(_startLocal);
                    if (picked != null) setState(() => _startLocal = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('End'),
                  subtitle: Text(fmt.format(_endLocal)),
                  trailing: const Icon(Icons.schedule),
                  onTap: () async {
                    final picked = await _pickDateTime(_endLocal);
                    if (picked != null) setState(() => _endLocal = picked);
                  },
                ),
                const SizedBox(height: 8),
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
                  controller: _tagInputController,
                  tags: _tags,
                  onChanged: (next) => setState(() => _tags = next),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _onSavePressed,
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
