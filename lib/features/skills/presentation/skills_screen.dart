import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/skill_accent_palette.dart';
import '../../../core/time/duration_format.dart';
import '../domain/skill.dart';
import '../../timer/presentation/pre_session_sheet.dart';

class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(activeSkillsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayutam')),
      body: skillsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load skills: $e')),
        data: (skills) {
          if (skills.isEmpty) {
            return const _EmptySkillsState();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: skills.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _SkillCard(skill: skills[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSkillEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Skill'),
        tooltip: 'Create skill',
      ),
    );
  }
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

class _SkillCard extends ConsumerWidget {
  const _SkillCard({required this.skill});

  final Skill skill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = _skillAccent(skill);
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
                        IconButton(
                          tooltip: 'Edit skill',
                          onPressed: () =>
                              _openSkillEditor(context, ref, skill: skill),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Archive skill',
                          onPressed: () =>
                              _archiveWithUndo(context, ref, skill),
                          icon: const Icon(Icons.archive_outlined),
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
                      child: FilledButton.tonalIcon(
                        onPressed: () =>
                            showPreSessionSheet(context, skill: skill),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

Future<void> _openSkillEditor(
  BuildContext context,
  WidgetRef ref, {
  Skill? skill,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _SkillEditorSheet(skill: skill),
  );

  if (saved == true) {
    ref.invalidate(activeSkillsProvider);
  }
}

/// Owns [TextEditingController]s for the lifetime of the sheet so IME/focus
/// teardown cannot notify disposed controllers (common on Android).
class _SkillEditorSheet extends ConsumerStatefulWidget {
  const _SkillEditorSheet({required this.skill});

  final Skill? skill;

  @override
  ConsumerState<_SkillEditorSheet> createState() => _SkillEditorSheetState();
}

class _SkillEditorSheetState extends ConsumerState<_SkillEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _hoursController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _createdDateController;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final skill = widget.skill;
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    _nameController = TextEditingController(text: skill?.name ?? '');
    _hoursController = TextEditingController(
      text: ((skill?.targetSeconds ?? AppConstants.defaultTargetSeconds) / 3600)
          .round()
          .toString(),
    );
    _descriptionController = TextEditingController(
      text: skill?.descriptionMarkdown ?? '',
    );
    _createdDateController = TextEditingController(
      text: skill?.createdLocalDate ?? today,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hoursController.dispose();
    _descriptionController.dispose();
    _createdDateController.dispose();
    super.dispose();
  }

  Future<void> _pickCreatedDate() async {
    final parsed = DateTime.tryParse(_createdDateController.text.trim());
    final initial = parsed ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _createdDateController.text =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _submit() async {
    if (_saving) return;
    final hours = int.tryParse(_hoursController.text.trim());
    if (hours == null || hours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Target hours must be a whole number greater than zero.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final targetSeconds = hours * 3600;
    final service = ref.read(skillServiceProvider);
    final skill = widget.skill;
    final result = skill == null
        ? await service.create(
            name: _nameController.text,
            targetSeconds: targetSeconds,
            descriptionMarkdown: _descriptionController.text,
            createdLocalDate: _createdDateController.text,
          )
        : await service.update(
            id: skill.id,
            name: _nameController.text,
            targetSeconds: targetSeconds,
            descriptionMarkdown: _descriptionController.text,
            createdLocalDate: _createdDateController.text,
          );
    if (!mounted) return;
    result.when(
      success: (_) => Navigator.pop(context, true),
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
    final bottomInset = media.viewInsets.bottom;
    // Match pre-session / completion: short landscape must scroll, not clip.
    final maxHeight = media.size.height * 0.92;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: bottomInset + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.skill == null ? 'New skill' : 'Edit skill',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _hoursController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Target hours',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _createdDateController,
                  readOnly: true,
                  onTap: _pickCreatedDate,
                  decoration: const InputDecoration(
                    labelText: 'Creation date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: Text(widget.skill == null ? 'Create' : 'Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _archiveWithUndo(
  BuildContext context,
  WidgetRef ref,
  Skill skill,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final result = await ref.read(skillServiceProvider).archive(skill.id);
  if (!context.mounted) {
    return;
  }
  await result.when(
    success: (_) async {
      ref.invalidate(activeSkillsProvider);
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
                success: (_) => ref.invalidate(activeSkillsProvider),
                failure: (f) =>
                    messenger.showSnackBar(SnackBar(content: Text(f.message))),
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
