import 'package:ayutam/core/constants/app_constants.dart';
import 'package:ayutam/features/timer/application/long_session_warning.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('warns at eight hours of session active time and never below', () {
    expect(
      exceedsLongSessionWarning(AppConstants.longSessionWarningSeconds - 1),
      isFalse,
    );
    expect(
      exceedsLongSessionWarning(AppConstants.longSessionWarningSeconds),
      isTrue,
    );
  });
}
