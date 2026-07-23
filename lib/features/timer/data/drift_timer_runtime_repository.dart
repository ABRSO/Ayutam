import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../domain/models.dart' as domain;
import '../domain/repositories.dart';

final class DriftTimerRuntimeRepository implements TimerRuntimeRepository {
  DriftTimerRuntimeRepository(this._db);

  final AppDatabase _db;

  @override
  Future<domain.TimerRuntimeState> get() async {
    final row = await (_db.select(
      _db.timerRuntime,
    )..where((t) => t.singletonId.equals(1))).getSingle();
    return _toDomain(row);
  }

  @override
  Future<void> save(domain.TimerRuntimeState state) async {
    await _db
        .into(_db.timerRuntime)
        .insertOnConflictUpdate(_toCompanion(state));
  }

  @override
  Future<void> clearToIdle({required DateTime updatedAtUtc}) async {
    await save(
      domain.TimerRuntimeState(
        machineState: domain.TimerMachineState.idle,
        currentCycle: 1,
        phaseAccumulatedSeconds: 0,
        updatedAtUtc: updatedAtUtc,
      ),
    );
  }

  domain.TimerRuntimeState _toDomain(TimerRuntimeData row) {
    return domain.TimerRuntimeState(
      sessionId: row.sessionId,
      machineState: domain.TimerMachineState.parse(row.machineState),
      currentSegmentId: row.currentSegmentId,
      phasePlannedSeconds: row.phasePlannedSeconds,
      phaseStartedAtUtc: row.phaseStartedAtUtc == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              row.phaseStartedAtUtc!,
              isUtc: true,
            ),
      phaseAccumulatedSeconds: row.phaseAccumulatedSeconds,
      currentCycle: row.currentCycle,
      monotonicAnchorMicros: row.monotonicAnchorMicros,
      wallClockAnchorUtc: row.wallClockAnchorUtc == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              row.wallClockAnchorUtc!,
              isUtc: true,
            ),
      lastHeartbeatUtc: row.lastHeartbeatUtc == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              row.lastHeartbeatUtc!,
              isUtc: true,
            ),
      lastCheckpointAtUtc: row.lastCheckpointAtUtc == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              row.lastCheckpointAtUtc!,
              isUtc: true,
            ),
      recoveryReason: domain.RecoveryReason.tryParse(row.recoveryReason),
      updatedAtUtc: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAtUtc,
        isUtc: true,
      ),
    );
  }

  TimerRuntimeCompanion _toCompanion(domain.TimerRuntimeState state) {
    return TimerRuntimeCompanion.insert(
      singletonId: const Value(1),
      sessionId: Value(state.sessionId),
      machineState: Value(state.machineState.storageValue),
      currentSegmentId: Value(state.currentSegmentId),
      phasePlannedSeconds: Value(state.phasePlannedSeconds),
      phaseStartedAtUtc: Value(state.phaseStartedAtUtc?.millisecondsSinceEpoch),
      phaseAccumulatedSeconds: Value(state.phaseAccumulatedSeconds),
      currentCycle: Value(state.currentCycle),
      monotonicAnchorMicros: Value(state.monotonicAnchorMicros),
      wallClockAnchorUtc: Value(
        state.wallClockAnchorUtc?.millisecondsSinceEpoch,
      ),
      lastHeartbeatUtc: Value(state.lastHeartbeatUtc?.millisecondsSinceEpoch),
      lastCheckpointAtUtc: Value(
        state.lastCheckpointAtUtc?.millisecondsSinceEpoch,
      ),
      recoveryReason: Value(state.recoveryReason?.storageValue),
      updatedAtUtc: state.updatedAtUtc.millisecondsSinceEpoch,
    );
  }
}
