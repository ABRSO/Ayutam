import '../../../core/constants/app_constants.dart';

/// Product: warn after 8 hours of *session* active time; never auto-stop.
bool exceedsLongSessionWarning(int sessionActiveSeconds) {
  return sessionActiveSeconds >= AppConstants.longSessionWarningSeconds;
}
