import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../skills/domain/skill.dart';
import 'widgets/markdown_note_editor.dart';
import 'widgets/tag_chip_input.dart';

Future<bool> showManualSessionSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const ManualSessionSheet(),
  );
  return result == true;
}

class ManualSessionSheet extends ConsumerStatefulWidget {
  const ManualSessionSheet({super.key});

  @override
  ConsumerState<ManualSessionSheet> createState() => _ManualSessionSheetState();
}

class _ManualSessionSheetState extends ConsumerState<ManualSessionSheet> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _tagInputController = TagChipInputController();
  var _tags = <String>[];
  List<Skill> _skills = const [];
  String? _skillId;
  late DateTime _startLocal;
  late DateTime _endLocal;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endLocal = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    _startLocal = _endLocal.subtract(const Duration(hours: 1));
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
    final skills = await ref.read(skillServiceProvider).listActive();
    if (!mounted) return;
    setState(() {
      _skills = skills;
      _skillId ??= skills.isEmpty ? null : skills.first.id;
    });
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit({bool allowOverlap = false}) async {
    if (_saving) return;
    final skillId = _skillId;
    if (skillId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a skill before adding a session.'),
        ),
      );
      return;
    }
    if (!_endLocal.isAfter(_startLocal)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    setState(() => _saving = true);
    final tags = _tagInputController.commitPending();
    _tags = tags;
    final offset = _startLocal.timeZoneOffset.inMinutes;
    final result = await ref
        .read(sessionNoteServiceProvider)
        .createManualSession(
          skillId: skillId,
          startAtUtc: _startLocal.toUtc(),
          endAtUtc: _endLocal.toUtc(),
          title: _titleController.text,
          noteMarkdown: _noteController.text,
          tagNames: tags,
          allowOverlap: allowOverlap,
          timezoneId: _startLocal.timeZoneName,
          offsetMinutes: offset,
        );

    if (!mounted) return;
    await result.when(
      success: (manual) async {
        if (manual.needsOverlapConfirm) {
          setState(() => _saving = false);
          final ok = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Overlapping session'),
              content: Text(
                'This time overlaps ${manual.overlaps.length} other '
                'session(s) for this skill. Save anyway?',
              ),
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
            await _submit(allowOverlap: true);
          }
          return;
        }
        ref.invalidate(learningLogEntriesProvider);
        ref.invalidate(activeSkillsProvider);
        Navigator.pop(context, true);
      },
      failure: (f) async {
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
                  'Manual session',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _skillId,
                  decoration: const InputDecoration(
                    labelText: 'Skill',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final skill in _skills)
                      DropdownMenuItem(
                        value: skill.id,
                        child: Text(skill.name),
                      ),
                  ],
                  onChanged: _skills.isEmpty
                      ? null
                      : (id) => setState(() => _skillId = id),
                ),
                const SizedBox(height: 12),
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
                  onPressed: _saving ? null : _submit,
                  child: const Text('Save session'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
