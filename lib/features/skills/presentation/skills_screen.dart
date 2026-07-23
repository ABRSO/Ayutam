import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(skill.name, style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  tooltip: 'Edit skill',
                  onPressed: () => _openSkillEditor(context, ref, skill: skill),
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
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: skill.progressFraction),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () => showPreSessionSheet(context, skill: skill),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openSkillEditor(
  BuildContext context,
  WidgetRef ref, {
  Skill? skill,
}) async {
  final nameController = TextEditingController(text: skill?.name ?? '');
  final hoursController = TextEditingController(
    text: ((skill?.targetSeconds ?? AppConstants.defaultTargetSeconds) / 3600)
        .round()
        .toString(),
  );

  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 8,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              skill == null ? 'New skill' : 'Edit skill',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hoursController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target hours',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final name = nameController.text;
                final hours = int.tryParse(hoursController.text.trim());
                final targetSeconds =
                    (hours ?? AppConstants.defaultTargetHours) * 3600;
                final service = ref.read(skillServiceProvider);
                final result = skill == null
                    ? await service.create(
                        name: name,
                        targetSeconds: targetSeconds,
                      )
                    : await service.update(
                        id: skill.id,
                        name: name,
                        targetSeconds: targetSeconds,
                      );
                if (!context.mounted) {
                  return;
                }
                result.when(
                  success: (_) => Navigator.pop(context, true),
                  failure: (f) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(f.message)));
                  },
                );
              },
              child: Text(skill == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      );
    },
  );

  nameController.dispose();
  hoursController.dispose();
  if (saved == true) {
    ref.invalidate(activeSkillsProvider);
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
