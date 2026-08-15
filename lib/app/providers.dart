import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/id/id_generator.dart';
import '../core/logging/app_logger.dart';
import '../core/time/clock_service.dart';
import '../core/time/timezone_service.dart';
import '../database/app_database.dart';
import '../features/learning_log/application/indexed_session_completion.dart';
import '../features/learning_log/application/indexed_session_deletion.dart';
import '../features/learning_log/application/indexed_skill_rename.dart';
import '../features/learning_log/application/learning_log_service.dart';
import '../features/learning_log/application/session_note_service.dart';
import '../features/learning_log/application/tag_service.dart';
import '../features/learning_log/data/drift_tag_repository.dart';
import '../features/learning_log/data/session_search_indexer.dart';
import '../features/learning_log/domain/learning_log_models.dart';
import '../features/learning_log/domain/tag_repository.dart';
import '../features/settings/application/settings_service.dart';
import '../features/settings/data/drift_settings_repository.dart';
import '../features/settings/domain/settings_repository.dart';
import '../features/skills/application/skill_service.dart';
import '../features/skills/data/drift_skill_repository.dart';
import '../features/skills/domain/skill.dart';
import '../features/skills/domain/skill_repository.dart';
import '../features/statistics/application/statistics_service.dart';
import '../features/statistics/data/drift_statistics_source.dart';
import '../features/statistics/domain/statistics_models.dart';
import '../features/statistics/domain/statistics_source.dart';
import '../features/timer/application/stopwatch_timer_service.dart';
import '../features/timer/data/drift_session_repository.dart';
import '../features/timer/data/drift_timer_runtime_repository.dart';
import '../features/timer/data/drift_unit_of_work.dart';
import '../features/timer/domain/models.dart';
import '../features/timer/domain/repositories.dart';

final clockServiceProvider = Provider<ClockService>((ref) {
  return SystemClockService();
});

final timezoneServiceProvider = Provider<TimezoneService>((ref) {
  throw StateError(
    'timezoneServiceProvider was read before bootstrap completed. '
    'Override this provider after resolving the device IANA timezone.',
  );
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

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return DriftSettingsRepository(ref.watch(appDatabaseProvider));
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService(
    settings: ref.watch(settingsRepositoryProvider),
    clock: ref.watch(clockServiceProvider),
    deviceId: () => ref.watch(appDatabaseProvider).requireDeviceId(),
  );
});

final reducedMotionProvider = StreamProvider<bool>((ref) {
  return ref.watch(settingsServiceProvider).watchReducedMotion();
});

final skillServiceProvider = Provider<SkillService>((ref) {
  return SkillService(
    skills: ref.watch(skillRepositoryProvider),
    sessions: ref.watch(sessionRepositoryProvider),
    searchReindexing: IndexedSkillRename(
      ref.watch(sessionSearchIndexerProvider),
    ),
    clock: ref.watch(clockServiceProvider),
    timezones: ref.watch(timezoneServiceProvider),
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
    sessionDeletion: ref.watch(permanentSessionDeletionProvider),
    sessionIndexing: IndexedSessionCompletion(
      sessions: ref.watch(sessionRepositoryProvider),
      indexer: ref.watch(sessionSearchIndexerProvider),
    ),
    clock: ref.watch(clockServiceProvider),
    timezones: ref.watch(timezoneServiceProvider),
    ids: ref.watch(idGeneratorProvider),
    deviceId: () => ref.watch(appDatabaseProvider).requireDeviceId(),
  );
});

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  return DriftTagRepository(ref.watch(appDatabaseProvider));
});

final sessionSearchIndexerProvider = Provider<SessionSearchIndexer>((ref) {
  return SessionSearchIndexer(ref.watch(appDatabaseProvider));
});

final permanentSessionDeletionProvider = Provider<PermanentSessionDeletion>((
  ref,
) {
  return IndexedSessionDeletion(
    sessions: ref.watch(sessionRepositoryProvider),
    indexer: ref.watch(sessionSearchIndexerProvider),
  );
});

final tagServiceProvider = Provider<TagService>((ref) {
  return TagService(
    tags: ref.watch(tagRepositoryProvider),
    clock: ref.watch(clockServiceProvider),
    ids: ref.watch(idGeneratorProvider),
    deviceId: () => ref.watch(appDatabaseProvider).requireDeviceId(),
  );
});

final sessionNoteServiceProvider = Provider<SessionNoteService>((ref) {
  return SessionNoteService(
    sessions: ref.watch(sessionRepositoryProvider),
    skills: ref.watch(skillRepositoryProvider),
    tags: ref.watch(tagServiceProvider),
    indexer: ref.watch(sessionSearchIndexerProvider),
    uow: ref.watch(unitOfWorkProvider),
    clock: ref.watch(clockServiceProvider),
    timezones: ref.watch(timezoneServiceProvider),
    ids: ref.watch(idGeneratorProvider),
    deviceId: () => ref.watch(appDatabaseProvider).requireDeviceId(),
  );
});

final learningLogServiceProvider = Provider<LearningLogService>((ref) {
  return LearningLogService(
    sessions: ref.watch(sessionRepositoryProvider),
    skills: ref.watch(skillRepositoryProvider),
    tags: ref.watch(tagRepositoryProvider),
    indexer: ref.watch(sessionSearchIndexerProvider),
  );
});

final statisticsSourceProvider = Provider<StatisticsSource>((ref) {
  return DriftStatisticsSource(ref.watch(appDatabaseProvider));
});

final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  return StatisticsService(
    source: ref.watch(statisticsSourceProvider),
    skills: ref.watch(skillRepositoryProvider),
    clock: ref.watch(clockServiceProvider),
    timezones: ref.watch(timezoneServiceProvider),
  );
});

final class StatsScopeNotifier extends Notifier<StatsScope> {
  @override
  StatsScope build() => const StatsScope.all();

  void set(StatsScope scope) => state = scope;
}

final statsScopeProvider = NotifierProvider<StatsScopeNotifier, StatsScope>(
  StatsScopeNotifier.new,
);

final class StatsBundleNotifier extends AsyncNotifier<StatsBundle> {
  @override
  Future<StatsBundle> build() {
    final scope = ref.watch(statsScopeProvider);
    final service = ref.watch(statisticsServiceProvider);
    // Drift watches emit once on subscribe; only later emissions mean the
    // sessions table actually changed.
    final changes = ref
        .watch(statisticsSourceProvider)
        .watchChanges()
        .skip(1)
        .listen((_) => ref.invalidateSelf());
    ref.onDispose(changes.cancel);
    return service.load(scope);
  }
}

final statsBundleProvider =
    AsyncNotifierProvider<StatsBundleNotifier, StatsBundle>(
      StatsBundleNotifier.new,
    );

final activeSkillsProvider = StreamProvider<List<Skill>>((ref) {
  return ref.watch(skillServiceProvider).watchActive();
});

final allSkillsProvider = StreamProvider<List<Skill>>((ref) {
  return ref.watch(skillServiceProvider).watchAll();
});

final class AppShellIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final appShellIndexProvider = NotifierProvider<AppShellIndexNotifier, int>(
  AppShellIndexNotifier.new,
);

final class LearningLogFiltersNotifier extends Notifier<LearningLogFilters> {
  @override
  LearningLogFilters build() => const LearningLogFilters();

  void setFilters(LearningLogFilters filters) => state = filters;

  void update(LearningLogFilters Function(LearningLogFilters current) fn) {
    state = fn(state);
  }

  void clear() => state = const LearningLogFilters();
}

final learningLogFiltersProvider =
    NotifierProvider<LearningLogFiltersNotifier, LearningLogFilters>(
      LearningLogFiltersNotifier.new,
    );

final class LearningLogListNotifier
    extends AsyncNotifier<LearningLogListState> {
  @override
  Future<LearningLogListState> build() {
    final filters = ref.watch(learningLogFiltersProvider);
    return ref.watch(learningLogServiceProvider).loadInitial(filters);
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || current.loadingMore) return;
    final filters = ref.read(learningLogFiltersProvider);
    final older = filters.sort != LearningLogSort.oldest;
    if (older && !current.hasMoreOlder) return;
    if (!older && !current.hasMoreNewer) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    final service = ref.read(learningLogServiceProvider);
    final next = older
        ? await service.loadOlder(filters, current)
        : await service.loadNewer(filters, current);
    if (!ref.mounted) return;
    state = AsyncData(next.copyWith(loadingMore: false));
  }
}

final learningLogListProvider =
    AsyncNotifierProvider<LearningLogListNotifier, LearningLogListState>(
      LearningLogListNotifier.new,
    );

/// Live Learning Log row for [sessionId]. Invalidated with the list after edits.
final learningLogEntryProvider = FutureProvider.autoDispose
    .family<LearningLogEntry?, String>((ref, sessionId) {
      return ref.watch(learningLogServiceProvider).getEntry(sessionId);
    });

final class SelectedLearningLogSessionIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final selectedLearningLogSessionIdProvider =
    NotifierProvider<SelectedLearningLogSessionIdNotifier, String?>(
      SelectedLearningLogSessionIdNotifier.new,
    );

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
