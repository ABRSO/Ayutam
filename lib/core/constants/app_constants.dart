/// Shared product defaults (see product-spec / database docs).
abstract final class AppConstants {
  static const int defaultTargetHours = 10000;
  static const int defaultTargetSeconds = defaultTargetHours * 3600;
  static const int streakMinimumSecondsDefault = 120;
  static const int recoveryGapThresholdMinutes = 30;
  static const int longSessionWarningHours = 8;
  static const int schemaVersion = 1;
}
