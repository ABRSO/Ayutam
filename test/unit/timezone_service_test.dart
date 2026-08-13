import 'package:ayutam/core/time/iana_timezone_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('IanaTimezoneService stores IANA ids and DST-aware offsets', () {
    final kolkata = IanaTimezoneService(ianaId: 'Asia/Kolkata');
    expect(kolkata.ianaId, 'Asia/Kolkata');
    expect(kolkata.offsetMinutesAt(DateTime.utc(2026, 8, 1, 10)), 330);

    final unknown = IanaTimezoneService(ianaId: 'Not/AZone');
    expect(['UTC', 'Etc/UTC'], contains(unknown.ianaId));
    expect(unknown.offsetMinutesAt(DateTime.utc(2026, 1, 1)), 0);
  });

  test(
    'CLDR alias ids from Windows/ICU resolve instead of degrading to UTC',
    () {
      // Windows reports India Standard Time as Asia/Calcutta (CLDR canonical),
      // which is a link zone; it must not silently become UTC (offset 0 made
      // the skill editor cap "today" at the previous UTC day after midnight).
      final calcutta = IanaTimezoneService(ianaId: 'Asia/Calcutta');
      expect(calcutta.ianaId, 'Asia/Calcutta');
      expect(calcutta.offsetMinutesAt(DateTime.utc(2026, 8, 13, 19, 4)), 330);
    },
  );
}
