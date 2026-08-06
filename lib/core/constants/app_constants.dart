/// Shared product defaults (see product-spec / database docs).
abstract final class AppConstants {
  static const int defaultTargetHours = 10000;
  static const int defaultTargetSeconds = defaultTargetHours * 3600;
  static const int streakMinimumSecondsDefault = 120;
  static const int recoveryGapThresholdMinutes = 30;
  static const int longSessionWarningHours = 8;
  static const int schemaVersion = 2;

  /// Soft character hint for session notes (no hard limit).
  static const int noteSoftCharHint = 2000;

  /// Debounce for completion/detail note autosave.
  static const Duration noteAutosaveDebounce = Duration(milliseconds: 500);

  /// Learning Log two-pane breakpoint (UX: desktop ≥ ~1000 dp).
  static const double learningLogTwoPaneBreakpoint = 1000;
}
