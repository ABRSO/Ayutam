import 'package:ayutam/core/id/id_generator.dart';
import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/database/app_database.dart';
import 'package:ayutam/features/learning_log/application/learning_log_service.dart';
import 'package:ayutam/features/learning_log/application/session_note_service.dart';
import 'package:ayutam/features/learning_log/application/tag_service.dart';
import 'package:ayutam/features/learning_log/data/drift_tag_repository.dart';
import 'package:ayutam/features/learning_log/data/session_search_indexer.dart';
import 'package:ayutam/features/learning_log/domain/learning_log_models.dart';
import 'package:ayutam/features/skills/application/skill_service.dart';
import 'package:ayutam/features/skills/data/drift_skill_repository.dart';
import 'package:ayutam/features/skills/domain/skill.dart';
import 'package:ayutam/features/timer/application/stopwatch_timer_service.dart';
import 'package:ayutam/features/timer/data/drift_session_repository.dart';
import 'package:ayutam/features/timer/data/drift_timer_runtime_repository.dart';
import 'package:ayutam/features/timer/data/drift_unit_of_work.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeqIds implements IdGenerator {
  int _n = 0;

  @override
  String v4() {
    _n += 1;
    return 'id-${_n.toString().padLeft(4, '0')}';
  }
}

void main() {
  late FakeClockService clock;
  late _SeqIds ids;
  late AppDatabase db;
  late SkillService skills;
  late StopwatchTimerService timer;
  late TagService tags;
  late SessionNoteService notes;
  late LearningLogService log;
  late SessionSearchIndexer indexer;

  setUp(() async {
    clock = FakeClockService(initialUtc: DateTime.utc(2026, 8, 6, 12));
    ids = _SeqIds();
    db = AppDatabase.memory(clock: clock, ids: ids);
    await db.ensureSeeded(clock: clock, ids: ids);
    final skillRepo = DriftSkillRepository(db);
    final sessionRepo = DriftSessionRepository(db);
    final runtimeRepo = DriftTimerRuntimeRepository(db);
    final tagRepo = DriftTagRepository(db);
    final uow = DriftUnitOfWork(db);
    indexer = SessionSearchIndexer(db);
    skills = SkillService(
      skills: skillRepo,
      sessions: sessionRepo,
      clock: clock,
      ids: ids,
      deviceId: db.requireDeviceId,
    );
    timer = StopwatchTimerService(
      sessions: sessionRepo,
      runtime: runtimeRepo,
      skills: skillRepo,
      uow: uow,
      clock: clock,
      ids: ids,
      deviceId: db.requireDeviceId,
    );
    tags = TagService(
      tags: tagRepo,
      clock: clock,
      ids: ids,
      deviceId: db.requireDeviceId,
    );
    notes = SessionNoteService(
      sessions: sessionRepo,
      skills: skillRepo,
      tags: tags,
      indexer: indexer,
      uow: uow,
      clock: clock,
      ids: ids,
      deviceId: db.requireDeviceId,
    );
    log = LearningLogService(
      sessions: sessionRepo,
      skills: skillRepo,
      tags: tagRepo,
      indexer: indexer,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> createSkill([String name = 'Piano']) async {
    return (await skills.create(name: name)).valueOrNull!.id;
  }

  Future<String> completeTimedSession({
    required String skillId,
    required String note,
    String? title,
    List<String> tagNames = const [],
  }) async {
    await timer.startStopwatch(skillId);
    clock.advance(const Duration(minutes: 10));
    await timer.stop();
    final sessionId = (await timer.snapshot()).session!.id;
    await notes.updateDraft(
      sessionId: sessionId,
      title: title,
      updateTitle: title != null,
      noteMarkdown: note,
      updateNote: true,
      tagNames: tagNames,
    );
    await timer.saveCompletion();
    return sessionId;
  }

  test('markdown round-trip: save reload preview text', () async {
    final skillId = await createSkill();
    final sessionId = await completeTimedSession(
      skillId: skillId,
      title: 'Scales',
      note: '# Focus\nPracticed **chromatic** scales',
      tagNames: ['Technique'],
    );

    final entry = await log.getEntry(sessionId);
    expect(entry, isNotNull);
    expect(entry!.session.title, 'Scales');
    expect(entry.session.noteMarkdown, contains('**chromatic**'));
    expect(entry.tags.map((t) => t.name), contains('Technique'));
    expect(entry.displayTitle, 'Scales');
  });

  test('autosave draft survives remount-style reload', () async {
    final skillId = await createSkill();
    await timer.startStopwatch(skillId);
    clock.advance(const Duration(minutes: 5));
    await timer.stop();
    final sessionId = (await timer.snapshot()).session!.id;

    await notes.updateDraft(
      sessionId: sessionId,
      noteMarkdown: 'Draft note before dispose',
      updateNote: true,
      tagNames: ['Focus'],
    );

    // Simulate provider remount: new service instances over same DB.
    final reloaded = await DriftSessionRepository(db).findById(sessionId);
    expect(reloaded!.noteMarkdown, 'Draft note before dispose');
    final draftTags = await tags.listForSession(sessionId);
    expect(draftTags.map((t) => t.normalizedName), contains('focus'));
  });

  test('FTS returns rows and indexer updates on note/tag change', () async {
    final skillId = await createSkill();
    final sessionId = await completeTimedSession(
      skillId: skillId,
      note: 'UniqueTokenAlpha practice',
      tagNames: ['alpha'],
    );

    expect(
      await indexer.searchSessionIds('UniqueTokenAlpha'),
      contains(sessionId),
    );
    expect(await indexer.searchSessionIds('Piano'), contains(sessionId));
    expect(await indexer.searchSessionIds('alpha'), contains(sessionId));

    await notes.updateDraft(
      sessionId: sessionId,
      noteMarkdown: 'UniqueTokenBeta after edit',
      updateNote: true,
      tagNames: ['beta'],
    );

    expect(await indexer.searchSessionIds('UniqueTokenAlpha'), isEmpty);
    expect(
      await indexer.searchSessionIds('UniqueTokenBeta'),
      contains(sessionId),
    );
    expect(await indexer.searchSessionIds('beta'), contains(sessionId));
  });

  test('filter AND combinations', () async {
    final piano = await createSkill('Piano');
    final guitar = await createSkill('Guitar');
    final a = await completeTimedSession(
      skillId: piano,
      note: 'with note',
      tagNames: ['shared', 'piano-only'],
    );
    clock.advance(const Duration(hours: 1));
    final b = await completeTimedSession(
      skillId: guitar,
      note: '',
      tagNames: ['shared'],
    );

    final pianoOnly = await log.query(LearningLogFilters(skillIds: {piano}));
    expect(pianoOnly.map((e) => e.session.id), [a]);

    final withNotes = await log.query(
      const LearningLogFilters(notePresence: NotePresenceFilter.withNotes),
    );
    expect(withNotes.map((e) => e.session.id), [a]);

    final sharedTag = await tags.ensureTag('shared');
    final tagged = await log.query(
      LearningLogFilters(tagIds: {sharedTag.valueOrNull!.id}),
    );
    expect(tagged.map((e) => e.session.id).toSet(), {a, b});

    final andCombo = await log.query(
      LearningLogFilters(
        skillIds: {guitar},
        notePresence: NotePresenceFilter.withoutNotes,
        tagIds: {sharedTag.valueOrNull!.id},
      ),
    );
    expect(andCombo.map((e) => e.session.id), [b]);
  });

  test('manual entry validation and overlap warn path', () async {
    final skillId = await createSkill();
    final start = DateTime.utc(2026, 8, 1, 10);
    final end = DateTime.utc(2026, 8, 1, 11);

    final first = await notes.createManualSession(
      skillId: skillId,
      startAtUtc: start,
      endAtUtc: end,
      noteMarkdown: 'Manual A',
    );
    expect(first.isSuccess, isTrue);
    expect(first.valueOrNull!.session, isNotNull);

    final overlap = await notes.createManualSession(
      skillId: skillId,
      startAtUtc: DateTime.utc(2026, 8, 1, 10, 30),
      endAtUtc: DateTime.utc(2026, 8, 1, 11, 30),
      noteMarkdown: 'Manual B',
    );
    expect(overlap.isSuccess, isTrue);
    expect(overlap.valueOrNull!.needsOverlapConfirm, isTrue);
    expect(overlap.valueOrNull!.session, isNull);

    final forced = await notes.createManualSession(
      skillId: skillId,
      startAtUtc: DateTime.utc(2026, 8, 1, 10, 30),
      endAtUtc: DateTime.utc(2026, 8, 1, 11, 30),
      noteMarkdown: 'Manual B',
      allowOverlap: true,
    );
    expect(forced.valueOrNull!.session, isNotNull);

    final invalid = await notes.createManualSession(
      skillId: skillId,
      startAtUtc: end,
      endAtUtc: start,
    );
    expect(invalid.isFailure, isTrue);
  });

  test('soft-delete Undo restores session and FTS', () async {
    final skillId = await createSkill();
    final sessionId = await completeTimedSession(
      skillId: skillId,
      note: 'RestoreMeToken',
    );

    expect((await notes.softDelete(sessionId)).isSuccess, isTrue);
    expect(await log.getEntry(sessionId), isNull);
    expect(await indexer.searchSessionIds('RestoreMeToken'), isEmpty);

    expect((await notes.restore(sessionId)).isSuccess, isTrue);
    expect(await log.getEntry(sessionId), isNotNull);
    expect(
      await indexer.searchSessionIds('RestoreMeToken'),
      contains(sessionId),
    );
  });

  test('tag ensure is case-insensitive unique', () async {
    final a = await tags.ensureTag('Focus');
    final b = await tags.ensureTag('focus');
    expect(a.valueOrNull!.id, b.valueOrNull!.id);
    expect(a.valueOrNull!.name, 'Focus');
  });

  test(
    'queryMonth returns only that local month and reports hasMore',
    () async {
      final skillId = await createSkill();
      await notes.createManualSession(
        skillId: skillId,
        startAtUtc: DateTime.utc(2026, 7, 15, 12),
        endAtUtc: DateTime.utc(2026, 7, 15, 13),
        title: 'July',
      );
      await notes.createManualSession(
        skillId: skillId,
        startAtUtc: DateTime.utc(2026, 8, 15, 12),
        endAtUtc: DateTime.utc(2026, 8, 15, 13),
        title: 'August',
      );

      final august = CalendarMonth.fromLocal(
        DateTime.utc(2026, 8, 15, 12).toLocal(),
      );
      final page = await log.queryMonth(const LearningLogFilters(), august);
      expect(page.entries.map((e) => e.session.title), ['August']);
      expect(page.hasMoreOlder, isTrue);

      final loaded = await log.loadOlder(
        const LearningLogFilters(),
        LearningLogListState(
          entries: page.entries,
          oldestLoaded: august,
          newestLoaded: august,
          hasMoreOlder: page.hasMoreOlder,
          hasMoreNewer: page.hasMoreNewer,
        ),
      );
      expect(loaded.entries.map((e) => e.session.title).toSet(), {
        'August',
        'July',
      });
    },
  );

  test('archived skills remain in journal skill list', () async {
    final piano = await createSkill('Piano');
    await createSkill('Guitar');
    expect((await skills.archive(piano)).isSuccess, isTrue);
    final journal = await skills.listForJournal();
    expect(
      journal.map((s) => s.name).toSet(),
      containsAll(['Piano', 'Guitar']),
    );
    expect(
      journal.firstWhere((s) => s.id == piano).status,
      SkillStatus.archived,
    );
    final active = await skills.listActive();
    expect(active.map((s) => s.id), isNot(contains(piano)));
  });

  test('edit completed session skill and times', () async {
    final piano = await createSkill('Piano');
    final guitar = await createSkill('Guitar');
    final created = await notes.createManualSession(
      skillId: piano,
      startAtUtc: DateTime.utc(2026, 8, 1, 10),
      endAtUtc: DateTime.utc(2026, 8, 1, 11),
      title: 'Move me',
    );
    final sessionId = created.valueOrNull!.session!.id;
    final updated = await notes.updateCompletedSession(
      sessionId: sessionId,
      skillId: guitar,
      startAtUtc: DateTime.utc(2026, 8, 1, 12),
      endAtUtc: DateTime.utc(2026, 8, 1, 14),
    );
    expect(updated.isSuccess, isTrue);
    final entry = await log.getEntry(sessionId);
    expect(entry!.session.skillId, guitar);
    expect(entry.session.activeSeconds, 2 * 3600);
    expect(entry.skillName, 'Guitar');
  });
}
