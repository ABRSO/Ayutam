import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/ayutam_app.dart';
import '../app/providers.dart';
import '../core/result/result.dart';
import '../features/backup/domain/backup_models.dart';
import '../features/backup/presentation/import_flow.dart';

/// Desktop drag-and-drop for `.skilltracker` / `.json` / `.sqlite` imports.
class DesktopImportDropTarget extends ConsumerStatefulWidget {
  const DesktopImportDropTarget({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DesktopImportDropTarget> createState() =>
      _DesktopImportDropTargetState();
}

class _DesktopImportDropTargetState
    extends ConsumerState<DesktopImportDropTarget> {
  var _dragging = false;
  var _busy = false;

  bool get _enabled => !_busy && (Platform.isWindows || Platform.isLinux);

  @override
  Widget build(BuildContext context) {
    if (!(Platform.isWindows || Platform.isLinux)) {
      return widget.child;
    }
    return DropTarget(
      onDragEntered: (_) {
        if (_enabled) setState(() => _dragging = true);
      },
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (detail) {
        setState(() => _dragging = false);
        unawaited(_handleDrop(detail));
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_dragging)
            ColoredBox(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              child: Center(
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Drop backup to import'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleDrop(DropDoneDetails detail) async {
    if (_busy) return;
    final files = detail.files;
    if (files.isEmpty) return;
    if (files.length > 1) {
      ayutamScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Drop a single backup file.')),
      );
      return;
    }
    final path = files.first.path;
    final lower = path.toLowerCase();
    final ctx = ayutamNavigatorKey.currentContext;
    if (ctx == null) return;

    _busy = true;
    try {
      final bytes = await File(path).readAsBytes();
      final backup = ref.read(backupServiceProvider);
      late final Result<ImportPreview> previewResult;
      if (lower.endsWith('.skilltracker')) {
        previewResult = await backup.previewImportBytes(
          bytes: bytes,
          fileName: path,
        );
      } else if (lower.endsWith('.json')) {
        previewResult = await backup.previewImportBytes(
          bytes: bytes,
          fileName: path,
        );
      } else if (lower.endsWith('.sqlite') || lower.endsWith('.db')) {
        previewResult = await backup.previewSqliteImportBytes(
          bytes: bytes,
          fileName: path,
        );
      } else {
        ayutamScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text(
              'Unsupported file. Use .skilltracker, .json, or .sqlite.',
            ),
          ),
        );
        return;
      }
      if (!ctx.mounted) return;
      await runImportPreviewFlow(
        context: ctx,
        ref: ref,
        previewResult: previewResult,
      );
    } catch (e) {
      ayutamScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Could not read dropped file: $e')),
      );
    } finally {
      _busy = false;
    }
  }
}
