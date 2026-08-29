import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/skills/domain/skill.dart';
import '../features/timer/domain/timer_enums.dart';
import '../features/timer/presentation/pre_session_sheet.dart';
import 'ayutam_app.dart';
import 'providers.dart';

/// Desktop timer shortcuts (product-spec §2.3 / F-017).
///
/// Space = pause/resume, Ctrl+Enter = start last skill, Ctrl+Shift+Enter = stop.
/// Suppressed while an editable text field has focus.
class DesktopTimerShortcuts extends ConsumerStatefulWidget {
  const DesktopTimerShortcuts({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DesktopTimerShortcuts> createState() =>
      _DesktopTimerShortcutsState();
}

class _DesktopTimerShortcutsState extends ConsumerState<DesktopTimerShortcuts> {
  bool _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (_textFieldFocused()) return false;

    final isSpace = event.logicalKey == LogicalKeyboardKey.space;
    final isEnter =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    final ctrl =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final shift = HardwareKeyboard.instance.isShiftPressed;

    if (isSpace && !ctrl && !shift) {
      unawaited(_pauseOrResume());
      return true;
    }
    if (isEnter && ctrl && shift) {
      unawaited(_stop());
      return true;
    }
    if (isEnter && ctrl && !shift) {
      unawaited(_start());
      return true;
    }
    return false;
  }

  bool _textFieldFocused() {
    final primary = FocusManager.instance.primaryFocus;
    if (primary == null) return false;
    final ctx = primary.context;
    if (ctx == null) return false;
    return ctx.findAncestorWidgetOfExactType<EditableText>() != null ||
        ctx.findAncestorWidgetOfExactType<TextField>() != null ||
        ctx.findAncestorWidgetOfExactType<TextFormField>() != null;
  }

  Future<void> _pauseOrResume() async {
    final state = ref
        .read(timerSessionProvider)
        .asData
        ?.value
        .runtime
        .machineState;
    final notifier = ref.read(timerSessionProvider.notifier);
    if (state == TimerMachineState.running) {
      await notifier.pause();
    } else if (state == TimerMachineState.paused) {
      await notifier.resume();
    }
  }

  Future<void> _stop() async {
    final state = ref
        .read(timerSessionProvider)
        .asData
        ?.value
        .runtime
        .machineState;
    if (state != TimerMachineState.running &&
        state != TimerMachineState.paused) {
      return;
    }
    await ref.read(timerSessionProvider.notifier).stop();
  }

  Future<void> _start() async {
    final state = ref
        .read(timerSessionProvider)
        .asData
        ?.value
        .runtime
        .machineState;
    if (state == TimerMachineState.running ||
        state == TimerMachineState.paused ||
        state == TimerMachineState.completionPending) {
      return;
    }
    final skillId = ref.read(shortcutSkillIdProvider);
    final ctx = ayutamNavigatorKey.currentContext;
    if (skillId == null || ctx == null) {
      ayutamScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
            'Select a skill and press Play once to enable Ctrl+Enter.',
          ),
        ),
      );
      return;
    }
    final skills =
        ref.read(activeSkillsProvider).asData?.value ??
        ref.read(allSkillsProvider).asData?.value;
    Skill? skill;
    if (skills != null) {
      for (final s in skills) {
        if (s.id == skillId) {
          skill = s;
          break;
        }
      }
    }
    if (skill == null) {
      ayutamScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Skill for Ctrl+Enter is no longer available.'),
        ),
      );
      return;
    }
    await showPreSessionSheet(ctx, skill: skill);
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
