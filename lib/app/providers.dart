import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/id/id_generator.dart';
import '../core/logging/app_logger.dart';
import '../core/time/clock_service.dart';
import '../database/app_database.dart';
import '../features/skills/application/skill_service.dart';
import '../features/skills/data/drift_skill_repository.dart';
import '../features/skills/domain/skill.dart';
import '../features/skills/domain/skill_repository.dart';
import '../features/timer/application/stopwatch_timer_service.dart';
import '../features/timer/data/drift_session_repository.dart';
import '../features/timer/data/drift_timer_runtime_repository.dart';
import '../features/timer/data/drift_unit_of_work.dart';
import '../features/timer/domain/models.dart';
import '../features/timer/domain/repositories.dart';

final clockServiceProvider = Provider<ClockService>((ref) {
  return SystemClockService();
});

final idGeneratorProvider = Provider<IdGenerator>((ref) {
  return const UuidIdGenerator();
});

final appLoggerProvider = Provider<AppLogger>((ref) {
  return const ConsoleAppLogger();
});

/// Opened during [bootstrap]. Override in tests with an in-memory DB.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw StateError(
    'appDatabaseProvider was read before bootstrap completed. '
    'Override this provider after AppDatabase.open.',
  );
});

final deviceIdProvider = FutureProvider<String>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.requireDeviceId();
});

final skillRepositoryProvider = Provider<SkillRepository>((ref) {
  return DriftSkillRepository(ref.watch(appDatabaseProvider));
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return DriftSessionRepository(ref.watch(appDatabaseProvider));
});

final timerRuntimeRepositoryProvider = Provider<TimerRuntimeRepository>((ref) {
  return DriftTimerRuntimeRepository(ref.watch(appDatabaseProvider));
});

final unitOfWorkProvider = Provider<UnitOfWork>((ref) {
  return DriftUnitOfWork(ref.watch(appDatabaseProvider));
});

final skillServiceProvider = Provider<SkillService>((ref) {
  return SkillService(
    skills: ref.watch(skillRepositoryProvider),
    clock: ref.watch(clockServiceProvider),
    ids: ref.watch(idGeneratorProvider),
    deviceId: () => ref.watch(appDatabaseProvider).requireDeviceId(),
  );
});

final stopwatchTimerServiceProvider = Provider<StopwatchTimerService>((ref) {
  return StopwatchTimerService(
    sessions: ref.watch(sessionRepositoryProvider),
    runtime: ref.watch(timerRuntimeRepositoryProvider),
    skills: ref.watch(skillRepositoryProvider),
    uow: ref.watch(unitOfWorkProvider),
    clock: ref.watch(clockServiceProvider),
    ids: ref.watch(idGeneratorProvider),
    deviceId: () => ref.watch(appDatabaseProvider).requireDeviceId(),
  );
});

final activeSkillsProvider = StreamProvider<List<Skill>>((ref) {
  return ref.watch(skillServiceProvider).watchActive();
});

final class TimerSessionNotifier extends AsyncNotifier<TimerSnapshot> {
  @override
  Future<TimerSnapshot> build() {
    return ref.read(stopwatchTimerServiceProvider).snapshot();
  }

  StopwatchTimerService get _service => ref.read(stopwatchTimerServiceProvider);

  Future<void> refresh() async {
    state = AsyncData(await _service.snapshot());
  }

  Future<String?> startStopwatch(String skillId) async {
    final result = await _service.startStopwatch(skillId);
    return result.when(
      success: (snap) {
        state = AsyncData(snap);
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> pause() async {
    final result = await _service.pause();
    return result.when(
      success: (snap) {
        state = AsyncData(snap);
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> resume() async {
    final result = await _service.resume();
    return result.when(
      success: (snap) {
        state = AsyncData(snap);
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> stop() async {
    final result = await _service.stop();
    return result.when(
      success: (snap) {
        state = AsyncData(snap);
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> saveCompletion() async {
    final result = await _service.saveCompletion();
    return result.when(
      success: (snap) {
        state = AsyncData(snap);
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> discardCompletion() async {
    final result = await _service.discardCompletion();
    return result.when(
      success: (snap) {
        state = AsyncData(snap);
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<String?> resumeFromCompletion() async {
    final result = await _service.resumeFromCompletion();
    return result.when(
      success: (snap) {
        state = AsyncData(snap);
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<void> heartbeat() async {
    final result = await _service.heartbeat();
    result.when(success: (snap) => state = AsyncData(snap), failure: (_) {});
  }

  Future<String?> applyRecovery({
    required RecoveryDecision decision,
    DateTime? editedEndUtc,
  }) async {
    final result = await _service.applyRecoveryDecision(
      decision: decision,
      editedEndUtc: editedEndUtc,
    );
    return result.when(
      success: (snap) {
        state = AsyncData(snap);
        return null;
      },
      failure: (f) => f.message,
    );
  }
}

final timerSessionProvider =
    AsyncNotifierProvider<TimerSessionNotifier, TimerSnapshot>(
      TimerSessionNotifier.new,
    );

final class StartupGateNotifier extends AsyncNotifier<StartupRoute> {
  @override
  Future<StartupRoute> build() async {
    final result = await ref
        .read(stopwatchTimerServiceProvider)
        .recoverOnStartup();
    return result.when(
      success: (route) => route,
      failure: (_) =>
          const StartupRoute(destination: StartupDestination.skillsHome),
    );
  }

  Future<void> reevaluate() async {
    state = const AsyncLoading();
    state = AsyncData(await build());
  }
}

final startupGateProvider =
    AsyncNotifierProvider<StartupGateNotifier, StartupRoute>(
      StartupGateNotifier.new,
    );
