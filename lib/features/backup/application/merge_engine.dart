import '../domain/backup_models.dart';
import '../domain/session_completion.dart';

enum _MergeSide { local, incoming }

/// Last-write-wins merge of two portable payloads (ADR-012).
///
/// Identity is UUID only. Equal `updatedAt` with different content yields
/// [ImportConflict] items; [ConflictResolution] selects the winner.
///
/// When both sides have a live (active/paused/completion_pending) session,
/// merge does **not** auto-resolve — [MergedPayload.activeSessionCollision]
/// is set and [activeDecision] is required before a safe apply.
final class MergeEngine {
  const MergeEngine();

  /// Detects whether both local and incoming payloads contain a live session.
  ActiveSessionCollision? detectActiveCollision({
    required BackupPayload local,
    required BackupPayload incoming,
  }) {
    final localLive = _liveSessions(local.sessions);
    final incomingLive = _liveSessions(incoming.sessions);
    if (localLive.isEmpty || incomingLive.isEmpty) return null;
    return ActiveSessionCollision(
      localLive: localLive.first,
      incomingLive: incomingLive.first,
      localLiveCount: localLive.length,
      incomingLiveCount: incomingLive.length,
    );
  }

  MergedPayload merge({
    required BackupPayload local,
    required BackupPayload incoming,
    ConflictResolution defaultResolution = ConflictResolution.keepCurrent,
    Map<String, ConflictResolution> perItem = const {},
    ActiveSessionDecision? activeDecision,
    int? reviewedEndAtUtc,
    int? nowUtcMs,
  }) {
    final conflicts = <ImportConflict>[];
    final collision = detectActiveCollision(local: local, incoming: incoming);

    if (collision != null && activeDecision == ActiveSessionDecision.cancel) {
      return MergedPayload(
        payload: local,
        conflicts: const [],
        activeSessionCollision: collision,
        cancelled: true,
      );
    }

    final needsDecision = collision != null && activeDecision == null;
    final suppressedSessionConflictId = collision?.sameSessionId == true
        ? collision!.localLive.id
        : null;

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

    final sessionMerge = _mergeByIdWithSide(
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
      suppressGenericConflictId: suppressedSessionConflictId,
    );
    var sessions = List<BackupSessionRecord>.from(sessionMerge.items);
    final sessionSources = Map<String, _MergeSide>.from(sessionMerge.sides);

    if (!needsDecision && collision != null && activeDecision != null) {
      sessions = _applyActiveDecision(
        sessions: sessions,
        sessionSources: sessionSources,
        local: local,
        incoming: incoming,
        collision: collision,
        decision: activeDecision,
        reviewedEndAtUtc: reviewedEndAtUtc,
        nowUtcMs: nowUtcMs,
      );
    }

    // Child data follows the winning session wholesale — never union losers.
    final tagIdSet = tags.map((t) => t.id).toSet();
    var segments = <BackupSegmentRecord>[];
    final sessionTags = <BackupSessionTagRecord>[];
    for (final session in sessions) {
      final side = sessionSources[session.id] ?? _MergeSide.local;
      final sourceSegs = side == _MergeSide.incoming
          ? incoming.sessionSegments
          : local.sessionSegments;
      final sourceLinks = side == _MergeSide.incoming
          ? incoming.sessionTags
          : local.sessionTags;
      segments.addAll(sourceSegs.where((s) => s.sessionId == session.id));
      for (final link in sourceLinks.where((l) => l.sessionId == session.id)) {
        if (tagIdSet.contains(link.tagId)) {
          sessionTags.add(link);
        }
      }
    }

    if (collision != null &&
        activeDecision == ActiveSessionDecision.completeOtherWithEnd &&
        reviewedEndAtUtc != null &&
        !collision.sameSessionId) {
      final incomingId = collision.incomingLive.id;
      final session = sessions.singleWhere((s) => s.id == incomingId);
      final sessionSegs = segments
          .where((segment) => segment.sessionId == incomingId)
          .toList();
      final reconciled = BackupSessionCompletion.completeSessionAt(
        session: session,
        sessionSegments: sessionSegs,
        endAtUtc: reviewedEndAtUtc,
        nowUtcMs: nowUtcMs ?? reviewedEndAtUtc,
      );
      sessions = sessions
          .map((s) => s.id == incomingId ? reconciled.session : s)
          .toList();
      segments = [
        ...segments.where((segment) => segment.sessionId != incomingId),
        ...reconciled.segments,
      ];
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

    final merged = BackupPayload(
      dataVersion: skilltrackerDataVersion,
      exportedAtUtc: incoming.exportedAtUtc,
      skills: skills,
      sessions: sessions,
      sessionSegments: segments,
      tags: tags,
      sessionTags: sessionTags,
      settings: settings,
      deviceMetadata: devices,
      timerRuntime: null,
      backupMetadata: incoming.backupMetadata ?? local.backupMetadata,
    );

    return MergedPayload(
      payload: merged,
      conflicts: conflicts,
      activeSessionCollision: collision,
      cancelled: false,
    );
  }

  List<BackupSessionRecord> _applyActiveDecision({
    required List<BackupSessionRecord> sessions,
    required Map<String, _MergeSide> sessionSources,
    required BackupPayload local,
    required BackupPayload incoming,
    required ActiveSessionCollision collision,
    required ActiveSessionDecision decision,
    required int? reviewedEndAtUtc,
    required int? nowUtcMs,
  }) {
    final localId = collision.localLive.id;
    final incomingId = collision.incomingLive.id;
    final byId = {for (final s in sessions) s.id: s};

    void put(BackupSessionRecord session, _MergeSide side) {
      byId[session.id] = session;
      sessionSources[session.id] = side;
    }

    switch (decision) {
      case ActiveSessionDecision.keepCurrent:
        put(collision.localLive, _MergeSide.local);
        if (localId != incomingId) {
          byId.remove(incomingId);
          for (final s in incoming.sessions) {
            if (s.id == incomingId && !_isLive(s)) {
              put(s, _MergeSide.incoming);
            }
          }
        }
        break;
      case ActiveSessionDecision.preferImported:
        put(collision.incomingLive, _MergeSide.incoming);
        if (localId != incomingId) {
          byId.remove(localId);
          for (final s in local.sessions) {
            if (s.id == localId && !_isLive(s)) {
              put(s, _MergeSide.local);
            }
          }
        }
        break;
      case ActiveSessionDecision.completeOtherWithEnd:
        if (collision.sameSessionId) {
          throw ArgumentError(
            'completeOtherWithEnd is not valid when both sides share the '
            'same live session id',
          );
        }
        if (reviewedEndAtUtc == null) {
          throw ArgumentError(
            'reviewedEndAtUtc is required for completeOtherWithEnd',
          );
        }
        BackupSessionCompletion.validateReviewedEnd(
          startAtUtc: collision.incomingLive.startAtUtc,
          endAtUtc: reviewedEndAtUtc,
          nowUtcMs: nowUtcMs ?? reviewedEndAtUtc,
        );
        put(collision.localLive, _MergeSide.local);
        put(
          collision.incomingLive.copyWith(
            status: 'completed',
            endAtUtc: reviewedEndAtUtc,
          ),
          _MergeSide.incoming,
        );
        break;
      case ActiveSessionDecision.cancel:
        break;
    }

    final list = byId.values.toList();
    final live = list.where(_isLive).toList();
    if (live.length > 1) {
      throw StateError(
        'Active-session decision left ${live.length} live sessions',
      );
    }
    return list;
  }

  static bool _isLive(BackupSessionRecord s) =>
      s.deletedAtUtc == null &&
      (s.status == 'active' ||
          s.status == 'paused' ||
          s.status == 'completion_pending');

  static List<BackupSessionRecord> _liveSessions(
    List<BackupSessionRecord> sessions,
  ) => sessions.where(_isLive).toList();

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
    return _mergeByIdWithSide(
      local: local,
      incoming: incoming,
      idOf: idOf,
      updatedOf: updatedOf,
      hashOf: hashOf,
      labelOf: labelOf,
      entityType: entityType,
      conflicts: conflicts,
      defaultResolution: defaultResolution,
      perItem: perItem,
    ).items;
  }

  ({List<T> items, Map<String, _MergeSide> sides}) _mergeByIdWithSide<T>({
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
    String? suppressGenericConflictId,
  }) {
    final localMap = {for (final item in local) idOf(item): item};
    final incomingMap = {for (final item in incoming) idOf(item): item};
    final ids = {...localMap.keys, ...incomingMap.keys};
    final out = <T>[];
    final sides = <String, _MergeSide>{};
    for (final id in ids) {
      final loc = localMap[id];
      final inc = incomingMap[id];
      if (loc == null) {
        out.add(inc as T);
        sides[id] = _MergeSide.incoming;
        continue;
      }
      if (inc == null) {
        out.add(loc);
        sides[id] = _MergeSide.local;
        continue;
      }
      if (hashOf(loc) == hashOf(inc)) {
        out.add(loc);
        sides[id] = _MergeSide.local;
        continue;
      }
      final locUpdated = updatedOf(loc);
      final incUpdated = updatedOf(inc);
      if (incUpdated > locUpdated) {
        out.add(inc);
        sides[id] = _MergeSide.incoming;
      } else if (locUpdated > incUpdated) {
        out.add(loc);
        sides[id] = _MergeSide.local;
      } else {
        final suppressGeneric =
            suppressGenericConflictId != null &&
            id == suppressGenericConflictId;
        if (!suppressGeneric) {
          conflicts.add(
            ImportConflict(
              entityType: entityType,
              id: id,
              localUpdatedAtUtc: locUpdated,
              incomingUpdatedAtUtc: incUpdated,
              label: labelOf(loc),
            ),
          );
        }
        final resolution = suppressGeneric
            ? ConflictResolution.keepCurrent
            : (perItem['$entityType:$id'] ?? defaultResolution);
        if (resolution == ConflictResolution.preferImported) {
          out.add(inc);
          sides[id] = _MergeSide.incoming;
        } else {
          out.add(loc);
          sides[id] = _MergeSide.local;
        }
      }
    }
    return (items: out, sides: sides);
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

extension on BackupSessionRecord {
  BackupSessionRecord copyWith({
    String? status,
    int? endAtUtc,
    int? activeSeconds,
    int? pausedSeconds,
    int? updatedAtUtc,
  }) {
    return BackupSessionRecord(
      id: id,
      skillId: skillId,
      title: title,
      noteMarkdown: noteMarkdown,
      mode: mode,
      status: status ?? this.status,
      source: source,
      startAtUtc: startAtUtc,
      endAtUtc: endAtUtc ?? this.endAtUtc,
      activeSeconds: activeSeconds ?? this.activeSeconds,
      pausedSeconds: pausedSeconds ?? this.pausedSeconds,
      timezoneIdAtCreation: timezoneIdAtCreation,
      offsetMinutesAtStart: offsetMinutesAtStart,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      sourceDeviceId: sourceDeviceId,
      deletedAtUtc: deletedAtUtc,
    );
  }
}

final class MergedPayload {
  const MergedPayload({
    required this.payload,
    required this.conflicts,
    this.activeSessionCollision,
    this.cancelled = false,
  });

  final BackupPayload payload;
  final List<ImportConflict> conflicts;
  final ActiveSessionCollision? activeSessionCollision;
  final bool cancelled;

  bool get requiresActiveSessionDecision =>
      activeSessionCollision != null && !cancelled;
}
