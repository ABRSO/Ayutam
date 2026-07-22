# AGENTS.md — Ayutam

## Mission

Ayutam is a **local-first** Flutter skill-practice tracker for **Android, Windows, and Linux**. It has **no backend**, accounts, analytics, advertisements, or automatic cloud synchronization. SQLite (Drift) is the live store. Users own and move data through explicit backups.

**Read before non-trivial work:**

1. This file  
2. [`docs/README.md`](docs/README.md)  
3. Relevant specs under `docs/product/` and `docs/architecture/`  
4. [`docs/plan/execution-plan.md`](docs/plan/execution-plan.md) for implementation order  

Archived brainstorming under `docs/archive/` is **not** authoritative.

## Non-negotiable invariants

1. At most one session may be `active`, `paused`, or `completion_pending`.  
2. Timer truth is persisted timestamps and **session segments**, not UI ticks.  
3. State transitions are transactional and idempotent (persist, then notify UI/platform).  
4. Completed progress is integer **active** seconds; pauses and Pomodoro breaks never count as active.  
5. Cross-midnight work segments are split by configured timezone for daily statistics.  
6. Global streak requires ≥ **120** completed active seconds per local day (default, Settings-adjustable).  
7. Backups are marked successful only after verification.  
8. Imports validate before mutation and create a safety snapshot.  
9. Schema changes require migrations and migration tests in the same change.  
10. No backend, auth, telemetry, ads, or automatic cloud sync.  
11. Android, Windows, and Linux share domain and application logic.  
12. Domain/application layers must not import `package:flutter` or `package:drift`.

## Architecture

Feature-based modules: presentation (Riverpod 3 Notifiers) → application → domain → data (Drift) + platform services.

See [`docs/architecture/architecture.md`](docs/architecture/architecture.md).

## Technology baseline

- Flutter stable (pin via repo tooling)  
- Material 3  
- **Riverpod 3.x** (`Notifier` API — not legacy `StateNotifierProvider`)  
- Drift + native SQLite + **FTS5** for Learning Log search  
- Standard Navigator (no `go_router` unless new ADR)  
- Custom flip clock and heatmap; `fl_chart` for line charts  
- Notes: **`flutter_markdown_plus`** (not discontinued `flutter_markdown`)  
- Permissively licensed packages only; document substitutions in ADRs  

Re-verify package versions at implementation time.

## Commands (once Flutter project exists)

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after Drift (and optional Riverpod codegen) changes
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter test integration_test
```

## Timer work

Before changing timer code, read [`docs/architecture/timer-state-machine.md`](docs/architecture/timer-state-machine.md) and recovery tests.

Every transition must: validate persisted state → update session, segments, and `timer_runtime` in one transaction → commit → then notification/tray/UI → tolerate duplicate commands → survive process death.

Use injectable wall + monotonic clocks in tests.

## Backup / import work

Canonical format: versioned `.skilltracker` — see [`docs/architecture/backup-format.md`](docs/architecture/backup-format.md).

Stages: file safety → manifest → checksum/decrypt → semantic validation → preview → snapshot → transactional replace/merge → integrity. UUID identity; LWW on `updated_at`; equal timestamp conflicts need UI. Never update last-successful-backup before verify.

## Product boundaries — do not add

Firebase/Supabase/backend/API; login; social/leaderboards; AI summaries; media attachments; multiple active timers; web/PWA; iOS/macOS in v1; automatic cloud sync; unrelated gamification.

Put suggestions in issues. Do not implement opportunistically.

## UI rules

- Skills is Home; Timer is an immersive nested route.  
- Stopwatch: large accumulated flip clock; Pomodoro: large phase countdown.  
- Icon-only timer controls need semantics, tooltips, focus, 48×48 targets.  
- Light / dark / system; reduced motion; large text; keyboard; colour-independent charts/heatmap.

## Documentation maintenance

Update docs in the **same change** when altering user-visible behavior, schema, backup format, state machine, package choice, permissions, or security model. Material decisions → ADR under `docs/architecture/decisions/`.

## Before claiming done

1. Relevant tests pass (`flutter test` + targeted integration).  
2. Schema change includes migration + migration test.  
3. New dependency documented (purpose, licence, platforms) or ADR notes substitution.  
4. No new network/analytics call.  
5. Phase exit criteria in execution plan met if implementing a phase.

## Completion report format

- Files changed  
- Behavior implemented  
- Tests run and results  
- Migrations / data implications  
- Platform implications  
- Remaining limitations  

## Decisions — do not re-litigate

See [`docs/architecture/decisions/`](docs/architecture/decisions/) (segments model, Riverpod 3, markdown_plus, Android 15 FGS, FTS5, app lock/encryption phasing, four-tab nav, Pomodoro overlay, etc.).
