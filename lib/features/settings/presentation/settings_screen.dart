import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/result/result.dart';
import '../../backup/domain/backup_models.dart';
import '../../backup/presentation/import_preview_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static final _backupStamp = DateFormat.yMMMd().add_jm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceIdAsync = ref.watch(deviceIdProvider);
    final reducedMotion =
        ref.watch(reducedMotionProvider).asData?.value ?? false;
    final weeklyReminder =
        ref.watch(weeklyBackupReminderProvider).asData?.value ?? true;
    final backupStatus = ref.watch(backupStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Appearance'),
            subtitle: Text('Follows system theme (Phase 0)'),
          ),
          SwitchListTile(
            title: const Text('Reduced motion'),
            subtitle: const Text(
              'Disables the flip-clock 3D animation. Also follows the '
              'system Reduce motion / disable animations setting.',
            ),
            value: reducedMotion,
            onChanged: (value) {
              unawaited(
                ref.read(settingsServiceProvider).setReducedMotion(value),
              );
            },
          ),
          const Divider(),
          const ListTile(
            title: Text('Backup & Data'),
            subtitle: Text(
              'Export, import, and safety snapshots stay on this device.',
            ),
          ),
          backupStatus.when(
            loading: () => const ListTile(
              title: Text('Backup status'),
              subtitle: Text('Loading…'),
            ),
            error: (e, _) => ListTile(
              title: const Text('Backup status'),
              subtitle: Text('Error: $e'),
            ),
            data: (status) => ListTile(
              title: const Text('Backup status'),
              subtitle: Text(_statusSubtitle(status)),
            ),
          ),
          SwitchListTile(
            title: const Text('Weekly backup reminder'),
            subtitle: const Text(
              'Show a reminder on Skills when a backup is due.',
            ),
            value: weeklyReminder,
            onChanged: (value) {
              unawaited(
                ref
                    .read(settingsServiceProvider)
                    .setWeeklyBackupReminder(value),
              );
            },
          ),
          ListTile(
            title: const Text('Export backup'),
            subtitle: const Text('Verified .skilltracker archive'),
            onTap: () => _runBackupAction(context, ref, () async {
              final result = await ref
                  .read(backupServiceProvider)
                  .exportSkilltracker();
              return result.when(
                success: (path) => 'Backup saved: $path',
                failure: (f) => f.message,
              );
            }, invalidateStatus: true),
          ),
          ListTile(
            title: const Text('Export JSON'),
            subtitle: const Text('Human-readable portable backup'),
            onTap: () => _runBackupAction(context, ref, () async {
              final result = await ref.read(backupServiceProvider).exportJson();
              return result.when(
                success: (path) => 'JSON saved: $path',
                failure: (f) => f.message,
              );
            }, invalidateStatus: true),
          ),
          ListTile(
            title: const Text('Import backup'),
            subtitle: const Text(
              'Merge or replace from .skilltracker or .json',
            ),
            onTap: () => _importBackup(context, ref),
          ),
          ListTile(
            title: const Text('Import JSON'),
            subtitle: const Text('Restore from a portable JSON backup'),
            onTap: () => _importBackup(context, ref),
          ),
          ListTile(
            title: const Text('Import SQLite snapshot'),
            subtitle: const Text('Replace (or merge) from a .sqlite file'),
            onTap: () => _importSqlite(context, ref),
          ),
          ListTile(
            title: const Text('Export CSV'),
            subtitle: const Text('Sessions spreadsheet (not restorable)'),
            onTap: () => _runBackupAction(context, ref, () async {
              final result = await ref
                  .read(auxiliaryExportServiceProvider)
                  .exportCsv();
              return result.when(
                success: (path) => 'CSV saved: $path',
                failure: (f) => f.message,
              );
            }),
          ),
          ListTile(
            title: const Text('Export SQLite'),
            subtitle: const Text('Consistent database snapshot'),
            onTap: () => _runBackupAction(context, ref, () async {
              final result = await ref
                  .read(auxiliaryExportServiceProvider)
                  .exportSqliteSnapshot();
              return result.when(
                success: (path) => 'SQLite saved: $path',
                failure: (f) => f.message,
              );
            }),
          ),
          ListTile(
            title: const Text('Safety snapshots'),
            subtitle: const Text('Local copies kept before imports/deletes'),
            onTap: () => _showSnapshots(context, ref),
          ),
          const Divider(),
          const ListTile(
            title: Text('About Ayutam'),
            subtitle: Text(
              'Local-first skill tracker · schema v${AppConstants.schemaVersion}',
            ),
          ),
          deviceIdAsync.when(
            data: (id) =>
                ListTile(title: const Text('Device ID'), subtitle: Text(id)),
            loading: () => const ListTile(
              title: Text('Device ID'),
              subtitle: Text('Loading…'),
            ),
            error: (e, _) => ListTile(
              title: const Text('Device ID'),
              subtitle: Text('Error: $e'),
            ),
          ),
          const ListTile(
            title: Text('Privacy'),
            subtitle: Text(
              'No accounts, analytics, or automatic cloud sync. '
              'Data stays on this device until you export a backup.',
            ),
          ),
        ],
      ),
    );
  }

  static String _statusSubtitle(BackupStatus status) {
    if (status.neverBackedUp) {
      return 'Never backed up'
          '${status.sessionsChangedSinceBackup > 0 ? ' · ${status.sessionsChangedSinceBackup} session change(s)' : ''}'
          '${status.due ? ' · backup due' : ''}';
    }
    final when = _backupStamp.format(
      status.lastSuccessfulBackupAtUtc!.toLocal(),
    );
    final parts = <String>['Last backup $when'];
    if (status.sessionsChangedSinceBackup > 0) {
      parts.add('${status.sessionsChangedSinceBackup} session change(s)');
    }
    if (status.due) {
      parts.add('backup due');
    }
    return parts.join(' · ');
  }

  static Future<void> _runBackupAction(
    BuildContext context,
    WidgetRef ref,
    Future<String> Function() action, {
    bool invalidateStatus = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Working…')));
    final message = await action();
    if (invalidateStatus) {
      ref.invalidate(backupStatusProvider);
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  static Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final previewResult = await ref.read(backupServiceProvider).previewImport();
    if (!context.mounted) return;
    await _finishImport(
      context: context,
      ref: ref,
      messenger: messenger,
      previewResult: previewResult,
    );
  }

  static Future<void> _importSqlite(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final previewResult = await ref
        .read(backupServiceProvider)
        .previewSqliteImport();
    if (!context.mounted) return;
    await _finishImport(
      context: context,
      ref: ref,
      messenger: messenger,
      previewResult: previewResult,
    );
  }

  static Future<void> _finishImport({
    required BuildContext context,
    required WidgetRef ref,
    required ScaffoldMessengerState messenger,
    required Result<ImportPreview> previewResult,
  }) async {
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
      messenger.showSnackBar(
        const SnackBar(content: Text('Import cancelled.')),
      );
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

  static Future<void> _showSnapshots(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final snapshots = await ref.read(backupServiceProvider).listSnapshots();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Safety snapshots'),
        content: SizedBox(
          width: double.maxFinite,
          child: snapshots.isEmpty
              ? const Text('No safety snapshots yet.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshots.length,
                  itemBuilder: (context, index) {
                    final snap = snapshots[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(snap.reason),
                      subtitle: Text(
                        '${_backupStamp.format(snap.createdAtUtc.toLocal())}'
                        '${snap.isValid ? '' : ' · invalid'}',
                      ),
                      trailing:
                          snap.isValid && !snap.filePath.startsWith('memory://')
                          ? TextButton(
                              onPressed: () async {
                                Navigator.pop(dialogContext);
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Restore snapshot?'),
                                    content: const Text(
                                      'This replaces your current data with the '
                                      'snapshot. A new safety snapshot is taken first.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(c, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Restore'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm != true || !context.mounted) return;
                                final result = await ref
                                    .read(backupServiceProvider)
                                    .restoreSnapshot(snap);
                                if (!context.mounted) return;
                                final messenger = ScaffoldMessenger.of(context);
                                result.when(
                                  success: (_) {
                                    ref.invalidate(backupStatusProvider);
                                    ref.invalidate(activeSkillsProvider);
                                    ref.invalidate(allSkillsProvider);
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Snapshot restored.'),
                                      ),
                                    );
                                  },
                                  failure: (f) => messenger.showSnackBar(
                                    SnackBar(content: Text(f.message)),
                                  ),
                                );
                              },
                              child: const Text('Restore'),
                            )
                          : null,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
