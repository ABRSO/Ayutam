# Ayutam — Technical Architecture

**Status:** Authoritative  
**Related:** [Database](database.md) · [Backup](backup-format.md) · [Timer](timer-state-machine.md) · [ADRs](decisions/)

---

## 1. Architecture style

**Feature-based modular architecture** with clear presentation → application → domain → data boundaries. Not enterprise Clean Architecture ceremony, but dependency direction is mandatory.

```text
Flutter UI / Platform Views
        │
        ▼
Presentation state (Riverpod 3 Notifiers)
        │
        ▼
Application services / use cases
        │
        ▼
Domain models + repository contracts
        │
        ▼
Repositories
   ┌────┴───────────┬─────────────────┐
   ▼                ▼                 ▼
Drift/SQLite   File/backup I/O   Platform services
                                 (notification, tray,
                                  shortcuts, wakelock, …)
```

**Rules:**

- Widgets do not execute SQL.
- Platform plugins do not define domain truth.
- Repositories are the only source of persisted domain data.
- Application commands own transactions and validation.
- Timer truth is persisted state + timestamps/segments, not animation ticks.
- `lib/.../domain/` and application layers must not import `package:flutter` or `package:drift`.

---

## 2. Recommended stack

| Concern | Choice | Notes |
|---|---|---|
| Framework | Flutter stable (pin in repo tooling) | Android, Windows, Linux |
| UI | Material 3 | Light/dark/system |
| State / DI | **Riverpod 3.x** (`flutter_riverpod`) | Modern `Notifier` / `AsyncNotifier` — **not** legacy `StateNotifierProvider` (see ADR-007) |
| Database | Drift + native SQLite | Typed queries, migrations, `.watch()`, desktop support |
| Navigation | Standard `Navigator` + typed route builders | No `go_router` in v1 (ADR-008) |
| Charts | `fl_chart` behind a thin adapter | Heatmap is custom |
| Flip clock | Custom widgets | No novelty package |
| Markdown | **`flutter_markdown_plus`** | Successor to discontinued `flutter_markdown` (ADR-015) |
| Archive / hash | `archive`, `crypto` | ZIP + SHA-256 |
| Files | `path_provider`, `file_picker` / `file_selector` | Re-verify at implement time |
| Notifications | Interface + `flutter_foreground_task` or native Kotlin | Replaceable; Android 15 FGS rules (ADR-016) |
| Desktop | `window_manager`, `tray_manager` | Graceful degrade if tray fails |
| Wakelock | `wakelock_plus` | |
| IDs / locale | `uuid`, `intl`, `timezone` | |
| CSV | `csv` | |

**Package policy:** Prefer mature MIT/BSD/Apache-2.0 packages; minimize count; document purpose, licence, platform matrix, replacement plan. Re-check versions on pub.dev before pinning. Do not add packages for trivial Dart/Flutter-native capability.

---

## 3. Project structure

```text
ayutam/
├── AGENTS.md
├── README.md
├── LICENSE
├── CHANGELOG.md
├── CONTRIBUTING.md
├── SECURITY.md
├── pubspec.yaml
├── analysis_options.yaml
├── .github/workflows/
├── docs/                          # this documentation set
├── assets/
├── lib/
│   ├── main.dart
│   ├── bootstrap.dart
│   ├── app/                       # MaterialApp, theme, routes, lifecycle
│   ├── core/                      # Result, failures, clock, ids, logging, constants
│   ├── database/                  # Drift AppDatabase, tables, daos, migrations, fts
│   ├── features/
│   │   ├── skills/
│   │   ├── timer/
│   │   ├── sessions/
│   │   ├── learning_log/
│   │   ├── statistics/
│   │   ├── backup/
│   │   ├── settings/
│   │   ├── onboarding/
│   │   └── diagnostics/
│   └── platform/                  # foreground, tray, shortcuts, orientation, …
├── test/
├── integration_test/
├── tool/                          # fixtures, verify_backup, licence_report
├── android/
├── windows/
└── linux/
```

Each feature may use:

```text
feature/
├── domain/          # entities, value objects, repository interfaces, policies
├── application/     # services/commands/queries
├── data/            # Drift repo impls, mappers
└── presentation/    # Notifiers, screens, widgets
```

Do not create empty layers. Small features may combine files while preserving dependency direction.

**Naming:** `SkillsScreen`, `TimerController` (Notifier), `StartSessionService`, `SessionRepository` + `DriftSessionRepository`. Avoid vague `Helper`/`Manager`/`Utils`.

**Build flavors (optional):** `dev` / `staging` / `prod` — logging and application ID only; no backend URLs.

---

## 4. State management (Riverpod 3)

### 4.1 Role

Riverpod provides DI, async UI state, repository streams, and command coordination. **SQLite remains the source of truth.** Riverpod must not become an alternate database.

### 4.2 Prefer modern APIs

Use `Notifier`, `AsyncNotifier`, `StreamNotifier`, and `Provider` / `FutureProvider` / `StreamProvider` as appropriate.

**Do not** introduce new `StateNotifierProvider` / `StateProvider` / `ChangeNotifierProvider` code. Those are legacy in Riverpod 3 (`package:flutter_riverpod/legacy.dart`). Prefer codegen (`riverpod_annotation` + `riverpod_generator`) **or** manual Notifiers — pick one style in Phase 0 and stay consistent. If using Drift’s `build_runner`, Riverpod codegen is acceptable as a second generator; document the choice in an ADR update if opting out of codegen for Riverpod to keep a single generator.

### 4.3 Provider categories

**Infrastructure:** database, repositories, clock, file dialogs, platform services, logger.

**Queries:** active skills, recent sessions, active/pending session, Learning Log pages, stats series, backup status — prefer Drift `.watch()` → `StreamProvider` where live.

**Controllers (Notifiers):** skills, timer display, completion draft, Learning Log filters, statistics selection, backup/import, settings.

### 4.4 Rules

1. **Persist first**, then publish success UI state.  
2. Commands expose loading / success / typed failure.  
3. Commands are idempotent or rejected by state preconditions.  
4. UI may rebuild every second for display; DB writes only on transitions or periodic heartbeats (not every second for full session rows).  
5. Screens recover from provider recreation via repository state.  
6. Tests override providers for fake clock, temp DB, fake platform services.  
7. Be aware Riverpod 3 filters updates with `==` and may auto-retry failed providers — design providers accordingly.

### 4.5 Timer display model

```text
TimerDisplayState
- sessionId, skillId, mode, machineState
- accumulatedSkillSeconds
- currentSessionActiveSeconds
- currentPhaseRemainingSeconds (Pomodoro)
- pomodoroCycle
- longSessionWarningDue
- recoveryReviewRequired
```

Controller asks injectable clock for `now`, combines with persisted anchors — does **not** increment canonical duration.

---

## 5. Cross-cutting services

| Service | Responsibility |
|---|---|
| ClockService | Wall UTC + monotonic elapsed; single place for clock-change validation |
| Timer services | Start/Pause/Resume/Stop/Recover/Finalize — transactional |
| BackupService | Archive build/validate, merge/replace, snapshots |
| NotificationService | Android ongoing notification + Pomodoro alerts |
| TrayService | Windows/Linux tray icon/menu |
| OrientationService / ScreenAwakeService | Timer chrome |
| FileDialogService | Pick/save/share |
| SettingsService | Typed KV over `app_settings` |
| UpdateCheckService | Opt-in GitHub Releases (Phase 2); never blocks startup |
| AppLockService | Optional PIN / platform auth (Phase 8) |

---

## 6. Concurrency

- Prefer Drift database in a background isolate where supported.  
- Heavy JSON, ZIP, checksum, large CSV, large stats aggregation: off UI isolate.  
- Single coordinated SQLite writer; no multiple independent writers.  
- UI observes streams or invalidates after commands.

---

## 7. Offline and network

- No network for core. No remote fonts, remote Markdown assets, telemetry.  
- Android `INTERNET` omitted until opt-in update check is included in a build.  
- Update check failures never affect startup or core flows.

---

## 8. Platform integrations

**Android foreground / notification:** Improves visibility and Pause/Stop actions. Duration still comes from DB. Must declare FGS type correctly for Android 14+; handle Android 15 timeouts for restricted types; `stopWithTask` / boot policy reviewed before Play submission (ADR-016). Interface must allow swapping plugin for native Kotlin.

**Desktop lifecycle:** Close with no session → exit. Close with active session → minimize to tray after first-run explanation. Explicit Exit confirms if needed. Tray/shortcut failure must not block DB or timer.

---

## 9. Error model

Use typed `Result` / sealed failures — not unstructured strings across layers.

Categories: validation, database, file permission, unsupported backup version, checksum, integrity, conflict, platform unavailable, clock discontinuity, storage, encryption.

User-facing errors: concise explanation, whether data changed, recovery action, diagnostic code for logs.

Uncaught exceptions: catch at root, local diagnostic log only, generic UI + “Export diagnostic log”.

---

## 10. Logging

Local structured rolling logs. No note content by default. No PIN/passphrase. Export diagnostics on demand. Debug builds may be more verbose; never log secrets.

---

## 11. Packaging and release architecture

Support: debug/release APK (AAB later), Windows installer/ZIP, Linux x64 `.deb`/archive/AppImage, GitHub Actions matrix, semver, changelog, lockfile, store metadata outside core app code.

---

## 12. Navigation model

Conceptual routes (typed builders, not stringly named routes):

```text
/onboarding
/skills (+ create/edit/start)
/timer/:sessionId
/session/:sessionId/complete
/learning-log (+ session detail/edit, manual)
/statistics
/settings (+ nested groups, snapshots, diagnostics)
/backup/import-preview
/backup/conflicts
```

**Startup:** corrupt DB → recovery; completion_pending → completion; active/paused → timer or recovery review; no skills → onboarding; else Skills.

**Back:** Timer back does not stop session. Completion back keeps pending draft. No duplicate Timer routes for same session.
