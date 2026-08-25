import 'package:ayutam/core/id/id_generator.dart';
import 'package:ayutam/core/result/result.dart';
import 'package:ayutam/core/time/clock_service.dart';
import 'package:ayutam/core/time/timezone_service.dart';
import 'package:ayutam/database/app_database.dart';
import 'package:ayutam/features/backup/application/backup_service.dart';
import 'package:ayutam/features/backup/application/backup_validator.dart';
import 'package:ayutam/features/backup/application/merge_engine.dart';
import 'package:ayutam/features/backup/application/skilltracker_codec.dart';
import 'package:ayutam/features/backup/data/drift_backup_store.dart';
import 'package:ayutam/features/backup/domain/backup_models.dart';
import 'package:ayutam/features/backup/domain/backup_store.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

final class _MemFiles implements BackupFileIo {
  Uint8List? lastSaved;

  @override
  Future<OpenedBackupFile?> openBackupFile() async => null;

  @override
  Future<String?> pickSavePath({
    required String suggestedName,
    required String extension,
  }) async => null;

  @override
  Future<String?> saveBytes({
    required Uint8List bytes,
    required String suggestedName,
    required String extension,
    required String mimeType,
    String? relativeDocumentsSubdir,
  }) async {
    lastSaved = bytes;
    return 'memory://$suggestedName';
  }
}

final class _CancelFiles implements BackupFileIo {
  @override
  Future<OpenedBackupFile?> openBackupFile() async => null;

  @override
  Future<String?> pickSavePath({
    required String suggestedName,
    required String extension,
  }) async => null;

  @override
  Future<String?> saveBytes({
    required Uint8List bytes,
    required String suggestedName,
    required String extension,
    required String mimeType,
    String? relativeDocumentsSubdir,
  }) async => null;
}

void main() {
  late AppDatabase db;
  late DriftBackupStore store;
  late _MemFiles files;
  late BackupService service;
  late FakeClockService clock;
  late UuidIdGenerator ids;

  setUp(() async {
    clock = FakeClockService(initialUtc: DateTime.utc(2026, 8, 26, 12));
    ids = const UuidIdGenerator();
    db = AppDatabase.memory(clock: clock, ids: ids);
    await db.ensureSeeded(clock: clock, ids: ids);
    store = DriftBackupStore(db);
    files = _MemFiles();
    service = BackupService(
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
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedSkillSession({
    required String skillId,
    required String sessionId,
    int active = 120,
    String status = 'completed',
  }) async {
    final now = clock.nowUtc().millisecondsSinceEpoch;
    final device = await db.requireDeviceId();
    await db
        .into(db.skills)
        .insert(
          SkillsCompanion.insert(
            id: skillId,
            name: 'Guitar',
            createdLocalDate: '2026-01-01',
            createdAtUtc: now,
            updatedAtUtc: now,
            sourceDeviceId: device,
          ),
        );
    await db
        .into(db.sessions)
        .insert(
          SessionsCompanion.insert(
            id: sessionId,
            skillId: skillId,
            status: status,
            startAtUtc: now - 120000,
            endAtUtc: Value(status == 'completed' ? now : null),
            activeSeconds: Value(active),
            timezoneIdAtCreation: 'UTC',
            offsetMinutesAtStart: 0,
            createdAtUtc: now,
            updatedAtUtc: now,
            sourceDeviceId: device,
          ),
        );
    await db
        .into(db.sessionSegments)
        .insert(
          SessionSegmentsCompanion.insert(
            id: '33333333-3333-4333-8333-${sessionId.substring(24)}',
            sessionId: sessionId,
            segmentType: 'work',
            startAtUtc: now - 120000,
            endAtUtc: Value(now),
            durationSeconds: Value(active),
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
  }

  test('empty DB export/import replace round-trip', () async {
    final exported = await service.exportSkilltrackerBytes();
    expect(exported.isSuccess, isTrue);
    final zip = exported.valueOrNull!;

    final preview = await service.previewImportBytes(
      bytes: zip,
      fileName: 'empty.skilltracker',
    );
    expect(preview.isSuccess, isTrue);
    final applied = await service.applyImport(
      preview: preview.valueOrNull!,
      mode: ImportMode.replace,
    );
    expect(applied.isSuccess, isTrue);
    expect(await db.select(db.skills).get(), isEmpty);
  });

  test('round-trip preserves skill/session/segment/note', () async {
    const skillId = '11111111-1111-4111-8111-111111111111';
    const sessionId = '22222222-2222-4222-8222-222222222222';
    await seedSkillSession(skillId: skillId, sessionId: sessionId);
    await (db.update(db.sessions)..where((t) => t.id.equals(sessionId))).write(
      const SessionsCompanion(noteMarkdown: Value('Hello 🎸\n```dart\nx\n```')),
    );

    final zip = (await service.exportSkilltrackerBytes()).valueOrNull!;
    await db.delete(db.sessionSegments).go();
    await db.delete(db.sessions).go();
    await db.delete(db.skills).go();

    final preview = (await service.previewImportBytes(
      bytes: zip,
      fileName: 'full.skilltracker',
    )).valueOrNull!;
    expect(
      (await service.applyImport(
        preview: preview,
        mode: ImportMode.replace,
      )).isSuccess,
      isTrue,
    );

    final skill = await (db.select(
      db.skills,
    )..where((t) => t.id.equals(skillId))).getSingle();
    expect(skill.name, 'Guitar');
    final session = await (db.select(
      db.sessions,
    )..where((t) => t.id.equals(sessionId))).getSingle();
    expect(session.noteMarkdown, contains('🎸'));
    expect(session.noteMarkdown, contains('```dart'));
    expect(session.activeSeconds, 120);
    expect(await db.select(db.sessionSegments).get(), hasLength(1));
  });

  test('corrupt payload byte is rejected with no mutation', () async {
    const skillId = '11111111-1111-4111-8111-111111111111';
    const sessionId = '22222222-2222-4222-8222-222222222222';
    await seedSkillSession(skillId: skillId, sessionId: sessionId);
    final zip = (await service.exportSkilltrackerBytes()).valueOrNull!;
    final corrupted = Uint8List.fromList(zip);
    corrupted[corrupted.length ~/ 2] ^= 0xff;

    final before = await db.select(db.skills).get();
    final preview = await service.previewImportBytes(
      bytes: corrupted,
      fileName: 'bad.skilltracker',
    );
    expect(preview.isFailure, isTrue);
    expect(await db.select(db.skills).get(), hasLength(before.length));
  });

  test('missing skill reference rejected', () {
    const payload = BackupPayload(
      dataVersion: 1,
      exportedAtUtc: '2026-08-26T00:00:00.000Z',
      skills: [],
      sessions: [
        BackupSessionRecord(
          id: '22222222-2222-4222-8222-222222222222',
          skillId: '11111111-1111-4111-8111-111111111111',
          mode: 'stopwatch',
          status: 'completed',
          source: 'timer',
          startAtUtc: 1,
          endAtUtc: 2,
          activeSeconds: 1,
          pausedSeconds: 0,
          timezoneIdAtCreation: 'UTC',
          offsetMinutesAtStart: 0,
          createdAtUtc: 1,
          updatedAtUtc: 1,
          sourceDeviceId: 'd',
        ),
      ],
      sessionSegments: [],
      tags: [],
      sessionTags: [],
      settings: [],
      deviceMetadata: [],
    );
    final result = validateBackupPayload(payload);
    expect(result.isFailure, isTrue);
    expect((result as Failure).error.code, 'BACKUP-FK');
  });

  test('newer format rejected', () {
    const codec = SkilltrackerCodec();
    const payload = BackupPayload(
      dataVersion: 1,
      exportedAtUtc: '2026-08-26T00:00:00.000Z',
      skills: [],
      sessions: [],
      sessionSegments: [],
      tags: [],
      sessionTags: [],
      settings: [],
      deviceMetadata: [],
    );
    final bytes = encodePayloadBytes(payload);
    final zip = codec.encode(
      manifestWithoutPayloadHash: BackupManifest(
        format: skilltrackerFormat,
        formatVersion: 99,
        createdAtUtc: '2026-08-26T00:00:00.000Z',
        applicationVersion: '9.0.0',
        databaseSchemaVersion: 3,
        sourcePlatform: 'test',
        sourceDeviceId: 'd',
        timezone: 'UTC',
        encrypted: false,
        compression: 'zip-deflate',
        payloadPath: 'payload/data.json',
        payloadMediaType: 'application/json',
        payloadSha256: '',
        payloadUncompressedBytes: bytes.length,
        summary: payload.computeSummary(),
      ),
      payloadJsonBytes: bytes,
    );
    expect(codec.decode(zip, fileName: 'new.skilltracker').isFailure, isTrue);
  });

  test('merge divergent UUIDs keeps both; same UUID newest wins', () async {
    const skillA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    const skillB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
    const sessionOld = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
    const sessionNew = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
    final now = clock.nowUtc().millisecondsSinceEpoch;
    final device = await db.requireDeviceId();
    await db
        .into(db.skills)
        .insert(
          SkillsCompanion.insert(
            id: skillA,
            name: 'Local',
            createdLocalDate: '2026-01-01',
            createdAtUtc: now,
            updatedAtUtc: now,
            sourceDeviceId: device,
          ),
        );
    await db
        .into(db.sessions)
        .insert(
          SessionsCompanion.insert(
            id: sessionOld,
            skillId: skillA,
            status: 'completed',
            title: const Value('old title'),
            startAtUtc: now,
            endAtUtc: Value(now),
            activeSeconds: const Value(10),
            timezoneIdAtCreation: 'UTC',
            offsetMinutesAtStart: 0,
            createdAtUtc: now,
            updatedAtUtc: now,
            sourceDeviceId: device,
          ),
        );

    final incoming = BackupPayload(
      dataVersion: 1,
      exportedAtUtc: '2026-08-26T00:00:00.000Z',
      skills: [
        BackupSkillRecord(
          id: skillA,
          name: 'Local renamed',
          targetSeconds: 36000000,
          createdLocalDate: '2026-01-01',
          status: 'active',
          sortOrder: 0,
          createdAtUtc: now,
          updatedAtUtc: now + 1000,
          sourceDeviceId: 'other',
        ),
        BackupSkillRecord(
          id: skillB,
          name: 'Incoming only',
          targetSeconds: 36000000,
          createdLocalDate: '2026-01-01',
          status: 'active',
          sortOrder: 0,
          createdAtUtc: now,
          updatedAtUtc: now,
          sourceDeviceId: 'other',
        ),
      ],
      sessions: [
        BackupSessionRecord(
          id: sessionOld,
          skillId: skillA,
          title: 'new title',
          mode: 'stopwatch',
          status: 'completed',
          source: 'timer',
          startAtUtc: now,
          endAtUtc: now,
          activeSeconds: 10,
          pausedSeconds: 0,
          timezoneIdAtCreation: 'UTC',
          offsetMinutesAtStart: 0,
          createdAtUtc: now,
          updatedAtUtc: now + 1000,
          sourceDeviceId: 'other',
        ),
        BackupSessionRecord(
          id: sessionNew,
          skillId: skillB,
          mode: 'stopwatch',
          status: 'completed',
          source: 'timer',
          startAtUtc: now,
          endAtUtc: now,
          activeSeconds: 5,
          pausedSeconds: 0,
          timezoneIdAtCreation: 'UTC',
          offsetMinutesAtStart: 0,
          createdAtUtc: now,
          updatedAtUtc: now,
          sourceDeviceId: 'other',
        ),
      ],
      sessionSegments: const [],
      tags: const [],
      sessionTags: const [],
      settings: const [],
      deviceMetadata: const [],
    );

    final local = await store.readPayload();
    final merged = const MergeEngine().merge(local: local, incoming: incoming);
    await store.applyMerged(merged.payload);

    final skills = await db.select(db.skills).get();
    expect(skills.map((s) => s.id).toSet(), {skillA, skillB});
    expect(skills.firstWhere((s) => s.id == skillA).name, 'Local renamed');
    final sessions = await db.select(db.sessions).get();
    expect(sessions.map((s) => s.id).toSet(), {sessionOld, sessionNew});
    expect(sessions.firstWhere((s) => s.id == sessionOld).title, 'new title');
  });

  test('lastSuccessfulBackupAt only updates after verify', () async {
    expect(await store.lastSuccessfulBackupAt(), isNull);
    final cancelService = BackupService(
      store: store,
      files: _CancelFiles(),
      clock: clock,
      timezones: const FakeTimezoneService(),
      deviceId: () async => db.requireDeviceId(),
      applicationVersion: () async => '0.5.0',
      snapshotsDirectory: () async => 'memory',
      newId: ids.v4,
      platform: 'test',
    );
    expect((await cancelService.exportSkilltracker()).isFailure, isTrue);
    expect(await store.lastSuccessfulBackupAt(), isNull);

    expect((await service.exportSkilltrackerBytes()).isSuccess, isTrue);
    expect(await store.lastSuccessfulBackupAt(), isNotNull);
  });

  test('same backup twice does not duplicate on merge', () async {
    const skillId = '11111111-1111-4111-8111-111111111111';
    const sessionId = '22222222-2222-4222-8222-222222222222';
    await seedSkillSession(skillId: skillId, sessionId: sessionId);
    final zip = (await service.exportSkilltrackerBytes()).valueOrNull!;
    final preview = (await service.previewImportBytes(
      bytes: zip,
      fileName: 'dup.skilltracker',
    )).valueOrNull!;
    await service.applyImport(preview: preview, mode: ImportMode.merge);
    await service.applyImport(preview: preview, mode: ImportMode.merge);
    expect(await db.select(db.skills).get(), hasLength(1));
    expect(await db.select(db.sessions).get(), hasLength(1));
  });
}
