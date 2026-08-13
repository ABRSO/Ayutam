import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/skill_accent_palette.dart';
import '../domain/skill.dart';

Future<bool> showSkillEditorSheet(BuildContext context, {Skill? skill}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _SkillEditorSheet(skill: skill),
  );
  return saved == true;
}

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
  late int _accentArgb;
  var _saving = false;
  var _defaultedAccent = false;

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
    _accentArgb = skill?.accentArgb ?? 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_defaultedAccent || widget.skill != null) {
      return;
    }
    _defaultedAccent = true;
    final existing = ref.read(allSkillsProvider).asData?.value ?? const [];
    _accentArgb = SkillAccentPalette.toArgb(
      SkillAccentPalette.nextAccent(existing.map((s) => s.accentArgb)),
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

  Future<void> _submit({bool allowDuplicateName = false}) async {
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
            accentArgb: _accentArgb,
            allowDuplicateName: allowDuplicateName,
          )
        : await service.update(
            id: skill.id,
            name: _nameController.text,
            targetSeconds: targetSeconds,
            descriptionMarkdown: _descriptionController.text,
            createdLocalDate: _createdDateController.text,
            accentArgb: _accentArgb,
            allowDuplicateName: allowDuplicateName,
          );
    if (!mounted) return;
    final failure = result.when(success: (_) => null, failure: (f) => f);
    if (failure == null) {
      Navigator.pop(context, true);
      return;
    }
    if (failure.code == 'SKILL-DUP-NAME') {
      setState(() => _saving = false);
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Duplicate name'),
          content: Text(failure.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (proceed == true && mounted) {
        await _submit(allowDuplicateName: true);
      }
      return;
    }
    setState(() => _saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failure.message)));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
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
                Text(
                  'Accent colour',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < SkillAccentPalette.colors.length; i++)
                      _AccentSwatch(
                        color: SkillAccentPalette.colors[i],
                        selected:
                            _accentArgb ==
                            SkillAccentPalette.toArgb(
                              SkillAccentPalette.colors[i],
                            ),
                        semanticLabel: 'Accent colour ${i + 1}',
                        onTap: () {
                          setState(() {
                            _accentArgb = SkillAccentPalette.toArgb(
                              SkillAccentPalette.colors[i],
                            );
                          });
                        },
                      ),
                  ],
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

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.color,
    required this.selected,
    required this.semanticLabel,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: Material(
        color: color,
        shape: CircleBorder(
          side: BorderSide(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: 3,
          ),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: selected
                ? Icon(
                    Icons.check,
                    color: color.computeLuminance() < 0.5
                        ? Colors.white
                        : Colors.black,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
