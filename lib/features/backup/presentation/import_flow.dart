import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/result/result.dart';
import '../domain/backup_models.dart';
import 'import_preview_sheet.dart';

/// Shared import confirmation + apply path used by Settings and drag-and-drop.
Future<void> runImportPreviewFlow({
  required BuildContext context,
  required WidgetRef ref,
  required Result<ImportPreview> previewResult,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final preview = previewResult.valueOrNull;
  if (preview == null) {
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          previewResult.when(
            success: (_) => 'Import cancelled.',
            failure: (f) => f.message,
          ),
        ),
      ),
    );
    return;
  }
  if (!context.mounted) return;
  final choice = await showImportPreviewSheet(context, preview: preview);
  if (choice == null || !context.mounted) return;

  if (choice.activeDecision == ActiveSessionDecision.cancel) {
    messenger.showSnackBar(const SnackBar(content: Text('Import cancelled.')));
    return;
  }

  if (choice.mode == ImportMode.replace) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Replace all local data?'),
        content: const Text(
          'This overwrites skills, sessions, and settings on this device '
          'with the backup. A safety snapshot is created first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
  }

  messenger.showSnackBar(const SnackBar(content: Text('Importing…')));
  final result = await ref
      .read(backupServiceProvider)
      .applyImport(
        preview: preview,
        mode: choice.mode,
        conflictResolution: choice.conflictResolution,
        perItem: choice.perItem,
        activeDecision: choice.activeDecision,
        reviewedEndUtc: choice.reviewedEndUtc,
        restoreActiveTimer: choice.restoreActiveTimer,
      );
  ref.invalidate(backupStatusProvider);
  ref.invalidate(activeSkillsProvider);
  ref.invalidate(allSkillsProvider);
  ref.invalidate(learningLogListProvider);
  ref.invalidate(statsBundleProvider);
  await ref.read(timerSessionProvider.notifier).refresh();
  if (!context.mounted) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        result.when(
          success: (_) => choice.mode == ImportMode.replace
              ? 'Replace complete.'
              : 'Merge complete.',
          failure: (f) => f.message,
        ),
      ),
    ),
  );
}
