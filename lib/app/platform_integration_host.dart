import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/ayutam_app.dart';
import '../app/providers.dart';
import '../features/settings/domain/settings_repository.dart';
import '../features/timer/application/timer_platform_projection.dart';
import '../features/timer/domain/timer_enums.dart';
import '../features/timer/domain/timer_platform_ports.dart';
import '../features/timer/presentation/open_in_progress_session.dart';

/// App-level host: syncs notification/tray after timer commits and routes
/// platform actions back into the same Riverpod commands (ADR-014).
class PlatformIntegrationHost extends ConsumerStatefulWidget {
  const PlatformIntegrationHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PlatformIntegrationHost> createState() =>
      _PlatformIntegrationHostState();
}

class _PlatformIntegrationHostState
    extends ConsumerState<PlatformIntegrationHost> {
  StreamSubscription<TimerPlatformAction>? _actions;
  StreamSubscription<void>? _timeouts;
  StreamSubscription<void>? _closeRequests;
  var _closeToTrayExplained = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final coordinator = ref.read(timerPlatformCoordinatorProvider);
    final windows = ref.read(desktopWindowLifecycleProvider);
    try {
      await coordinator.start();
    } catch (_) {}
    try {
      await windows.ensureReady();
    } catch (e, st) {
      ref
          .read(appLoggerProvider)
          .warning(
            'Desktop window lifecycle failed: $e',
            error: e,
            stackTrace: st,
          );
    }
    _actions = coordinator.actions.listen(_onAction);
    _timeouts = coordinator.serviceTimeouts.listen((_) => _onTimeout());
    _closeRequests = windows.closeRequested.listen((_) => _onCloseRequested());
    await _syncFromSnapshot();
  }

  @override
  void dispose() {
    unawaited(_actions?.cancel());
    unawaited(_timeouts?.cancel());
    unawaited(_closeRequests?.cancel());
    super.dispose();
  }

  Future<void> _syncFromSnapshot() async {
    final snap = ref.read(timerSessionProvider).asData?.value;
    final coordinator = ref.read(timerPlatformCoordinatorProvider);
    final clock = ref.read(clockServiceProvider);

    if (snap == null) {
      await coordinator.clear();
      return;
    }

    String skillName = 'Practice';
    final skillId = snap.session?.skillId;
    if (skillId != null) {
      final skills =
          ref.read(allSkillsProvider).asData?.value ??
          ref.read(activeSkillsProvider).asData?.value;
      if (skills != null) {
        for (final s in skills) {
          if (s.id == skillId) {
            skillName = s.name;
            break;
          }
        }
      }
    }

    final projection = projectionFromSnapshot(
      snapshot: snap,
      skillName: skillName,
      nowUtc: clock.nowUtc(),
    );
    await coordinator.sync(projection);
  }

  Future<void> _onAction(TimerPlatformAction action) async {
    final notifier = ref.read(timerSessionProvider.notifier);
    switch (action) {
      case TimerPlatformAction.pause:
        await notifier.pause();
      case TimerPlatformAction.resume:
        await notifier.resume();
      case TimerPlatformAction.stop:
        final err = await notifier.stop();
        if (err == null) {
          await ref.read(desktopWindowLifecycleProvider).showAndFocus();
          // A mounted timer replaces itself when state becomes
          // completion-pending. Pushing here as well leaves that timer under
          // the completion page (Back still says Running; wakelock stays on).
          if (ref.read(timerScreenMountsProvider).count > 0) {
            break;
          }
          final snap = ref.read(timerSessionProvider).asData?.value;
          final skillId = snap?.session?.skillId;
          final nav = ayutamNavigatorKey.currentState;
          if (skillId != null && snap != null && nav != null) {
            await openInProgressSession(
              navigator: nav,
              skillId: skillId,
              snapshot: snap,
            );
          }
        }
      case TimerPlatformAction.showWindow:
        await ref.read(desktopWindowLifecycleProvider).showAndFocus();
      case TimerPlatformAction.exitApp:
        await _confirmExit();
    }
  }

  void _onTimeout() {
    ayutamScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text(
          'Timer notification stopped by the system. Your session is '
          'still running — open Ayutam to control it.',
        ),
      ),
    );
  }

  Future<void> _onCloseRequested() async {
    final live = ref
        .read(timerSessionProvider)
        .asData
        ?.value
        .runtime
        .machineState;
    final isLive =
        live == TimerMachineState.running || live == TimerMachineState.paused;
    final desktop = Platform.isWindows || Platform.isLinux;
    if (isLive && desktop) {
      if (!ref.read(desktopTrayServiceProvider).isAvailable) {
        ref
            .read(appLoggerProvider)
            .warning(
              'Close-to-tray skipped because the system tray is unavailable',
            );
        await _closeWithoutTray();
        return;
      }
      await _maybeExplainCloseToTray();
      try {
        await ref.read(desktopWindowLifecycleProvider).hideToTray();
      } catch (e, st) {
        ref
            .read(appLoggerProvider)
            .warning('Hide to tray failed: $e', error: e, stackTrace: st);
      }
      return;
    }
    await ref.read(desktopWindowLifecycleProvider).destroyAndQuit();
  }

  Future<void> _closeWithoutTray() async {
    final ctx = ayutamNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      return;
    }
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        title: const Text('System tray unavailable'),
        content: const Text(
          'Ayutam can\'t hide to the system tray on this desktop, so this '
          'window stays open. Exit quits the app. Reopen Ayutam to recover '
          'this session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep open'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(desktopWindowLifecycleProvider).destroyAndQuit();
    }
  }

  Future<void> _confirmExit() async {
    final windows = ref.read(desktopWindowLifecycleProvider);
    final live = ref
        .read(timerSessionProvider)
        .asData
        ?.value
        .runtime
        .machineState;
    final isLive =
        live == TimerMachineState.running || live == TimerMachineState.paused;
    if (!isLive) {
      await windows.destroyAndQuit();
      return;
    }
    // The window may already be hidden. Show it before the dialog so Exit
    // can be answered.
    await windows.showAndFocus();
    final ctx = ayutamNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      await windows.destroyAndQuit();
      return;
    }
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Exit Ayutam?'),
        content: const Text(
          'A practice session is still active. Exit stops only the app '
          'window; reopen Ayutam to recover the session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await windows.destroyAndQuit();
    }
  }

  Future<void> _maybeExplainCloseToTray() async {
    if (_closeToTrayExplained) return;
    final settings = ref.read(settingsRepositoryProvider);
    final raw = await settings.readValue(SettingsKeys.closeToTrayExplained);
    if (raw == 'true' || raw == '"true"') {
      _closeToTrayExplained = true;
      return;
    }
    final ctx = ayutamNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    await showDialog<void>(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Close hides to tray'),
        content: const Text(
          'While a timer is running, closing the window hides Ayutam to the '
          'system tray. Use Exit from the tray menu to quit.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
    _closeToTrayExplained = true;
    final clock = ref.read(clockServiceProvider);
    final deviceId = await ref.read(appDatabaseProvider).requireDeviceId();
    await settings.writeValue(
      key: SettingsKeys.closeToTrayExplained,
      valueJson: '"true"',
      updatedAtUtc: clock.nowUtc(),
      sourceDeviceId: deviceId,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(timerSessionProvider, (previous, next) {
      unawaited(_syncFromSnapshot());
    });
    return widget.child;
  }
}
