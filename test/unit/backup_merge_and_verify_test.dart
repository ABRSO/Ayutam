import 'dart:typed_data';

import 'package:ayutam/core/id/id_generator.dart';
import 'package:ayutam/core/result/result.dart';
import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/core/time/timezone_service.dart';
import 'package:ayutam/database/app_database.dart';
import 'package:ayutam/features/backup/application/backup_service.dart';
import 'package:ayutam/features/backup/application/merge_engine.dart';
import 'package:ayutam/features/backup/data/drift_backup_store.dart';
import 'package:ayutam/features/backup/domain/backup_models.dart';
import 'package:ayutam/features/backup/domain/backup_store.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

BackupSessionRecord _liveSession({
  required String id,
  required String skillId,
  required int start,
  required int updated,
  String title = 'live',
}) {
  return BackupSessionRecord(
    id: id,
    skillId: skillId,
    title: title,
    mode: 'stopwatch',
    status: 'active',
    source: 'timer',
    startAtUtc: start,
    endAtUtc: null,
    activeSeconds: 30,
    pausedSeconds: 0,
    timezoneIdAtCreation: 'UTC',
    offsetMinutesAtStart: 0,
    createdAtUtc: start,
    updatedAtUtc: updated,
    sourceDeviceId: 'd',
  );
}

BackupPayload _emptyPayload({
  List<BackupSkillRecord> skills = const [],
  List<BackupSessionRecord> sessions = const [],
  List<BackupSegmentRecord> segments = const [],
  List<BackupTagRecord> tags = const [],
  List<BackupSessionTagRecord> sessionTags = const [],
}) {
  return BackupPayload(
    dataVersion: 1,
    exportedAtUtc: '2026-08-26T00:00:00.000Z',
    skills: skills,
    sessions: sessions,
    sessionSegments: segments,
    tags: tags,
    sessionTags: sessionTags,
    settings: const [],
    deviceMetadata: const [],
  );
}

BackupSkillRecord _skill(String id, String name, int updated) {
  return BackupSkillRecord(
    id: id,
    name: name,
    targetSeconds: 36000000,
    createdLocalDate: '2026-01-01',
    status: 'active',
    sortOrder: 0,
    createdAtUtc: updated,
    updatedAtUtc: updated,
    sourceDeviceId: 'd',
  );
}

void main() {
  const engine = MergeEngine();
  const skillId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  const localLiveId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  const incomingLiveId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
  const sharedSessionId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
  const segKeepId = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
  const segDropId = 'ffffffff-ffff-4fff-8fff-ffffffffffff';
  const segNewId = '11111111-1111-4111-8111-111111111111';
  const tagKeepId = '22222222-2222-4222-8222-222222222222';
  const tagDropId = '33333333-3333-4333-8333-333333333333';
  const tagAddId = '44444444-4444-4444-8444-444444444444';

  group('active-session collision', () {
    late BackupPayload local;
    late BackupPayload incoming;

    setUp(() {
      final skill = _skill(skillId, 'Guitar', 1);
      local = _emptyPayload(
        skills: [skill],
        sessions: [
          _liveSession(
            id: localLiveId,
            skillId: skillId,
            start: 1000,
            updated: 2000,
            title: 'local live',
          ),
        ],
      );
      incoming = _emptyPayload(
        skills: [skill],
        sessions: [
          _liveSession(
            id: incomingLiveId,
            skillId: skillId,
            start: 1500,
            updated: 3000,
            title: 'incoming live',
          ),
        ],
      );
    });

    test('preview flags collision and does not invent completions', () {
      final merged = engine.merge(local: local, incoming: incoming);
      expect(merged.requiresActiveSessionDecision, isTrue);
      expect(merged.activeSessionCollision, isNotNull);
      final live = merged.payload.sessions.where(
        (s) =>
            s.deletedAtUtc == null &&
            (s.status == 'active' ||
                s.status == 'paused' ||
                s.status == 'completion_pending'),
      );
      // Without a decision we do not silently demote — both may still be live
      // in the dry-run payload; apply must require a decision.
      expect(merged.activeSessionCollision!.localLive.id, localLiveId);
      expect(merged.activeSessionCollision!.incomingLive.id, incomingLiveId);
      expect(
        live.every((s) => s.endAtUtc == null || s.endAtUtc! >= s.startAtUtc),
        isTrue,
      );
      expect(
        live.where((s) => s.endAtUtc == s.startAtUtc && s.activeSeconds > 0),
        isEmpty,
      );
    });

    test('keepCurrent keeps local live and omits other live', () {
      final merged = engine.merge(
        local: local,
        incoming: incoming,
        activeDecision: ActiveSessionDecision.keepCurrent,
      );
      expect(merged.requiresActiveSessionDecision, isTrue);
      final live = merged.payload.sessions
          .where(
            (s) =>
                s.status == 'active' ||
                s.status == 'paused' ||
                s.status == 'completion_pending',
          )
          .toList();
      expect(live, hasLength(1));
      expect(live.single.id, localLiveId);
      expect(
        merged.payload.sessions.where((s) => s.id == incomingLiveId),
        isEmpty,
      );
    });

    test('preferImported keeps incoming live and omits local live', () {
      final merged = engine.merge(
        local: local,
        incoming: incoming,
        activeDecision: ActiveSessionDecision.preferImported,
      );
      final live = merged.payload.sessions
          .where((s) => s.status == 'active')
          .toList();
      expect(live, hasLength(1));
      expect(live.single.id, incomingLiveId);
      expect(
        merged.payload.sessions.where((s) => s.id == localLiveId),
        isEmpty,
      );
    });

    test('completeOtherWithEnd keeps local live and completes imported', () {
      final merged = engine.merge(
        local: local,
        incoming: incoming,
        activeDecision: ActiveSessionDecision.completeOtherWithEnd,
        reviewedEndAtUtc: 5000,
      );
      final live = merged.payload.sessions
          .where((s) => s.status == 'active')
          .toList();
      expect(live, hasLength(1));
      expect(live.single.id, localLiveId);
      final completed = merged.payload.sessions.singleWhere(
        (s) => s.id == incomingLiveId,
      );
      expect(completed.status, 'completed');
      expect(completed.endAtUtc, 5000);
    });

    test('completeOtherWithEnd rejects missing reviewed end', () {
      expect(
        () => engine.merge(
          local: local,
          incoming: incoming,
          activeDecision: ActiveSessionDecision.completeOtherWithEnd,
        ),
        throwsArgumentError,
      );
    });

    test('cancel returns local payload unchanged', () {
      final merged = engine.merge(
        local: local,
        incoming: incoming,
        activeDecision: ActiveSessionDecision.cancel,
      );
      expect(merged.cancelled, isTrue);
      expect(merged.payload.sessions.map((s) => s.id), [localLiveId]);
    });
  });

  group('winning session children wholesale', () {
    test('incoming newer session drops local-only segment and tag', () {
      final skill = _skill(skillId, 'Guitar', 1);
      final localSession = const BackupSessionRecord(
        id: sharedSessionId,
        skillId: skillId,
        title: 'old',
        mode: 'stopwatch',
        status: 'completed',
        source: 'timer',
        startAtUtc: 1000,
        endAtUtc: 2000,
        activeSeconds: 100,
        pausedSeconds: 0,
        timezoneIdAtCreation: 'UTC',
        offsetMinutesAtStart: 0,
        createdAtUtc: 1000,
        updatedAtUtc: 1000,
        sourceDeviceId: 'local',
      );
      final incomingSession = const BackupSessionRecord(
        id: sharedSessionId,
        skillId: skillId,
        title: 'new',
        mode: 'stopwatch',
        status: 'completed',
        source: 'timer',
        startAtUtc: 1000,
        endAtUtc: 1900,
        activeSeconds: 60,
        pausedSeconds: 0,
        timezoneIdAtCreation: 'UTC',
        offsetMinutesAtStart: 0,
        createdAtUtc: 1000,
        updatedAtUtc: 2000,
        sourceDeviceId: 'remote',
      );

      final local = _emptyPayload(
        skills: [skill],
        sessions: [localSession],
        segments: [
          const BackupSegmentRecord(
            id: segKeepId,
            sessionId: sharedSessionId,
            segmentType: 'work',
            startAtUtc: 1000,
            endAtUtc: 1600,
            durationSeconds: 60,
            createdAtUtc: 1000,
            updatedAtUtc: 1000,
          ),
          const BackupSegmentRecord(
            id: segDropId,
            sessionId: sharedSessionId,
            segmentType: 'work',
            startAtUtc: 1600,
            endAtUtc: 2000,
            durationSeconds: 40,
            createdAtUtc: 1000,
            updatedAtUtc: 1000,
          ),
        ],
        tags: [
          const BackupTagRecord(
            id: tagKeepId,
            name: 'keep',
            normalizedName: 'keep',
            createdAtUtc: 1,
            updatedAtUtc: 1,
            sourceDeviceId: 'd',
          ),
          const BackupTagRecord(
            id: tagDropId,
            name: 'drop',
            normalizedName: 'drop',
            createdAtUtc: 1,
            updatedAtUtc: 1,
            sourceDeviceId: 'd',
          ),
        ],
        sessionTags: [
          const BackupSessionTagRecord(
            sessionId: sharedSessionId,
            tagId: tagKeepId,
          ),
          const BackupSessionTagRecord(
            sessionId: sharedSessionId,
            tagId: tagDropId,
          ),
        ],
      );

      final incoming = _emptyPayload(
        skills: [skill],
        sessions: [incomingSession],
        segments: [
          const BackupSegmentRecord(
            id: segKeepId,
            sessionId: sharedSessionId,
            segmentType: 'work',
            startAtUtc: 1000,
            endAtUtc: 1500,
            durationSeconds: 50,
            createdAtUtc: 1000,
            updatedAtUtc: 2000,
          ),
          const BackupSegmentRecord(
            id: segNewId,
            sessionId: sharedSessionId,
            segmentType: 'work',
            startAtUtc: 1500,
            endAtUtc: 1600,
            durationSeconds: 10,
            createdAtUtc: 2000,
            updatedAtUtc: 2000,
          ),
        ],
        tags: [
          const BackupTagRecord(
            id: tagKeepId,
            name: 'keep',
            normalizedName: 'keep',
            createdAtUtc: 1,
            updatedAtUtc: 1,
            sourceDeviceId: 'd',
          ),
          const BackupTagRecord(
            id: tagAddId,
            name: 'add',
            normalizedName: 'add',
            createdAtUtc: 2,
            updatedAtUtc: 2,
            sourceDeviceId: 'd',
          ),
        ],
        sessionTags: [
          const BackupSessionTagRecord(
            sessionId: sharedSessionId,
            tagId: tagKeepId,
          ),
          const BackupSessionTagRecord(
            sessionId: sharedSessionId,
            tagId: tagAddId,
          ),
        ],
      );

      final merged = engine.merge(local: local, incoming: incoming);
      final session = merged.payload.sessions.singleWhere(
        (s) => s.id == sharedSessionId,
      );
      expect(session.title, 'new');
      expect(session.activeSeconds, 60);

      final segIds = merged.payload.sessionSegments
          .where((s) => s.sessionId == sharedSessionId)
          .map((s) => s.id)
          .toSet();
      expect(segIds, {segKeepId, segNewId});
      expect(segIds.contains(segDropId), isFalse);

      final workSeconds = merged.payload.sessionSegments
          .where(
            (s) => s.sessionId == sharedSessionId && s.segmentType == 'work',
          )
          .fold<int>(0, (n, s) => n + s.durationSeconds);
      expect(workSeconds, session.activeSeconds);

      final boundary = merged.payload.sessionSegments.singleWhere(
        (s) => s.id == segKeepId,
      );
      expect(boundary.endAtUtc, 1500);
      expect(boundary.durationSeconds, 50);

      final tagIds = merged.payload.sessionTags
          .where((t) => t.sessionId == sharedSessionId)
          .map((t) => t.tagId)
          .toSet();
      expect(tagIds, {tagKeepId, tagAddId});
      expect(tagIds.contains(tagDropId), isFalse);
    });
  });

  group('verify-before-success reads destination', () {
    late AppDatabase db;
    late DriftBackupStore store;
    late FakeClockService clock;
    late UuidIdGenerator ids;

    setUp(() async {
      clock = FakeClockService(initialUtc: DateTime.utc(2026, 8, 26, 12));
      ids = const UuidIdGenerator();
      db = AppDatabase.memory(clock: clock, ids: ids);
      await db.ensureSeeded(clock: clock, ids: ids);
      store = DriftBackupStore(db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'unreadable destination fails and does not update last success',
      () async {
        final files = _UnreadableSavedFiles();
        final service = BackupService(
          store: store,
          files: files,
          clock: clock,
          timezones: const FakeTimezoneService(),
          deviceId: () async => db.requireDeviceId(),
          applicationVersion: () async => '0.5.0',
          snapshotsDirectory: () async => 'memory',
          newId: ids.v4,
          platform: 'test',
        );

        expect(await store.lastSuccessfulBackupAt(), isNull);
        final result = await service.exportSkilltracker();
        expect(result.isFailure, isTrue);
        expect((result as Failure).error.code, 'BACKUP-VERIFY-READ');
        expect(await store.lastSuccessfulBackupAt(), isNull);

        final history = await db.select(db.backupHistory).get();
        expect(history, isNotEmpty);
        expect(history.last.status, 'failed');
        expect(history.last.errorCode, 'BACKUP-VERIFY-READ');
      },
    );

    test('corrupted destination bytes fail verify', () async {
      final files = _CorruptSavedFiles();
      final service = BackupService(
        store: store,
        files: files,
        clock: clock,
        timezones: const FakeTimezoneService(),
        deviceId: () async => db.requireDeviceId(),
        applicationVersion: () async => '0.5.0',
        snapshotsDirectory: () async => 'memory',
        newId: ids.v4,
        platform: 'test',
      );

      final result = await service.exportSkilltracker();
      expect(result.isFailure, isTrue);
      expect(await store.lastSuccessfulBackupAt(), isNull);
      final history = await db.select(db.backupHistory).get();
      expect(history.last.status, 'failed');
    });
  });
}

final class _UnreadableSavedFiles implements BackupFileIo {
  @override
  Future<OpenedBackupFile?> openBackupFile() async => null;

  @override
  Future<String?> pickSavePath({
    required String suggestedName,
    required String extension,
  }) async => null;

  @override
  Future<Uint8List> readBytes(String path) async {
    throw StateError('cannot read $path');
  }

  @override
  Future<String?> saveBytes({
    required Uint8List bytes,
    required String suggestedName,
    required String extension,
    required String mimeType,
    String? relativeDocumentsSubdir,
  }) async => 'memory://unreadable/$suggestedName';
}

final class _CorruptSavedFiles implements BackupFileIo {
  @override
  Future<OpenedBackupFile?> openBackupFile() async => null;

  @override
  Future<String?> pickSavePath({
    required String suggestedName,
    required String extension,
  }) async => null;

  @override
  Future<Uint8List> readBytes(String path) async {
    return Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7]);
  }

  @override
  Future<String?> saveBytes({
    required Uint8List bytes,
    required String suggestedName,
    required String extension,
    required String mimeType,
    String? relativeDocumentsSubdir,
  }) async => 'memory://corrupt/$suggestedName';
}
