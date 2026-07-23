# Ayutam — Agent Execution Plan

**Status:** Authoritative implementation order  
**Audience:** Coding agents (and humans) building the app from an empty repo  
**Prerequisite reading:** [`AGENTS.md`](../../AGENTS.md), [`docs/README.md`](../README.md), product + architecture docs

This plan is ordered. **Do not start Phase N+1 until Phase N exit criteria pass.** Each phase must leave `main` (or the working branch) buildable and non-regressing.

Package versions: re-verify on pub.dev when adding dependencies; record pins in `pubspec.yaml` / lockfile and note material substitutions in an ADR.

---

## Global verification commands

Run after every phase (adapt when Flutter project exists):

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Platform smoke (when CI/agents have runners):

```bash
flutter build apk --debug
flutter build windows --debug
flutter build linux --debug
```

---

## Phase 0 — Repository and architectural foundation

**Goal:** Empty but correct Flutter multi-platform shell with docs already present, DI, DB open, CI.

### Tasks (in order)

1. Create Flutter project targeting Android, Windows, Linux (`flutter create --platforms=android,windows,linux`).
2. Add MIT `LICENSE` (already present — verify), rewrite root `README.md` if not already, add `CHANGELOG.md`, `CONTRIBUTING.md`, `SECURITY.md` stubs.
3. Ensure `AGENTS.md` and `docs/` are present (this documentation set).
4. Configure `analysis_options.yaml` (strict lints, prefer good practices).
5. Add dependencies: `flutter_riverpod` 3.x, `drift`, `drift_dev`, `sqlite3_flutter_libs` / `sqlite3`, `path_provider`, `path`, `uuid`, `intl`, `clock` or custom ClockService, `logger` or thin local logger — **re-verify versions**.
6. Scaffold `lib/` per [architecture.md](../architecture/architecture.md).
7. Implement `ClockService`, id generator, `Result`/`AppFailure`, bootstrap that opens Drift DB (background isolate if ready).
8. Schema version 1 tables from [database.md](../architecture/database.md) — at least empty tables + `device_identity` seed; migrations stub.
9. Material 3 theme (light/dark/system) + responsive shell with 4 destinations (placeholder screens).
10. GitHub Actions: format, analyze, test, optional build smoke matrix.
11. ADR index already exists — link from README; do not re-litigate accepted ADRs.

### Tests to write

- Clock abstraction unit test with fake time.
- Database opens and creates schema.
- Widget smoke: app loads to onboarding or Skills empty.

### Exit criteria

- [x] App launches on Android, Windows, and Linux to empty shell / onboarding.
- [x] No network permission required for core Android manifest.
- [x] CI green for analyze + unit/db smoke.
- [x] `device_id` generated once and persisted.

**Phase 0 notes (2026-07-22 / verified 2026-07-23):** Scaffold on `cursor/phase-0-flutter-scaffold`. Main AndroidManifest has no `INTERNET` (debug/profile overlays retain it for Flutter tooling only).

Real platform smoke evidence:

| Platform | Evidence |
|---|---|
| **Windows** | `flutter build windows --debug` → `build\windows\x64\runner\Debug\ayutam.exe`; process stayed alive ~5s (`WIN_SMOKE_OK`). Needs Developer Mode (plugin symlinks). If MSVC `cl.exe` fails with “requires elevation”, clear bogus `RUNASADMIN` AppCompat on `cl.exe` and/or set `__COMPAT_LAYER=RunAsInvoker` for the build shell. |
| **Android** | SDK at `%LOCALAPPDATA%\Android\Sdk`; AVD `ayutam_api34` (API 34 google_apis x86_64); `flutter build apk --debug` → install + `am start` → `pidof com.ayutam.ayutam` (`ANDROID_SMOKE_OK`). |
| **Linux** | WSL2 Ubuntu (`abr`) + WSLg; Flutter in `~/flutter`; `flutter build linux --debug` → `build/linux/x64/debug/bundle/ayutam`; short GUI launch (`LINUX_SMOKE_OK`). |

---

## Phase 1 — Vertical slice: skill → completed stopwatch session

**Goal:** Prove durable timer invariant early (hardest risk).

### Tasks

1. Skill domain + Drift repo: create/edit/list/archive (delete can be soft or full with confirm).
2. Skills home UI: panels, progress from totals, Play, Create Skill, empty state.
3. Pre-session sheet (Stopwatch only for now).
4. Implement timer state machine for stopwatch: start/pause/resume/stop with **segments** + `timer_runtime` ([timer-state-machine.md](../architecture/timer-state-machine.md)).
5. Completion panel: save without note; `completion_pending` before UI; Discard with confirm.
6. Process-kill recovery + 30-minute heartbeat gap rule (Recovery Review UI).
7. Startup routing: pending → completion; active → timer/recovery; else Skills.

### Tests

- State-machine unit tests (all stopwatch transitions + idempotent stop).
- DB: one-active invariant; segment sums = cached totals.
- Integration: start → pause → resume → stop → save → skill total updates.
- Crash recovery with fake clock (silent vs review).

### Exit criteria

- [ ] Flow: create skill → Play → Start → Stop → Save → Home shows updated total.
- [ ] Force-close mid-run → reopen reconstructs duration within 10s (simulated).
- [ ] Double-stop does not duplicate sessions.
- [ ] Domain logic shared; no platform-specific business rules.

---

## Phase 2 — Flip clock + visual identity

**Goal:** Signature UI without changing domain.

### Tasks

1. Custom `FlipDigit` / `FlipClock` (rotateX flip; Reduced Motion fade/instant).
2. Wire stopwatch timer screen: large accumulated total + smaller session mono text.
3. Per-skill accent palette auto-assign; theme polish.
4. Icon-only controls with semantics + tooltips + 48dp targets.

### Tests

- Widget tests: digit change; reduced motion path.
- Semantics labels for Pause/Stop.

### Exit criteria

- [ ] Timer matches UX flip-clock intent.
- [ ] Reduced Motion disables 3D flip.
- [ ] Hours unbounded (e.g. > 99).

---

## Phase 3 — Notes, tags, Learning Log

### Tasks

1. Markdown note editor + preview via `flutter_markdown_plus`; autosave draft.
2. Title + tags (normalized uniqueness, autocomplete).
3. Manual session entry + overlap warning.
4. Edit/delete completed sessions + Undo snackbar.
5. FTS5 `session_search` maintenance.
6. Learning Log: group day/week/month, filters, sort, calendar jump, lazy months.
7. Desktop two-pane; mobile list + detail route.
8. Link from skill “View all”.

### Tests

- Markdown round trip; autosave survives provider dispose.
- FTS search returns expected rows.
- Filter AND combinations.
- Manual entry validation.

### Exit criteria

- [ ] Completion with note/tags works; empty note OK.
- [ ] Learning Log usable with synthetic multi-year fixture (≥10k sessions preferred).
- [ ] Search meets soft latency target on mid hardware or documented baseline.

---

## Phase 4 — Statistics

### Tasks

1. Aggregation services: daily allocation from work segments; streak; 4-week average; projection.
2. Summary card above views.
3. Cumulative chart (`fl_chart` adapter): ranges, milestones, overlay, tooltips, zoom/pan, PNG export.
4. Custom heatmap: fixed buckets; day popover + Open in Learning Log.
5. Summary table: day/week/month/year + % change.
6. Scope: skill / all / compare (max ~5).

### Tests

- Cross-midnight allocation unit tests.
- Streak 120s threshold + timezone.
- Aggregation correctness fixtures.
- Widget smoke for chart/heatmap empty states.

### Exit criteria

- [ ] Stats match Learning Log totals for fixtures.
- [ ] Heatmap day opens filtered Log.
- [ ] Projection/streak labeled correctly in UI.

---

## Phase 5 — Backup, restore, migration

### Tasks

1. `.skilltracker` writer (manifest, payload incl. segments, checksums).
2. Export verify-before-success; `backup_history`.
3. Import validation stages + preview UI.
4. Replace path + Merge LWW + equal-timestamp conflicts.
5. Safety snapshots (retain 3); restore UI.
6. CSV + per-skill Markdown + consistent SQLite snapshot exports.
7. Weekly reminder + last-backup indicator.
8. Migration test harness for schema v1 (ready for future bumps).

### Tests

- Full backup matrix from [testing-strategy.md](../testing/testing-strategy.md).
- Principal round-trip test (same OS first; cross-OS when available).
- Mid-merge failure leaves original data.

### Exit criteria

- [ ] Export → wipe/replace → identical skills/sessions/segments/notes/settings.
- [ ] Merge divergent UUIDs keeps both; same UUID newest wins.
- [ ] Corrupt file rejected with no mutation.
- [ ] `lastSuccessfulBackupAt` only updates after verify.

---

## Phase 6 — Platform integrations

### Tasks

1. Android ongoing notification + Pause/Stop → same commands; handle FGS timeout per ADR-016.
2. Orientation request for timer; wakelock while visible.
3. Windows/Linux tray + window close → tray when session active.
4. Desktop shortcuts (respect text-field focus).
5. Drag-and-drop import on desktop.
6. Graceful degrade if tray/notification unavailable.

### Tests

- Command idempotency from “notification” fake.
- Timer remains correct with notification service failing.
- Manual checklist for tray/orientation.

### Exit criteria

- [ ] Core timer works with integrations disabled.
- [ ] Notification/tray reflect running/paused state when available.
- [ ] Linux tray failure does not prevent startup.

---

## Phase 7 — Pomodoro

### Tasks

1. Settings for focus/break/cycles/auto-start/sound.
2. Pre-session mode Pomodoro; countdown-dominant flip clock.
3. Phase transitions as segments; break = non-active.
4. Alerts after persist; skip break; recovery of phase/cycle/remaining.
5. Completion shows work-only active total.

### Tests

- Phase machine unit tests; backgrounded phase complete.
- Active seconds exclude breaks.
- Recovery restores Pomodoro fields.

### Exit criteria

- [ ] Completed Pomodoro session active time = sum of focus work only.
- [ ] No second timer engine — extends Phase 1 machine.

---

## Phase 8 — Hardening and release

### Tasks

1. Accessibility pass (Part UX §10); empty/error catalog wired.
2. Performance fixture tool + profile hot paths.
3. Optional app lock (off by default) per ADR-018.
4. Optional encrypted backup if security review + Argon2id benchmarks pass; else defer with format fields already reserved.
5. Diagnostics export; integrity screen.
6. Packaging: signed APK, Windows installer/ZIP, Linux `.deb`/archive; GitHub Releases workflow.
7. Store-readiness scaffolding (icons, metadata placeholders) without submission.
8. Update `CHANGELOG`; run principal E2E across three platforms.
9. Optional: GitHub Releases update check behind flag (still no custom backend).

### Tests

- Perf smoke on fixture.
- Full integration + E2E acceptance.
- Package install/upgrade preserves app data dir.

### Exit criteria

- [ ] GitHub Release produces installable artifacts for Android, Windows, Linux.
- [ ] Principal E2E acceptance (§ testing strategy) passes.
- [ ] Accessibility checklist signed off.
- [ ] Docs updated for any shipped deviations (ADRs).

---

## After v1 (not blocking)

- Play Store / Microsoft Store submission and FGS evidence.
- Biometrics / Windows Hello enhancements.
- Encryption if deferred.
- macOS/iOS only if product direction changes (new ADR).

---

## Agent checklist per phase

1. Read `AGENTS.md` + relevant docs/ADRs.  
2. Restate acceptance criteria in the PR/commit message.  
3. Implement smallest vertical change.  
4. Add tests.  
5. Run global verification commands.  
6. Update docs if behavior/schema/format changed.  
7. Mark phase exit criteria complete only when demonstrably true.
