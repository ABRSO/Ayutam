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
  final Map<String, ConflictResolution> _perItem = {};
  final Set<String> _expandedConflicts = {};
  ActiveSessionDecision? _activeDecision;
  DateTime? _reviewedEndUtc;

  ImportPreview get preview => widget.preview;

  bool get _hasCollision => preview.activeSessionCollision != null;

  bool get _sameSessionCollision =>
      preview.activeSessionCollision?.sameSessionId ?? false;

  bool get _canMerge {
    if (!_hasCollision) return true;
    if (_activeDecision == null) return false;
    if (_activeDecision == ActiveSessionDecision.cancel) return true;
    if (_activeDecision == ActiveSessionDecision.completeOtherWithEnd) {
      if (_sameSessionCollision) return false;
      return _reviewedEndUtc != null && !_reviewedEndIsFuture;
    }
    return true;
  }

  bool get _reviewedEndIsFuture {
    final end = _reviewedEndUtc;
    if (end == null) return false;
    return end.isAfter(DateTime.now());
  }

  @override
  void initState() {
    super.initState();
    _reviewedEndUtc = DateTime.now();
  }

  ConflictResolution _resolutionFor(ImportConflict conflict) {
    return _perItem[_conflictKey(conflict)] ?? _conflictResolution;
  }

  void _applyGlobalConflictResolution(ConflictResolution resolution) {
    setState(() {
      _conflictResolution = resolution;
      for (final conflict in preview.conflicts) {
        _perItem[_conflictKey(conflict)] = resolution;
      }
    });
  }

  void _setPerItemResolution(
    ImportConflict conflict,
    ConflictResolution value,
  ) {
    setState(() => _perItem[_conflictKey(conflict)] = value);
  }

  ImportPreviewChoice _buildChoice(ImportMode mode) {
    return ImportPreviewChoice(
      mode: mode,
      conflictResolution: _conflictResolution,
      perItem: Map.unmodifiable(_perItem),
      activeDecision: _activeDecision,
      reviewedEndUtc:
          _activeDecision == ActiveSessionDecision.completeOtherWithEnd
          ? _reviewedEndUtc
          : null,
      restoreActiveTimer: _restoreActiveTimer,
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = preview.manifest.summary;
    final manifest = preview.manifest;
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
            Text('Backup details', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _MetadataRow(
              label: 'Created',
              value: _formatCreatedDate(manifest.createdAtUtc),
            ),
            _MetadataRow(
              label: 'App version',
              value: manifest.applicationVersion.isEmpty
                  ? 'Unknown'
                  : manifest.applicationVersion,
            ),
            _MetadataRow(
              label: 'Format version',
              value: '${manifest.formatVersion}',
            ),
            _MetadataRow(
              label: 'Device',
              value: _shortDeviceId(manifest.sourceDeviceId),
            ),
            _MetadataRow(
              label: 'Checksum',
              value: preview.checksumOk ? 'Verified' : 'Failed',
            ),
            _MetadataRow(
              label: 'Encryption',
              value: manifest.encrypted ? 'Encrypted' : 'Not encrypted',
            ),
            const SizedBox(height: 12),
            Text(
              '${summary.skills} skills · ${summary.sessions} sessions · '
              '${summary.tags} tags',
              style: theme.textTheme.bodyLarge,
            ),
            Text(
              'Completed practice: ${_formatSeconds(summary.completedActiveSeconds)}',
              style: theme.textTheme.bodyMedium,
            ),
            if (summary.containsActiveOrPendingSession)
              Text(
                'Contains an active or pending session',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
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
                'but differ. Choose which side wins for each item, or apply one '
                'choice to all:',
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
                onSelectionChanged: (selection) {
                  _applyGlobalConflictResolution(selection.first);
                },
              ),
              const SizedBox(height: 8),
              ...preview.conflicts.map(_buildConflictTile),
            ],
            if (_hasCollision) ...[
              const SizedBox(height: 16),
              Text(
                'Active session conflict',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                _sameSessionCollision
                    ? 'This device and the backup share the same in-progress '
                          'session (same id) with different state. Choose which '
                          'copy to keep.'
                    : 'Both this device and the backup have an in-progress session. '
                          'Choose how to resolve before merging.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              RadioGroup<ActiveSessionDecision>(
                groupValue: _activeDecision,
                onChanged: (v) => setState(() => _activeDecision = v),
                child: Column(
                  children: [
                    const RadioListTile<ActiveSessionDecision>(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Keep current'),
                      subtitle: Text('Keep the session on this device'),
                      value: ActiveSessionDecision.keepCurrent,
                    ),
                    const RadioListTile<ActiveSessionDecision>(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Prefer imported'),
                      subtitle: Text('Use the session from the backup'),
                      value: ActiveSessionDecision.preferImported,
                    ),
                    if (!_sameSessionCollision)
                      const RadioListTile<ActiveSessionDecision>(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Complete imported with reviewed end'),
                        subtitle: Text(
                          'Keep current; mark the imported session completed',
                        ),
                        value: ActiveSessionDecision.completeOtherWithEnd,
                      ),
                    const RadioListTile<ActiveSessionDecision>(
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
                if (_reviewedEndIsFuture)
                  Text(
                    'End time cannot be in the future.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
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
            Text('How to import', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Merge combines records by UUID and newest update. Your current '
              'data stays unless the backup is newer or you choose Prefer '
              'imported for conflicts.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Replace removes all current local data after creating a safety '
              'snapshot, then loads the backup.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _canMerge
                  ? () => Navigator.pop(context, _buildChoice(ImportMode.merge))
                  : null,
              child: const Text('Merge'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () =>
                  Navigator.pop(context, _buildChoice(ImportMode.replace)),
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

  Widget _buildConflictTile(ImportConflict conflict) {
    final key = _conflictKey(conflict);
    final expanded = _expandedConflicts.contains(key);
    final resolution = _resolutionFor(conflict);
    final label = conflict.label ?? conflict.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            title: Text('${conflict.entityType}: $label'),
            subtitle: Text(
              resolution == ConflictResolution.keepCurrent
                  ? 'Keep current'
                  : 'Prefer imported',
            ),
            trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
            onTap: () {
              setState(() {
                if (expanded) {
                  _expandedConflicts.remove(key);
                } else {
                  _expandedConflicts.add(key);
                }
              });
            },
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SegmentedButton<ConflictResolution>(
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
                selected: {resolution},
                onSelectionChanged: (selection) {
                  _setPerItemResolution(conflict, selection.first);
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickReviewedEnd(BuildContext context) async {
    final now = DateTime.now();
    final initial = _reviewedEndUtc ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !context.mounted) return;
    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      _reviewedEndUtc = picked.isAfter(now) ? now : picked;
    });
  }

  static String _conflictKey(ImportConflict conflict) =>
      '${conflict.entityType}:${conflict.id}';

  static String _formatCreatedDate(String createdAtUtc) {
    if (createdAtUtc.isEmpty) return 'Unknown';
    final parsed = DateTime.tryParse(createdAtUtc);
    if (parsed == null) return createdAtUtc;
    return parsed.toLocal().toString();
  }

  static String _shortDeviceId(String deviceId) {
    if (deviceId.isEmpty) return 'Unknown';
    if (deviceId.length <= 12) return deviceId;
    return '${deviceId.substring(0, 8)}…';
  }

  static String _formatSeconds(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
