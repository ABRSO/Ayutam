import 'package:flutter/material.dart';
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
                          onPressed: () => _confirmArchive(context, ref, skill),
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
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: skill.progressFraction,
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
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final skill = widget.skill;
    _nameController = TextEditingController(text: skill?.name ?? '');
    _hoursController = TextEditingController(
      text: ((skill?.targetSeconds ?? AppConstants.defaultTargetSeconds) / 3600)
          .round()
          .toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    final name = _nameController.text;
    final hours = int.tryParse(_hoursController.text.trim());
    final targetSeconds = (hours ?? AppConstants.defaultTargetHours) * 3600;
    final service = ref.read(skillServiceProvider);
    final skill = widget.skill;
    final result = skill == null
        ? await service.create(name: name, targetSeconds: targetSeconds)
        : await service.update(
            id: skill.id,
            name: name,
            targetSeconds: targetSeconds,
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
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
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hoursController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target hours',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(widget.skill == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmArchive(
  BuildContext context,
  WidgetRef ref,
  Skill skill,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Archive skill?'),
      content: Text(
        '"${skill.name}" will be hidden from the home list. '
        'Completed practice totals are kept.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Archive'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) {
    return;
  }
  final result = await ref.read(skillServiceProvider).archive(skill.id);
  result.when(
    success: (_) => ref.invalidate(activeSkillsProvider),
    failure: (f) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(f.message)));
    },
  );
}
