// Portable backup payload and import preview models (ADR-004 / backup-format.md).

const skilltrackerFormat = 'ayutam-portable-backup';
const skilltrackerFormatVersion = 1;
const skilltrackerDataVersion = 1;
const portableJsonFormat = 'ayutam-portable-json';
const portableJsonFormatVersion = 1;

/// Maximum accepted `.skilltracker` file size (bytes).
const maxSkilltrackerBytes = 200 * 1024 * 1024;

/// Maximum uncompressed payload JSON size (bytes).
const maxPayloadUncompressedBytes = 400 * 1024 * 1024;

final class BackupManifest {
  const BackupManifest({
    required this.format,
    required this.formatVersion,
    required this.createdAtUtc,
    required this.applicationVersion,
    required this.databaseSchemaVersion,
    required this.sourcePlatform,
    required this.sourceDeviceId,
    required this.timezone,
    required this.encrypted,
    required this.compression,
    required this.payloadPath,
    required this.payloadMediaType,
    required this.payloadSha256,
    required this.payloadUncompressedBytes,
    required this.summary,
  });

  final String format;
  final int formatVersion;
  final String createdAtUtc;
  final String applicationVersion;
  final int databaseSchemaVersion;
  final String sourcePlatform;
  final String sourceDeviceId;
  final String timezone;
  final bool encrypted;
  final String compression;
  final String payloadPath;
  final String payloadMediaType;
  final String payloadSha256;
  final int payloadUncompressedBytes;
  final BackupSummary summary;

  Map<String, Object?> toJson() => {
    'format': format,
    'formatVersion': formatVersion,
    'createdAtUtc': createdAtUtc,
    'applicationVersion': applicationVersion,
    'databaseSchemaVersion': databaseSchemaVersion,
    'sourcePlatform': sourcePlatform,
    'sourceDeviceId': sourceDeviceId,
    'timezone': timezone,
    'encrypted': encrypted,
    'compression': compression,
    'payload': {
      'path': payloadPath,
      'mediaType': payloadMediaType,
      'sha256': payloadSha256,
      'uncompressedBytes': payloadUncompressedBytes,
    },
    'summary': summary.toJson(),
    'encryption': null,
  };

  factory BackupManifest.fromJson(Map<String, Object?> json) {
    final payload = (json['payload'] as Map?)?.cast<String, Object?>() ?? {};
    final summaryRaw = (json['summary'] as Map?)?.cast<String, Object?>() ?? {};
    return BackupManifest(
      format: json['format'] as String? ?? '',
      formatVersion: (json['formatVersion'] as num?)?.toInt() ?? 0,
      createdAtUtc: json['createdAtUtc'] as String? ?? '',
      applicationVersion: json['applicationVersion'] as String? ?? '',
      databaseSchemaVersion:
          (json['databaseSchemaVersion'] as num?)?.toInt() ?? 0,
      sourcePlatform: json['sourcePlatform'] as String? ?? '',
      sourceDeviceId: json['sourceDeviceId'] as String? ?? '',
      timezone: json['timezone'] as String? ?? '',
      encrypted: json['encrypted'] as bool? ?? false,
      compression: json['compression'] as String? ?? '',
      payloadPath: payload['path'] as String? ?? 'payload/data.json',
      payloadMediaType: payload['mediaType'] as String? ?? 'application/json',
      payloadSha256: payload['sha256'] as String? ?? '',
      payloadUncompressedBytes:
          (payload['uncompressedBytes'] as num?)?.toInt() ?? 0,
      summary: BackupSummary.fromJson(summaryRaw),
    );
  }
}

final class BackupSummary {
  const BackupSummary({
    required this.skills,
    required this.sessions,
    required this.completedActiveSeconds,
    required this.tags,
    required this.containsActiveOrPendingSession,
  });

  final int skills;
  final int sessions;
  final int completedActiveSeconds;
  final int tags;
  final bool containsActiveOrPendingSession;

  Map<String, Object?> toJson() => {
    'skills': skills,
    'sessions': sessions,
    'completedActiveSeconds': completedActiveSeconds,
    'tags': tags,
    'containsActiveOrPendingSession': containsActiveOrPendingSession,
  };

  factory BackupSummary.fromJson(Map<String, Object?> json) {
    return BackupSummary(
      skills: (json['skills'] as num?)?.toInt() ?? 0,
      sessions: (json['sessions'] as num?)?.toInt() ?? 0,
      completedActiveSeconds:
          (json['completedActiveSeconds'] as num?)?.toInt() ?? 0,
      tags: (json['tags'] as num?)?.toInt() ?? 0,
      containsActiveOrPendingSession:
          json['containsActiveOrPendingSession'] as bool? ?? false,
    );
  }
}

final class BackupPayload {
  const BackupPayload({
    required this.dataVersion,
    required this.exportedAtUtc,
    required this.skills,
    required this.sessions,
    required this.sessionSegments,
    required this.tags,
    required this.sessionTags,
    required this.settings,
    required this.deviceMetadata,
    this.timerRuntime,
    this.backupMetadata,
  });

  final int dataVersion;
  final String exportedAtUtc;
  final List<BackupSkillRecord> skills;
  final List<BackupSessionRecord> sessions;
  final List<BackupSegmentRecord> sessionSegments;
  final List<BackupTagRecord> tags;
  final List<BackupSessionTagRecord> sessionTags;
  final List<BackupSettingRecord> settings;
  final List<BackupDeviceRecord> deviceMetadata;
  final BackupTimerRuntimeRecord? timerRuntime;
  final BackupMetadataRecord? backupMetadata;

  Map<String, Object?> toJson() => {
    'dataVersion': dataVersion,
    'exportedAtUtc': exportedAtUtc,
    'skills': skills.map((e) => e.toJson()).toList(),
    'sessions': sessions.map((e) => e.toJson()).toList(),
    'sessionSegments': sessionSegments.map((e) => e.toJson()).toList(),
    'tags': tags.map((e) => e.toJson()).toList(),
    'sessionTags': sessionTags.map((e) => e.toJson()).toList(),
    'settings': settings.map((e) => e.toJson()).toList(),
    'timerRuntime': timerRuntime?.toJson(),
    'deviceMetadata': deviceMetadata.map((e) => e.toJson()).toList(),
    'backupMetadata': backupMetadata?.toJson(),
  };

  factory BackupPayload.fromJson(Map<String, Object?> json) {
    List<Map<String, Object?>> listOf(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw
          .whereType<Map<Object?, Object?>>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    }

    final runtimeRaw = json['timerRuntime'];
    final metaRaw = json['backupMetadata'];
    return BackupPayload(
      dataVersion: (json['dataVersion'] as num?)?.toInt() ?? 0,
      exportedAtUtc: json['exportedAtUtc'] as String? ?? '',
      skills: listOf('skills').map(BackupSkillRecord.fromJson).toList(),
      sessions: listOf('sessions').map(BackupSessionRecord.fromJson).toList(),
      sessionSegments: listOf(
        'sessionSegments',
      ).map(BackupSegmentRecord.fromJson).toList(),
      tags: listOf('tags').map(BackupTagRecord.fromJson).toList(),
      sessionTags: listOf(
        'sessionTags',
      ).map(BackupSessionTagRecord.fromJson).toList(),
      settings: listOf('settings').map(BackupSettingRecord.fromJson).toList(),
      deviceMetadata: listOf(
        'deviceMetadata',
      ).map(BackupDeviceRecord.fromJson).toList(),
      timerRuntime: runtimeRaw is Map
          ? BackupTimerRuntimeRecord.fromJson(
              runtimeRaw.cast<String, Object?>(),
            )
          : null,
      backupMetadata: metaRaw is Map
          ? BackupMetadataRecord.fromJson(metaRaw.cast<String, Object?>())
          : null,
    );
  }

  BackupSummary computeSummary() {
    final completedActive = sessions
        .where((s) => s.status == 'completed' && s.deletedAtUtc == null)
        .fold<int>(0, (sum, s) => sum + s.activeSeconds);
    final activeOrPending = sessions.any(
      (s) =>
          s.deletedAtUtc == null &&
          (s.status == 'active' ||
              s.status == 'paused' ||
              s.status == 'completion_pending'),
    );
    return BackupSummary(
      skills: skills.where((s) => s.deletedAtUtc == null).length,
      sessions: sessions.where((s) => s.deletedAtUtc == null).length,
      completedActiveSeconds: completedActive,
      tags: tags.length,
      containsActiveOrPendingSession: activeOrPending,
    );
  }
}

final class BackupSkillRecord {
  const BackupSkillRecord({
    required this.id,
    required this.name,
    required this.targetSeconds,
    required this.createdLocalDate,
    required this.status,
    required this.sortOrder,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.sourceDeviceId,
    this.descriptionMarkdown,
    this.accentArgb,
    this.deletedAtUtc,
  });

  final String id;
  final String name;
  final String? descriptionMarkdown;
  final int targetSeconds;
  final String createdLocalDate;
  final int? accentArgb;
  final String status;
  final int sortOrder;
  final int createdAtUtc;
  final int updatedAtUtc;
  final String sourceDeviceId;
  final int? deletedAtUtc;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'descriptionMarkdown': descriptionMarkdown,
    'targetSeconds': targetSeconds,
    'createdLocalDate': createdLocalDate,
    'accentArgb': accentArgb,
    'status': status,
    'sortOrder': sortOrder,
    'createdAtUtc': createdAtUtc,
    'updatedAtUtc': updatedAtUtc,
    'sourceDeviceId': sourceDeviceId,
    'deletedAtUtc': deletedAtUtc,
  };

  factory BackupSkillRecord.fromJson(Map<String, Object?> json) {
    return BackupSkillRecord(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      descriptionMarkdown: json['descriptionMarkdown'] as String?,
      targetSeconds: (json['targetSeconds'] as num?)?.toInt() ?? 0,
      createdLocalDate: json['createdLocalDate'] as String? ?? '',
      accentArgb: (json['accentArgb'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'active',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      createdAtUtc: (json['createdAtUtc'] as num?)?.toInt() ?? 0,
      updatedAtUtc: (json['updatedAtUtc'] as num?)?.toInt() ?? 0,
      sourceDeviceId: json['sourceDeviceId'] as String? ?? '',
      deletedAtUtc: (json['deletedAtUtc'] as num?)?.toInt(),
    );
  }
}

final class BackupSessionRecord {
  const BackupSessionRecord({
    required this.id,
    required this.skillId,
    required this.mode,
    required this.status,
    required this.source,
    required this.startAtUtc,
    required this.activeSeconds,
    required this.pausedSeconds,
    required this.timezoneIdAtCreation,
    required this.offsetMinutesAtStart,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.sourceDeviceId,
    this.title,
    this.noteMarkdown,
    this.endAtUtc,
    this.deletedAtUtc,
  });

  final String id;
  final String skillId;
  final String? title;
  final String? noteMarkdown;
  final String mode;
  final String status;
  final String source;
  final int startAtUtc;
  final int? endAtUtc;
  final int activeSeconds;
  final int pausedSeconds;
  final String timezoneIdAtCreation;
  final int offsetMinutesAtStart;
  final int createdAtUtc;
  final int updatedAtUtc;
  final String sourceDeviceId;
  final int? deletedAtUtc;

  Map<String, Object?> toJson() => {
    'id': id,
    'skillId': skillId,
    'title': title,
    'noteMarkdown': noteMarkdown,
    'mode': mode,
    'status': status,
    'source': source,
    'startAtUtc': startAtUtc,
    'endAtUtc': endAtUtc,
    'activeSeconds': activeSeconds,
    'pausedSeconds': pausedSeconds,
    'timezoneIdAtCreation': timezoneIdAtCreation,
    'offsetMinutesAtStart': offsetMinutesAtStart,
    'createdAtUtc': createdAtUtc,
    'updatedAtUtc': updatedAtUtc,
    'sourceDeviceId': sourceDeviceId,
    'deletedAtUtc': deletedAtUtc,
  };

  factory BackupSessionRecord.fromJson(Map<String, Object?> json) {
    return BackupSessionRecord(
      id: json['id'] as String? ?? '',
      skillId: json['skillId'] as String? ?? '',
      title: json['title'] as String?,
      noteMarkdown: json['noteMarkdown'] as String?,
      mode: json['mode'] as String? ?? 'stopwatch',
      status: json['status'] as String? ?? 'completed',
      source: json['source'] as String? ?? 'timer',
      startAtUtc: (json['startAtUtc'] as num?)?.toInt() ?? 0,
      endAtUtc: (json['endAtUtc'] as num?)?.toInt(),
      activeSeconds: (json['activeSeconds'] as num?)?.toInt() ?? 0,
      pausedSeconds: (json['pausedSeconds'] as num?)?.toInt() ?? 0,
      timezoneIdAtCreation: json['timezoneIdAtCreation'] as String? ?? 'UTC',
      offsetMinutesAtStart:
          (json['offsetMinutesAtStart'] as num?)?.toInt() ?? 0,
      createdAtUtc: (json['createdAtUtc'] as num?)?.toInt() ?? 0,
      updatedAtUtc: (json['updatedAtUtc'] as num?)?.toInt() ?? 0,
      sourceDeviceId: json['sourceDeviceId'] as String? ?? '',
      deletedAtUtc: (json['deletedAtUtc'] as num?)?.toInt(),
    );
  }
}

final class BackupSegmentRecord {
  const BackupSegmentRecord({
    required this.id,
    required this.sessionId,
    required this.segmentType,
    required this.startAtUtc,
    required this.durationSeconds,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.pomodoroPhase,
    this.cycleNumber,
    this.endAtUtc,
  });

  final String id;
  final String sessionId;
  final String segmentType;
  final String? pomodoroPhase;
  final int? cycleNumber;
  final int startAtUtc;
  final int? endAtUtc;
  final int durationSeconds;
  final int createdAtUtc;
  final int updatedAtUtc;

  Map<String, Object?> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'segmentType': segmentType,
    'pomodoroPhase': pomodoroPhase,
    'cycleNumber': cycleNumber,
    'startAtUtc': startAtUtc,
    'endAtUtc': endAtUtc,
    'durationSeconds': durationSeconds,
    'createdAtUtc': createdAtUtc,
    'updatedAtUtc': updatedAtUtc,
  };

  factory BackupSegmentRecord.fromJson(Map<String, Object?> json) {
    return BackupSegmentRecord(
      id: json['id'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      segmentType: json['segmentType'] as String? ?? 'work',
      pomodoroPhase: json['pomodoroPhase'] as String?,
      cycleNumber: (json['cycleNumber'] as num?)?.toInt(),
      startAtUtc: (json['startAtUtc'] as num?)?.toInt() ?? 0,
      endAtUtc: (json['endAtUtc'] as num?)?.toInt(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      createdAtUtc: (json['createdAtUtc'] as num?)?.toInt() ?? 0,
      updatedAtUtc: (json['updatedAtUtc'] as num?)?.toInt() ?? 0,
    );
  }
}

final class BackupTagRecord {
  const BackupTagRecord({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.sourceDeviceId,
  });

  final String id;
  final String name;
  final String normalizedName;
  final int createdAtUtc;
  final int updatedAtUtc;
  final String sourceDeviceId;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'normalizedName': normalizedName,
    'createdAtUtc': createdAtUtc,
    'updatedAtUtc': updatedAtUtc,
    'sourceDeviceId': sourceDeviceId,
  };

  factory BackupTagRecord.fromJson(Map<String, Object?> json) {
    return BackupTagRecord(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      normalizedName: json['normalizedName'] as String? ?? '',
      createdAtUtc: (json['createdAtUtc'] as num?)?.toInt() ?? 0,
      updatedAtUtc: (json['updatedAtUtc'] as num?)?.toInt() ?? 0,
      sourceDeviceId: json['sourceDeviceId'] as String? ?? '',
    );
  }
}

final class BackupSessionTagRecord {
  const BackupSessionTagRecord({required this.sessionId, required this.tagId});

  final String sessionId;
  final String tagId;

  Map<String, Object?> toJson() => {'sessionId': sessionId, 'tagId': tagId};

  factory BackupSessionTagRecord.fromJson(Map<String, Object?> json) {
    return BackupSessionTagRecord(
      sessionId: json['sessionId'] as String? ?? '',
      tagId: json['tagId'] as String? ?? '',
    );
  }
}

final class BackupSettingRecord {
  const BackupSettingRecord({
    required this.key,
    required this.valueJson,
    required this.updatedAtUtc,
    required this.sourceDeviceId,
  });

  final String key;
  final String valueJson;
  final int updatedAtUtc;
  final String sourceDeviceId;

  Map<String, Object?> toJson() => {
    'key': key,
    'valueJson': valueJson,
    'updatedAtUtc': updatedAtUtc,
    'sourceDeviceId': sourceDeviceId,
  };

  factory BackupSettingRecord.fromJson(Map<String, Object?> json) {
    return BackupSettingRecord(
      key: json['key'] as String? ?? '',
      valueJson: json['valueJson'] as String? ?? '',
      updatedAtUtc: (json['updatedAtUtc'] as num?)?.toInt() ?? 0,
      sourceDeviceId: json['sourceDeviceId'] as String? ?? '',
    );
  }
}

final class BackupDeviceRecord {
  const BackupDeviceRecord({
    required this.deviceId,
    required this.createdAtUtc,
    this.displayName,
  });

  final String deviceId;
  final int createdAtUtc;
  final String? displayName;

  Map<String, Object?> toJson() => {
    'deviceId': deviceId,
    'createdAtUtc': createdAtUtc,
    'displayName': displayName,
  };

  factory BackupDeviceRecord.fromJson(Map<String, Object?> json) {
    return BackupDeviceRecord(
      deviceId: json['deviceId'] as String? ?? '',
      createdAtUtc: (json['createdAtUtc'] as num?)?.toInt() ?? 0,
      displayName: json['displayName'] as String?,
    );
  }
}

final class BackupTimerRuntimeRecord {
  const BackupTimerRuntimeRecord({
    required this.singletonId,
    required this.machineState,
    required this.phaseAccumulatedSeconds,
    required this.currentCycle,
    required this.updatedAtUtc,
    this.sessionId,
    this.currentSegmentId,
    this.phasePlannedSeconds,
    this.phaseStartedAtUtc,
    this.monotonicAnchorMicros,
    this.wallClockAnchorUtc,
    this.lastHeartbeatUtc,
    this.lastCheckpointAtUtc,
    this.recoveryReason,
  });

  final int singletonId;
  final String? sessionId;
  final String machineState;
  final String? currentSegmentId;
  final int? phasePlannedSeconds;
  final int? phaseStartedAtUtc;
  final int phaseAccumulatedSeconds;
  final int currentCycle;
  final int? monotonicAnchorMicros;
  final int? wallClockAnchorUtc;
  final int? lastHeartbeatUtc;
  final int? lastCheckpointAtUtc;
  final String? recoveryReason;
  final int updatedAtUtc;

  Map<String, Object?> toJson() => {
    'singletonId': singletonId,
    'sessionId': sessionId,
    'machineState': machineState,
    'currentSegmentId': currentSegmentId,
    'phasePlannedSeconds': phasePlannedSeconds,
    'phaseStartedAtUtc': phaseStartedAtUtc,
    'phaseAccumulatedSeconds': phaseAccumulatedSeconds,
    'currentCycle': currentCycle,
    'monotonicAnchorMicros': monotonicAnchorMicros,
    'wallClockAnchorUtc': wallClockAnchorUtc,
    'lastHeartbeatUtc': lastHeartbeatUtc,
    'lastCheckpointAtUtc': lastCheckpointAtUtc,
    'recoveryReason': recoveryReason,
    'updatedAtUtc': updatedAtUtc,
  };

  factory BackupTimerRuntimeRecord.fromJson(Map<String, Object?> json) {
    return BackupTimerRuntimeRecord(
      singletonId: (json['singletonId'] as num?)?.toInt() ?? 1,
      sessionId: json['sessionId'] as String?,
      machineState: json['machineState'] as String? ?? 'idle',
      currentSegmentId: json['currentSegmentId'] as String?,
      phasePlannedSeconds: (json['phasePlannedSeconds'] as num?)?.toInt(),
      phaseStartedAtUtc: (json['phaseStartedAtUtc'] as num?)?.toInt(),
      phaseAccumulatedSeconds:
          (json['phaseAccumulatedSeconds'] as num?)?.toInt() ?? 0,
      currentCycle: (json['currentCycle'] as num?)?.toInt() ?? 1,
      monotonicAnchorMicros: (json['monotonicAnchorMicros'] as num?)?.toInt(),
      wallClockAnchorUtc: (json['wallClockAnchorUtc'] as num?)?.toInt(),
      lastHeartbeatUtc: (json['lastHeartbeatUtc'] as num?)?.toInt(),
      lastCheckpointAtUtc: (json['lastCheckpointAtUtc'] as num?)?.toInt(),
      recoveryReason: json['recoveryReason'] as String?,
      updatedAtUtc: (json['updatedAtUtc'] as num?)?.toInt() ?? 0,
    );
  }
}

final class BackupMetadataRecord {
  const BackupMetadataRecord({this.lastSuccessfulBackupAtUtc});

  final String? lastSuccessfulBackupAtUtc;

  Map<String, Object?> toJson() => {
    'lastSuccessfulBackupAtUtc': lastSuccessfulBackupAtUtc,
  };

  factory BackupMetadataRecord.fromJson(Map<String, Object?> json) {
    return BackupMetadataRecord(
      lastSuccessfulBackupAtUtc: json['lastSuccessfulBackupAtUtc'] as String?,
    );
  }
}

enum ImportMode { merge, replace }

enum ConflictResolution { keepCurrent, preferImported }

/// User choice when both local and imported payloads have a live session.
enum ActiveSessionDecision {
  /// Keep the local active/paused/pending session.
  keepCurrent,

  /// Prefer the imported active/paused/pending session.
  preferImported,

  /// Keep local live; import the other live session as completed with a
  /// user-reviewed end time ([reviewedEndAtUtc] required).
  completeOtherWithEnd,

  /// Abort the merge.
  cancel,
}

final class ActiveSessionCollision {
  const ActiveSessionCollision({
    required this.localLive,
    required this.incomingLive,
    this.localLiveCount = 1,
    this.incomingLiveCount = 1,
  });

  final BackupSessionRecord localLive;
  final BackupSessionRecord incomingLive;
  final int localLiveCount;
  final int incomingLiveCount;

  bool get sameSessionId => localLive.id == incomingLive.id;
}

/// Filters generic equal-timestamp conflicts superseded by a same-UUID live
/// session collision. Active-session resolution is the sole control for that
/// session in import preview.
List<ImportConflict> previewConflictsFor({
  required List<ImportConflict> conflicts,
  required ActiveSessionCollision? collision,
}) {
  if (collision == null || !collision.sameSessionId) return conflicts;
  final sessionId = collision.localLive.id;
  return conflicts
      .where(
        (conflict) =>
            !(conflict.entityType == 'session' && conflict.id == sessionId),
      )
      .toList();
}

/// Removes per-item LWW choices for a live session owned by [collision].
Map<String, ConflictResolution> perItemForMerge({
  required Map<String, ConflictResolution> perItem,
  required ActiveSessionCollision? collision,
}) {
  if (collision == null || !collision.sameSessionId) return perItem;
  final filtered = Map<String, ConflictResolution>.from(perItem);
  filtered.remove('session:${collision.localLive.id}');
  return filtered;
}

final class ImportConflict {
  const ImportConflict({
    required this.entityType,
    required this.id,
    required this.localUpdatedAtUtc,
    required this.incomingUpdatedAtUtc,
    this.label,
  });

  final String entityType;
  final String id;
  final int localUpdatedAtUtc;
  final int incomingUpdatedAtUtc;
  final String? label;
}

final class ImportPreview {
  const ImportPreview({
    required this.fileName,
    required this.manifest,
    required this.payload,
    required this.checksumOk,
    required this.conflicts,
    required this.localHasActiveOrPending,
    this.activeSessionCollision,
    this.sourceKind = BackupSourceKind.skilltracker,
  });

  final String fileName;
  final BackupManifest manifest;
  final BackupPayload payload;
  final bool checksumOk;
  final List<ImportConflict> conflicts;
  final bool localHasActiveOrPending;
  final ActiveSessionCollision? activeSessionCollision;
  final BackupSourceKind sourceKind;

  bool get requiresActiveSessionDecision => activeSessionCollision != null;
}

/// Which restorable format was opened for import.
enum BackupSourceKind { skilltracker, json, sqlite }

final class BackupStatus {
  const BackupStatus({
    required this.lastSuccessfulBackupAtUtc,
    required this.sessionsChangedSinceBackup,
    required this.reminderEnabled,
    required this.due,
    required this.neverBackedUp,
    this.lastFailedAtUtc,
  });

  final DateTime? lastSuccessfulBackupAtUtc;
  final int sessionsChangedSinceBackup;
  final bool reminderEnabled;
  final bool due;
  final bool neverBackedUp;
  final DateTime? lastFailedAtUtc;
}

final class LocalSnapshotInfo {
  const LocalSnapshotInfo({
    required this.id,
    required this.filePath,
    required this.reason,
    required this.createdAtUtc,
    required this.schemaVersion,
    required this.fileSha256,
    required this.sizeBytes,
    required this.isValid,
  });

  final String id;
  final String filePath;
  final String reason;
  final DateTime createdAtUtc;
  final int schemaVersion;
  final String fileSha256;
  final int sizeBytes;
  final bool isValid;
}

/// Settings keys that may be imported via merge/replace.
const mergeableSettingsKeys = {
  'appearance.reduced_motion',
  'backup.weekly_reminder_enabled',
  'timer.keep_screen_awake',
  'timer.force_landscape_android',
};
