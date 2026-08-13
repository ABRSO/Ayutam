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
}
