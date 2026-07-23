/// Domain enums for timer sessions (no Flutter/Drift).
library;

enum SessionStatus {
  active,
  paused,
  completionPending,
  completed;

  static SessionStatus parse(String value) => switch (value) {
    'paused' => SessionStatus.paused,
    'completion_pending' => SessionStatus.completionPending,
    'completed' => SessionStatus.completed,
    _ => SessionStatus.active,
  };

  String get storageValue => switch (this) {
    SessionStatus.active => 'active',
    SessionStatus.paused => 'paused',
    SessionStatus.completionPending => 'completion_pending',
    SessionStatus.completed => 'completed',
  };

  bool get isInProgress =>
      this == SessionStatus.active ||
      this == SessionStatus.paused ||
      this == SessionStatus.completionPending;
}

enum SessionMode {
  stopwatch,
  pomodoro,
  manual;

  static SessionMode parse(String value) => switch (value) {
    'pomodoro' => SessionMode.pomodoro,
    'manual' => SessionMode.manual,
    _ => SessionMode.stopwatch,
  };

  String get storageValue => name;
}

enum SegmentType {
  work,
  pause,
  pomodoroBreak;

  static SegmentType parse(String value) => switch (value) {
    'pause' => SegmentType.pause,
    'pomodoro_break' => SegmentType.pomodoroBreak,
    _ => SegmentType.work,
  };

  String get storageValue => switch (this) {
    SegmentType.work => 'work',
    SegmentType.pause => 'pause',
    SegmentType.pomodoroBreak => 'pomodoro_break',
  };
}

enum TimerMachineState {
  idle,
  running,
  paused,
  completionPending,
  recoveryReview;

  static TimerMachineState parse(String value) => switch (value) {
    'running' => TimerMachineState.running,
    'paused' => TimerMachineState.paused,
    'completion_pending' => TimerMachineState.completionPending,
    'recovery_review' => TimerMachineState.recoveryReview,
    _ => TimerMachineState.idle,
  };

  String get storageValue => switch (this) {
    TimerMachineState.idle => 'idle',
    TimerMachineState.running => 'running',
    TimerMachineState.paused => 'paused',
    TimerMachineState.completionPending => 'completion_pending',
    TimerMachineState.recoveryReview => 'recovery_review',
  };
}

enum RecoveryReason {
  restart,
  clockChange,
  longGap;

  static RecoveryReason? tryParse(String? value) => switch (value) {
    'restart' => RecoveryReason.restart,
    'clock_change' => RecoveryReason.clockChange,
    'long_gap' => RecoveryReason.longGap,
    _ => null,
  };

  String get storageValue => switch (this) {
    RecoveryReason.restart => 'restart',
    RecoveryReason.clockChange => 'clock_change',
    RecoveryReason.longGap => 'long_gap',
  };
}

/// Where startup recovery should send the UI.
enum StartupDestination { skillsHome, timer, completion, recoveryReview }

/// User choice on Recovery Review.
enum RecoveryDecision { includeFullGap, trimToHeartbeat, editEnd, discard }
