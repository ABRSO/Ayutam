import 'package:ayutam/features/learning_log/data/session_date_search_text.dart';
import 'package:ayutam/features/learning_log/data/session_search_indexer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ftsQuery preserves Unicode and quotes terms', () {
    expect(SessionSearchIndexer.ftsQuery('संगीत'), '"संगीत"*');
    expect(SessionSearchIndexer.ftsQuery('café scales'), '"café"* "scales"*');
    expect(SessionSearchIndexer.ftsQuery('!!!'), isNull);
    expect(SessionSearchIndexer.ftsQuery('2026-08-01'), '"20260801"*');
  });

  test('sessionDateSearchText includes ISO and English month tokens', () {
    final text = sessionDateSearchText(
      startAtUtc: DateTime.utc(2026, 8, 1, 10),
      offsetMinutesAtStart: 0,
    );
    expect(text, contains('20260801'));
    expect(text, contains('2026-08-01'));
    expect(text, contains('aug'));
    expect(text, contains('august'));
  });
}
