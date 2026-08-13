/// FTS tokens for a session's recorded local calendar date(s).
///
/// Uses [offsetMinutesAtStart] (not the device's current zone) so historical
/// dates stay searchable after travel. Tokens are English month names plus
/// ISO `yyyy-MM-dd` and compact `yyyyMMdd` (hyphens are FTS separators / NOT).
String sessionDateSearchText({
  required DateTime startAtUtc,
  required int offsetMinutesAtStart,
  DateTime? endAtUtc,
}) {
  final tokens = <String>{};
  _addDateTokens(_wallClock(startAtUtc, offsetMinutesAtStart), tokens);
  if (endAtUtc != null) {
    final endWall = _wallClock(endAtUtc, offsetMinutesAtStart);
    final startWall = _wallClock(startAtUtc, offsetMinutesAtStart);
    if (endWall.year != startWall.year ||
        endWall.month != startWall.month ||
        endWall.day != startWall.day) {
      _addDateTokens(endWall, tokens);
    }
  }
  return tokens.join(' ');
}

DateTime _wallClock(DateTime utc, int offsetMinutes) {
  return utc.toUtc().add(Duration(minutes: offsetMinutes));
}

void _addDateTokens(DateTime wall, Set<String> tokens) {
  const short = [
    'jan',
    'feb',
    'mar',
    'apr',
    'may',
    'jun',
    'jul',
    'aug',
    'sep',
    'oct',
    'nov',
    'dec',
  ];
  const long = [
    'january',
    'february',
    'march',
    'april',
    'may',
    'june',
    'july',
    'august',
    'september',
    'october',
    'november',
    'december',
  ];
  final y = wall.year.toString().padLeft(4, '0');
  final m = wall.month.toString().padLeft(2, '0');
  final d = wall.day.toString().padLeft(2, '0');
  final monthIndex = wall.month - 1;
  tokens
    ..add('$y$m$d')
    ..add('$y-$m-$d')
    ..add(short[monthIndex])
    ..add(long[monthIndex])
    ..add('${wall.day}')
    ..add(y)
    ..add('${short[monthIndex]} ${wall.day} $y')
    ..add('${long[monthIndex]} ${wall.day} $y');
}
