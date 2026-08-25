import 'package:flutter/material.dart';

import '../domain/backup_models.dart';

/// Result of the import preview confirmation sheet.
final class ImportPreviewChoice {
  const ImportPreviewChoice({
    required this.mode,
    required this.restoreActiveTimer,
  });

  final ImportMode mode;
  final bool restoreActiveTimer;
}

/// Preview summary with Merge / Replace and active-timer restore option.
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

  ImportPreview get preview => widget.preview;

  @override
  Widget build(BuildContext context) {
    final summary = preview.manifest.summary;
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottom),
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
            const SizedBox(height: 12),
            Text(
              '${preview.conflicts.length} equal-timestamp conflict(s). '
              'Merge keeps your current copies by default.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (preview.localHasActiveOrPending ||
              summary.containsActiveOrPendingSession) ...[
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
            onPressed: () => Navigator.pop(
              context,
              ImportPreviewChoice(
                mode: ImportMode.merge,
                restoreActiveTimer: _restoreActiveTimer,
              ),
            ),
            child: const Text('Merge'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pop(
              context,
              ImportPreviewChoice(
                mode: ImportMode.replace,
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
    );
  }

  static String _formatSeconds(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
