import 'package:ayutam/features/backup/domain/backup_models.dart';
import 'package:ayutam/features/backup/presentation/import_preview_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ImportPreview _preview({
  List<ImportConflict> conflicts = const [],
  ActiveSessionCollision? collision,
  bool localHasActive = false,
}) {
  const skillId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  const sessionId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  const skill = BackupSkillRecord(
    id: skillId,
    name: 'Guitar',
    targetSeconds: 36000000,
    createdLocalDate: '2026-01-01',
    status: 'active',
    sortOrder: 0,
    createdAtUtc: 1,
    updatedAtUtc: 1,
    sourceDeviceId: 'device-1234567890abcdef',
  );
  const session = BackupSessionRecord(
    id: sessionId,
    skillId: skillId,
    title: 'Practice',
    mode: 'stopwatch',
    status: 'active',
    source: 'timer',
    startAtUtc: 1000,
    activeSeconds: 30,
    pausedSeconds: 0,
    timezoneIdAtCreation: 'UTC',
    offsetMinutesAtStart: 0,
    createdAtUtc: 1000,
    updatedAtUtc: 2000,
    sourceDeviceId: 'device-1234567890abcdef',
  );
  const payload = BackupPayload(
    dataVersion: 1,
    exportedAtUtc: '2026-08-26T12:00:00.000Z',
    skills: [skill],
    sessions: [session],
    sessionSegments: [],
    tags: [],
    sessionTags: [],
    settings: [],
    deviceMetadata: [],
  );
  const manifest = BackupManifest(
    format: skilltrackerFormat,
    formatVersion: skilltrackerFormatVersion,
    createdAtUtc: '2026-08-26T12:00:00.000Z',
    applicationVersion: '0.5.0',
    databaseSchemaVersion: 3,
    sourcePlatform: 'test',
    sourceDeviceId: 'device-1234567890abcdef',
    timezone: 'UTC',
    encrypted: false,
    compression: 'zip-deflate',
    payloadPath: 'payload/data.json',
    payloadMediaType: 'application/json',
    payloadSha256: 'abc',
    payloadUncompressedBytes: 100,
    summary: BackupSummary(
      skills: 1,
      sessions: 1,
      completedActiveSeconds: 0,
      tags: 0,
      containsActiveOrPendingSession: true,
    ),
  );
  return ImportPreview(
    fileName: 'ayutam-backup.skilltracker',
    manifest: manifest,
    payload: payload,
    checksumOk: true,
    conflicts: conflicts,
    localHasActiveOrPending: localHasActive,
    activeSessionCollision: collision,
  );
}

void main() {
  testWidgets('shows backup metadata and merge/replace consequences', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ImportPreviewSheet(preview: _preview())),
      ),
    );

    expect(find.text('Created'), findsOneWidget);
    expect(find.text('App version'), findsOneWidget);
    expect(find.text('0.5.0'), findsOneWidget);
    expect(find.text('Format version'), findsOneWidget);
    expect(find.text('Checksum'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Encryption'), findsOneWidget);
    expect(find.text('Not encrypted'), findsOneWidget);
    expect(find.text('Device'), findsOneWidget);
    expect(
      find.textContaining('Merge combines records by UUID'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Replace removes all current local data'),
      findsOneWidget,
    );
  });

  testWidgets('disables Merge until active-session decision is chosen', (
    tester,
  ) async {
    const localId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
    const incomingId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
    const skillId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    const collision = ActiveSessionCollision(
      localLive: BackupSessionRecord(
        id: localId,
        skillId: skillId,
        mode: 'stopwatch',
        status: 'active',
        source: 'timer',
        startAtUtc: 1000,
        activeSeconds: 10,
        pausedSeconds: 0,
        timezoneIdAtCreation: 'UTC',
        offsetMinutesAtStart: 0,
        createdAtUtc: 1000,
        updatedAtUtc: 2000,
        sourceDeviceId: 'd',
      ),
      incomingLive: BackupSessionRecord(
        id: incomingId,
        skillId: skillId,
        mode: 'stopwatch',
        status: 'active',
        source: 'timer',
        startAtUtc: 1500,
        activeSeconds: 20,
        pausedSeconds: 0,
        timezoneIdAtCreation: 'UTC',
        offsetMinutesAtStart: 0,
        createdAtUtc: 1500,
        updatedAtUtc: 3000,
        sourceDeviceId: 'd',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImportPreviewSheet(
            preview: _preview(collision: collision, localHasActive: true),
          ),
        ),
      ),
    );

    final mergeButton = find.widgetWithText(FilledButton, 'Merge');
    final button = tester.widget<FilledButton>(mergeButton);
    expect(button.onPressed, isNull);

    await tester.tap(find.text('Keep current'));
    await tester.pumpAndSettle();

    final enabled = tester.widget<FilledButton>(mergeButton);
    expect(enabled.onPressed, isNotNull);
  });

  testWidgets(
    'same-session active collision hides duplicate generic session conflict',
    (tester) async {
      const sharedId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
      const skillId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
      const sharedUpdated = 5000;
      const collision = ActiveSessionCollision(
        localLive: BackupSessionRecord(
          id: sharedId,
          skillId: skillId,
          mode: 'stopwatch',
          status: 'active',
          source: 'timer',
          startAtUtc: 1000,
          activeSeconds: 10,
          pausedSeconds: 0,
          timezoneIdAtCreation: 'UTC',
          offsetMinutesAtStart: 0,
          createdAtUtc: 1000,
          updatedAtUtc: sharedUpdated,
          sourceDeviceId: 'd',
        ),
        incomingLive: BackupSessionRecord(
          id: sharedId,
          skillId: skillId,
          mode: 'stopwatch',
          status: 'active',
          source: 'timer',
          startAtUtc: 1000,
          activeSeconds: 20,
          pausedSeconds: 0,
          timezoneIdAtCreation: 'UTC',
          offsetMinutesAtStart: 0,
          createdAtUtc: 1000,
          updatedAtUtc: sharedUpdated,
          sourceDeviceId: 'd',
        ),
      );
      final preview = ImportPreview(
        fileName: 'ayutam-backup.skilltracker',
        manifest: _preview().manifest,
        payload: _preview().payload,
        checksumOk: true,
        conflicts: const [
          ImportConflict(
            entityType: 'skill',
            id: skillId,
            localUpdatedAtUtc: sharedUpdated,
            incomingUpdatedAtUtc: sharedUpdated,
            label: 'Guitar',
          ),
        ],
        localHasActiveOrPending: true,
        activeSessionCollision: collision,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ImportPreviewSheet(preview: preview)),
        ),
      );

      expect(find.text('Active session conflict'), findsOneWidget);
      expect(find.text('Equal-timestamp conflicts'), findsOneWidget);
      expect(find.text('skill: Guitar'), findsOneWidget);
      expect(find.textContaining('session:'), findsNothing);
      expect(find.text('Complete imported with reviewed end'), findsNothing);
    },
  );

  testWidgets('hides complete-imported option for same-session collision', (
    tester,
  ) async {
    const sharedId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
    const skillId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    const collision = ActiveSessionCollision(
      localLive: BackupSessionRecord(
        id: sharedId,
        skillId: skillId,
        mode: 'stopwatch',
        status: 'active',
        source: 'timer',
        startAtUtc: 1000,
        activeSeconds: 10,
        pausedSeconds: 0,
        timezoneIdAtCreation: 'UTC',
        offsetMinutesAtStart: 0,
        createdAtUtc: 1000,
        updatedAtUtc: 2000,
        sourceDeviceId: 'd',
      ),
      incomingLive: BackupSessionRecord(
        id: sharedId,
        skillId: skillId,
        mode: 'stopwatch',
        status: 'active',
        source: 'timer',
        startAtUtc: 1000,
        activeSeconds: 20,
        pausedSeconds: 0,
        timezoneIdAtCreation: 'UTC',
        offsetMinutesAtStart: 0,
        createdAtUtc: 1000,
        updatedAtUtc: 3000,
        sourceDeviceId: 'd',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImportPreviewSheet(
            preview: _preview(collision: collision, localHasActive: true),
          ),
        ),
      ),
    );

    expect(find.text('Complete imported with reviewed end'), findsNothing);
    expect(
      find.textContaining('share the same in-progress session'),
      findsOneWidget,
    );
  });

  testWidgets('per-item conflict resolution populates choice map', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    ImportPreviewChoice? choice;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    choice = await showImportPreviewSheet(
                      context,
                      preview: _preview(
                        conflicts: const [
                          ImportConflict(
                            entityType: 'skill',
                            id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
                            localUpdatedAtUtc: 100,
                            incomingUpdatedAtUtc: 100,
                            label: 'Guitar',
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('skill: Guitar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Prefer imported').last);
    await tester.tap(find.text('Prefer imported').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Merge'));
    await tester.tap(find.widgetWithText(FilledButton, 'Merge'));
    await tester.pumpAndSettle();

    expect(choice, isNotNull);
    expect(
      choice!.perItem['skill:aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'],
      ConflictResolution.preferImported,
    );
  });
}
