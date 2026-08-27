import 'package:flutter/material.dart';

import '../domain/backup_models.dart';

/// Result of the import preview confirmation sheet.
final class ImportPreviewChoice {
  const ImportPreviewChoice({
    required this.mode,
    this.conflictResolution = ConflictResolution.keepCurrent,
    this.perItem = const {},
    this.activeDecision,
    this.reviewedEndUtc,
    this.restoreActiveTimer = false,
  });

  final ImportMode mode;
  final ConflictResolution conflictResolution;
  final Map<String, ConflictResolution> perItem;
  final ActiveSessionDecision? activeDecision;
  final DateTime? reviewedEndUtc;

  /// When there is no active-session collision: restore a live timer from the
  /// backup (replace / merge with idle local).
  final bool restoreActiveTimer;
}

/// Preview summary with Merge / Replace and conflict / active-session choices.
Future<ImportPreviewChoice?> showImportPreviewSheet(
  BuildContext context, {
  required ImportPreview preview,
}) {
  return showModalBottomSheet<ImportPreviewChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => ImportPreviewSheet(preview: preview),
  );
}

class ImportPreviewSheet extends StatefulWidget {
  const ImportPreviewSheet({super.key, required this.preview});

  final ImportPreview preview;

  @override
  State<ImportPreviewSheet> createState() => _ImportPreviewSheetState();
}

class _ImportPreviewSheetState extends State<ImportPreviewSheet> {
  var _restoreActiveTimer = false;
  var _conflictResolution = ConflictResolution.keepCurrent;
  ActiveSessionDecision? _activeDecision;
  DateTime? _reviewedEndUtc;

  ImportPreview get preview => widget.preview;

  bool get _hasCollision => preview.activeSessionCollision != null;

  bool get _canMerge {
    if (!_hasCollision) return true;
    if (_activeDecision == null) return false;
    if (_activeDecision == ActiveSessionDecision.cancel) return true;
    if (_activeDecision == ActiveSessionDecision.completeOtherWithEnd) {
      return _reviewedEndUtc != null;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _reviewedEndUtc = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final summary = preview.manifest.summary;
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final showRestoreCheckbox =
        !_hasCollision &&
        (preview.localHasActiveOrPending ||
            summary.containsActiveOrPendingSession);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Import preview', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              preview.fileName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${summary.skills} skills · ${summary.sessions} sessions · '
              '${summary.tags} tags',
              style: theme.textTheme.bodyLarge,
            ),
            Text(
              'Completed practice: ${_formatSeconds(summary.completedActiveSeconds)}',
              style: theme.textTheme.bodyMedium,
            ),
            if (preview.conflicts.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Equal-timestamp conflicts',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                '${preview.conflicts.length} item(s) share the same update time '
                'but differ. Choose which side wins for merge:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<ConflictResolution>(
                segments: const [
                  ButtonSegment(
                    value: ConflictResolution.keepCurrent,
                    label: Text('Keep current'),
                  ),
                  ButtonSegment(
                    value: ConflictResolution.preferImported,
                    label: Text('Prefer imported'),
                  ),
                ],
                selected: {_conflictResolution},
                onSelectionChanged: (s) {
                  setState(() => _conflictResolution = s.first);
                },
              ),
              const SizedBox(height: 8),
              ...preview.conflicts.take(8).map((c) {
                final label = c.label ?? c.id;
                return Text(
                  '· ${c.entityType}: $label',
                  style: theme.textTheme.bodySmall,
                );
              }),
              if (preview.conflicts.length > 8)
                Text(
                  '· …and ${preview.conflicts.length - 8} more',
                  style: theme.textTheme.bodySmall,
                ),
            ],
            if (_hasCollision) ...[
              const SizedBox(height: 16),
              Text(
                'Active session conflict',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Both this device and the backup have an in-progress session. '
                'Choose how to resolve before merging.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              RadioGroup<ActiveSessionDecision>(
                groupValue: _activeDecision,
                onChanged: (v) => setState(() => _activeDecision = v),
                child: const Column(
                  children: [
                    RadioListTile<ActiveSessionDecision>(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Keep current'),
                      subtitle: Text('Keep the session on this device'),
                      value: ActiveSessionDecision.keepCurrent,
                    ),
                    RadioListTile<ActiveSessionDecision>(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Prefer imported'),
                      subtitle: Text('Use the session from the backup'),
                      value: ActiveSessionDecision.preferImported,
                    ),
                    RadioListTile<ActiveSessionDecision>(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Complete imported with reviewed end'),
                      subtitle: Text(
                        'Keep current; mark the imported session completed',
                      ),
                      value: ActiveSessionDecision.completeOtherWithEnd,
                    ),
                    RadioListTile<ActiveSessionDecision>(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Cancel'),
                      subtitle: Text('Do not import'),
                      value: ActiveSessionDecision.cancel,
                    ),
                  ],
                ),
              ),
              if (_activeDecision ==
                  ActiveSessionDecision.completeOtherWithEnd) ...[
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reviewed end time'),
                  subtitle: Text(
                    _reviewedEndUtc == null
                        ? 'Tap to pick'
                        : _reviewedEndUtc!.toLocal().toString(),
                  ),
                  trailing: const Icon(Icons.event),
                  onTap: () => _pickReviewedEnd(context),
                ),
              ],
            ],
            if (showRestoreCheckbox) ...[
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Restore active timer from backup'),
                subtitle: Text(
                  preview.localHasActiveOrPending
                      ? 'You have an in-progress session. Restoring a timer '
                            'from the backup can replace it.'
                      : 'The backup contains an active or pending session.',
                  style: theme.textTheme.bodySmall,
                ),
                value: _restoreActiveTimer,
                onChanged: (v) =>
                    setState(() => _restoreActiveTimer = v ?? false),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _canMerge
                  ? () => Navigator.pop(
                      context,
                      ImportPreviewChoice(
                        mode: ImportMode.merge,
                        conflictResolution: _conflictResolution,
                        activeDecision: _activeDecision,
                        reviewedEndUtc:
                            _activeDecision ==
                                ActiveSessionDecision.completeOtherWithEnd
                            ? _reviewedEndUtc
                            : null,
                        restoreActiveTimer: _restoreActiveTimer,
                      ),
                    )
                  : null,
              child: const Text('Merge'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(
                context,
                ImportPreviewChoice(
                  mode: ImportMode.replace,
                  conflictResolution: _conflictResolution,
                  activeDecision: _activeDecision,
                  reviewedEndUtc:
                      _activeDecision ==
                          ActiveSessionDecision.completeOtherWithEnd
                      ? _reviewedEndUtc
                      : null,
                  restoreActiveTimer: _restoreActiveTimer,
                ),
              ),
              child: const Text('Replace all local data'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReviewedEnd(BuildContext context) async {
    final now = _reviewedEndUtc ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null || !context.mounted) return;
    setState(() {
      _reviewedEndUtc = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  static String _formatSeconds(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
