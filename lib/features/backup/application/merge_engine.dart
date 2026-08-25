import '../domain/backup_models.dart';

/// Last-write-wins merge of two portable payloads (ADR-012).
///
/// Identity is UUID only. Equal `updatedAt` with different content yields
/// [ImportConflict] items; [ConflictResolution] selects the winner.
final class MergeEngine {
  const MergeEngine();

  MergedPayload merge({
    required BackupPayload local,
    required BackupPayload incoming,
    ConflictResolution defaultResolution = ConflictResolution.keepCurrent,
    Map<String, ConflictResolution> perItem = const {},
  }) {
    final conflicts = <ImportConflict>[];

    final skills = _mergeById(
      local: local.skills,
      incoming: incoming.skills,
      idOf: (s) => s.id,
      updatedOf: (s) => s.updatedAtUtc,
      hashOf: (s) => s.toJson().toString(),
      labelOf: (s) => s.name,
      entityType: 'skill',
      conflicts: conflicts,
      defaultResolution: defaultResolution,
      perItem: perItem,
    );

    final tags = _mergeById(
      local: local.tags,
      incoming: incoming.tags,
      idOf: (t) => t.id,
      updatedOf: (t) => t.updatedAtUtc,
      hashOf: (t) => t.toJson().toString(),
      labelOf: (t) => t.name,
      entityType: 'tag',
      conflicts: conflicts,
      defaultResolution: defaultResolution,
      perItem: perItem,
    );

    final sessions = _mergeById(
      local: local.sessions,
      incoming: incoming.sessions,
      idOf: (s) => s.id,
      updatedOf: (s) => s.updatedAtUtc,
      hashOf: (s) => s.toJson().toString(),
      labelOf: (s) => s.title ?? s.id,
      entityType: 'session',
      conflicts: conflicts,
      defaultResolution: defaultResolution,
      perItem: perItem,
    );

    // Segments: prefer the version belonging to the winning session wholesale.
    final sessionIds = sessions.map((s) => s.id).toSet();
    final localSegs = {
      for (final s in local.sessionSegments)
        if (sessionIds.contains(s.sessionId)) s.id: s,
    };
    final incomingSegs = {
      for (final s in incoming.sessionSegments)
        if (sessionIds.contains(s.sessionId)) s.id: s,
    };
    final winningSessionUpdated = {
      for (final s in sessions) s.id: s.updatedAtUtc,
    };
    final localSessionUpdated = {
      for (final s in local.sessions) s.id: s.updatedAtUtc,
    };
    final segments = <BackupSegmentRecord>[];
    final allSegIds = {...localSegs.keys, ...incomingSegs.keys};
    for (final id in allSegIds) {
      final loc = localSegs[id];
      final inc = incomingSegs[id];
      if (loc == null) {
        segments.add(inc!);
        continue;
      }
      if (inc == null) {
        segments.add(loc);
        continue;
      }
      final sessionId = loc.sessionId;
      final winUpdated = winningSessionUpdated[sessionId] ?? 0;
      final localUpdated = localSessionUpdated[sessionId] ?? 0;
      segments.add(winUpdated > localUpdated ? inc : loc);
    }

    final settings = _mergeSettings(
      local: local.settings,
      incoming: incoming.settings,
      conflicts: conflicts,
      defaultResolution: defaultResolution,
      perItem: perItem,
    );

    final devices = _mergeDevices(
      local.deviceMetadata,
      incoming.deviceMetadata,
    );

    final sessionTagKeys = <String>{};
    final sessionTags = <BackupSessionTagRecord>[];
    final tagIdSet = tags.map((t) => t.id).toSet();
    for (final link in [...local.sessionTags, ...incoming.sessionTags]) {
      if (!sessionIds.contains(link.sessionId) ||
          !tagIdSet.contains(link.tagId)) {
        continue;
      }
      final key = '${link.sessionId}|${link.tagId}';
      if (sessionTagKeys.add(key)) {
        sessionTags.add(link);
      }
    }

    // Active-session invariant: at most one live session after merge.
    final live = sessions
        .where(
          (s) =>
              s.deletedAtUtc == null &&
              (s.status == 'active' ||
                  s.status == 'paused' ||
                  s.status == 'completion_pending'),
        )
        .toList();
    var resolvedSessions = sessions;
    if (live.length > 1) {
      // Prefer local live session; demote others to completed.
      final localLiveIds = local.sessions
          .where(
            (s) =>
                s.deletedAtUtc == null &&
                (s.status == 'active' ||
                    s.status == 'paused' ||
                    s.status == 'completion_pending'),
          )
          .map((s) => s.id)
          .toSet();
      final keepId = live
          .firstWhere(
            (s) => localLiveIds.contains(s.id),
            orElse: () => live.first,
          )
          .id;
      resolvedSessions = sessions.map((s) {
        if (s.id == keepId) return s;
        if (s.deletedAtUtc == null &&
            (s.status == 'active' ||
                s.status == 'paused' ||
                s.status == 'completion_pending')) {
          return BackupSessionRecord(
            id: s.id,
            skillId: s.skillId,
            title: s.title,
            noteMarkdown: s.noteMarkdown,
            mode: s.mode,
            status: 'completed',
            source: s.source,
            startAtUtc: s.startAtUtc,
            endAtUtc: s.endAtUtc ?? s.startAtUtc,
            activeSeconds: s.activeSeconds,
            pausedSeconds: s.pausedSeconds,
            timezoneIdAtCreation: s.timezoneIdAtCreation,
            offsetMinutesAtStart: s.offsetMinutesAtStart,
            createdAtUtc: s.createdAtUtc,
            updatedAtUtc: s.updatedAtUtc,
            sourceDeviceId: s.sourceDeviceId,
            deletedAtUtc: s.deletedAtUtc,
          );
        }
        return s;
      }).toList();
    }

    final merged = BackupPayload(
      dataVersion: skilltrackerDataVersion,
      exportedAtUtc: incoming.exportedAtUtc,
      skills: skills,
      sessions: resolvedSessions,
      sessionSegments: segments,
      tags: tags,
      sessionTags: sessionTags,
      settings: settings,
      deviceMetadata: devices,
      timerRuntime: null, // rebuilt by store after apply
      backupMetadata: incoming.backupMetadata ?? local.backupMetadata,
    );

    return MergedPayload(payload: merged, conflicts: conflicts);
  }

  List<T> _mergeById<T>({
    required List<T> local,
    required List<T> incoming,
    required String Function(T) idOf,
    required int Function(T) updatedOf,
    required String Function(T) hashOf,
    required String Function(T) labelOf,
    required String entityType,
    required List<ImportConflict> conflicts,
    required ConflictResolution defaultResolution,
    required Map<String, ConflictResolution> perItem,
  }) {
    final localMap = {for (final item in local) idOf(item): item};
    final incomingMap = {for (final item in incoming) idOf(item): item};
    final ids = {...localMap.keys, ...incomingMap.keys};
    final out = <T>[];
    for (final id in ids) {
      final loc = localMap[id];
      final inc = incomingMap[id];
      if (loc == null) {
        out.add(inc as T);
        continue;
      }
      if (inc == null) {
        out.add(loc);
        continue;
      }
      if (hashOf(loc) == hashOf(inc)) {
        out.add(loc);
        continue;
      }
      final locUpdated = updatedOf(loc);
      final incUpdated = updatedOf(inc);
      if (incUpdated > locUpdated) {
        out.add(inc);
      } else if (locUpdated > incUpdated) {
        out.add(loc);
      } else {
        conflicts.add(
          ImportConflict(
            entityType: entityType,
            id: id,
            localUpdatedAtUtc: locUpdated,
            incomingUpdatedAtUtc: incUpdated,
            label: labelOf(loc),
          ),
        );
        final resolution = perItem['$entityType:$id'] ?? defaultResolution;
        out.add(resolution == ConflictResolution.preferImported ? inc : loc);
      }
    }
    return out;
  }

  List<BackupSettingRecord> _mergeSettings({
    required List<BackupSettingRecord> local,
    required List<BackupSettingRecord> incoming,
    required List<ImportConflict> conflicts,
    required ConflictResolution defaultResolution,
    required Map<String, ConflictResolution> perItem,
  }) {
    final localMap = {
      for (final s in local)
        if (mergeableSettingsKeys.contains(s.key)) s.key: s,
    };
    final incomingMap = {
      for (final s in incoming)
        if (mergeableSettingsKeys.contains(s.key)) s.key: s,
    };
    // Preserve non-mergeable local settings untouched by adding them later in store.
    final keys = {...localMap.keys, ...incomingMap.keys};
    final out = <BackupSettingRecord>[];
    for (final key in keys) {
      final loc = localMap[key];
      final inc = incomingMap[key];
      if (loc == null) {
        out.add(inc!);
        continue;
      }
      if (inc == null) {
        out.add(loc);
        continue;
      }
      if (loc.valueJson == inc.valueJson) {
        out.add(loc);
        continue;
      }
      if (inc.updatedAtUtc > loc.updatedAtUtc) {
        out.add(inc);
      } else if (loc.updatedAtUtc > inc.updatedAtUtc) {
        out.add(loc);
      } else {
        conflicts.add(
          ImportConflict(
            entityType: 'setting',
            id: key,
            localUpdatedAtUtc: loc.updatedAtUtc,
            incomingUpdatedAtUtc: inc.updatedAtUtc,
            label: key,
          ),
        );
        final resolution = perItem['setting:$key'] ?? defaultResolution;
        out.add(resolution == ConflictResolution.preferImported ? inc : loc);
      }
    }
    return out;
  }

  List<BackupDeviceRecord> _mergeDevices(
    List<BackupDeviceRecord> local,
    List<BackupDeviceRecord> incoming,
  ) {
    final map = {for (final d in local) d.deviceId: d};
    for (final d in incoming) {
      map.putIfAbsent(d.deviceId, () => d);
    }
    return map.values.toList();
  }
}

final class MergedPayload {
  const MergedPayload({required this.payload, required this.conflicts});

  final BackupPayload payload;
  final List<ImportConflict> conflicts;
}
