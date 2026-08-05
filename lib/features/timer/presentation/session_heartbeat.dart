import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/timer_enums.dart';

/// Writes the session heartbeat for as long as a session is running, no matter
/// which route is on screen.
///
/// Heartbeat ownership must not sit on the timer route: leaving that route does
/// not stop the session, and a stalled heartbeat makes startup recovery treat
/// legitimately active time as a gap. Per the state machine the heartbeat is
/// only refreshed while running, so paused sessions deliberately go quiet.
class SessionHeartbeat extends ConsumerStatefulWidget {
  const SessionHeartbeat({
    super.key,
    required this.child,
    this.interval = const Duration(seconds: 30),
  });

  final Widget child;
  final Duration interval;

  @override
  ConsumerState<SessionHeartbeat> createState() => _SessionHeartbeatState();
}

class _SessionHeartbeatState extends ConsumerState<SessionHeartbeat> {
  Timer? _timer;

  void _sync(bool running) {
    if (running) {
      _timer ??= Timer.periodic(widget.interval, (_) {
        ref.read(timerSessionProvider.notifier).heartbeat();
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running =
        ref.watch(timerSessionProvider).asData?.value.runtime.machineState ==
        TimerMachineState.running;
    _sync(running);
    return widget.child;
  }
}
