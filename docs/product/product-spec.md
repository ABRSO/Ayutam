# Ayutam — Product Specification

**Status:** Authoritative  
**Audience:** Product owner, designers, developers, coding agents  
**Related:** [UX spec](ux-spec.md) · [Architecture](../architecture/architecture.md) · [Execution plan](../plan/execution-plan.md)

---

## 1. Product requirements

### 1.1 Problem

Existing “10,000 hour” / skill trackers typically force one of: vendor cloud sync (often paid), ads, or data loss when a device is replaced. Ayutam rejects accounts, backends, and automatic sync. The user owns a local SQLite database and moves data only via explicit export/import files.

### 1.2 Vision

A minimal, distinctive, single-purpose deliberate-practice tracker. The user creates skills, times sessions with a flip-clock stopwatch (or Pomodoro), optionally logs Markdown notes, and reviews progress via Learning Log and statistics. All data is local. One **Export** produces a portable backup; **Import** restores or merges it on any supported platform — no account, no network required for core use.

### 1.3 Target user

A self-directed learner tracking one or more long-horizon skills (e.g. AI Learning, Guitar), privacy- and cost-conscious, comfortable managing a backup file the way they would a password vault or ledger.

### 1.4 Goals

1. Track time against a skill goal (default 10,000 hours, configurable) via start/pause/stop.
2. Capture optional Markdown notes, titles, and tags per session.
3. Visualize progress: cumulative chart, GitHub-style heatmap, summary table.
4. Guarantee lossless export/import across Android, Windows, and Linux.
5. Ship one Flutter codebase for Android, Windows, and Linux; structure for future Play Store / Microsoft Store packaging without re-architecture.

### 1.5 Non-goals (permanent unless product direction is explicitly reversed)

No accounts, authentication, backend, automatic cloud sync, ads, analytics, telemetry, remote crash reporting, social features, multi-user, nested subskills, multiple concurrent timers, automatic idle detection, AI summaries, media attachments, browser/PWA, iOS/macOS (v1), calendar integrations, streak freezes.

### 1.6 Success criteria

- Install → first logged session with optional note in under two minutes.
- Export on device A → import on device B yields equivalent totals, notes, timestamps, tags, and settings (principal acceptance test).
- Codebase remains small and legible for a single maintainer returning after months away.

### 1.7 Platforms (v1)

| Platform | Minimum | Distribution (v1) |
|---|---|---|
| Android | API 29 (Android 10) | Sideloaded APK; Play Store later |
| Windows | 64-bit Windows 10/11 | ZIP/installer via GitHub Releases; Store later |
| Linux | Ubuntu 20.04–24.04 LTS, Debian 10–13, x64 | `.deb` and/or archive/AppImage via GitHub Releases |

License: **MIT**. No network required for core features. Optional GitHub Releases update check is Phase 2 / opt-in only (no custom backend).

**Shell navigation / back:** Skills is the Home destination.

- **Android:** system back (or gesture) on Learning Log, Statistics, or Settings returns to Skills; a further back from Skills exits. Nested immersive routes and sheets pop before the shell rule applies.
- **Windows / Linux:** Escape on Learning Log, Statistics, or Settings returns to Skills; Escape while already on Skills does nothing. Exit only via the window close control (title-bar X), not Escape.

### 1.8 Capacity target

Design for at least **20 years**, **100 skills**, **100,000 sessions**, notes ~2 KB average. Indexes and FTS must keep Learning Log / stats usable at that volume.

---

## 2. Functional specification

### 2.1 Skills

**Fields (user-facing):** name (required), description (optional), target hours (default 10,000, configurable, > 0), creation date (default today in configured timezone, editable, cannot be in the future), accent colour (optional; auto-assigned from palette if unset).

**Internal lifecycle:** `active` | `archived`. Home target-progress filters do not change that lifecycle: **In Progress** means a non-archived lifecycle-active skill below its target, while **Completed** means a non-archived lifecycle-active skill at or above its target. Completion is derived, and tracking can continue past the target. Archive hides from Home and timer picker; history remains in Learning Log and Statistics. Restore un-hides.

**Lifecycle actions:** rename, change target/description/colour/creation date, archive, restore, permanent delete. Permanent delete requires typing the skill name, shows affected session count/duration, recommends backup, creates a local safety snapshot first.

**Rules:** Unlimited skills. No subskills in v1. Session tags provide topical grouping. Duplicate names allowed with a warning. Archiving a skill with an active timer is blocked until the session is stopped.

### 2.2 Skills home (default screen)

Vertically stacked skill panels for active (non-archived) skills:

- Accent edge, name, target, accumulated time, progress %, remaining (clamped ≥ 0 when past target).
- **Play** → pre-session sheet → immersive timer.
- Card body expand → last ~5 sessions + “View all in Learning Log” + overflow (edit / archive / delete / export Markdown).
- **+ New Skill** (FAB mobile, toolbar desktop).
- Filters: In Progress / Completed / Archived. Search when many skills.
- Subtle backup-due banner when reminder fires.
- Empty state: guided “Create your first skill…”.

**Startup routing:** recovery/completion-pending/active timer take priority; else Skills (or onboarding if no skills).

### 2.3 Timer — one active session

Only one session may be `active`, `paused`, or `completion_pending` at a time. Starting another skill requires resolving the current one (open active timer / stop then start / cancel).

**Modes:** Stopwatch (count up) and Pomodoro (phase countdown). Both write to the same sessions/segments model.

**Controls:** Start, Pause/Resume, Stop — icon-only visually, with full accessibility labels and desktop tooltips.

**Truth model:** Elapsed time is **never** a free-running in-memory counter. Persist timestamps and segments; display = closed work segments + elapsed since open work segment (see [timer-state-machine.md](../architecture/timer-state-machine.md)).

**Pause:** Freezes display; pause time excluded from active totals; session stays open. Pause/resume does not split into multiple session records.

**Crash / restart:** On relaunch, reconstruct from DB. Gap since last heartbeat ≤ 30 minutes → silent resume. Larger gap → Recovery Review: Include full gap / Trim to last heartbeat / Edit end / Discard. Never silently discard an in-progress session.

**Long session:** Warn after 8 hours of active time; never auto-stop. No idle detection in v1.

**Overlaps:** Warn on overlap; allow save. The same warning applies when a completed session is reassigned to a skill that already has a session in that interval, even if start/end are unchanged.

**Completed / manual times:** Start and end must be ≤ now (UTC). Future timestamps are rejected (`VAL-FUTURE`). Date pickers stop at today; a time later today is also invalid.

**Cross-midnight:** One session record; active duration split across local calendar days for heatmap/daily stats (configured timezone).

**Platform:**

- Android: persistent notification with skill, elapsed, Pause/Stop (secondary to DB truth; see ADR on Android 15 FGS).
- Desktop: system tray while timer runs; shortcuts Space = pause/resume, Ctrl+Enter = start, Ctrl+Shift+Enter = stop (disabled while text fields focused).
- Mobile: request landscape for timer when setting enabled; keep-screen-awake while timer visible if enabled.

### 2.4 Session completion and notes

On Stop:

1. Debounce; close open segment; compute totals.
2. Persist status `completion_pending` immediately (so a crash does not lose the session).
3. Open completion panel.

**Panel:** Read-only skill/date/start–end/active/paused/mode. Editable optional title, Markdown note (soft counter past 2,000 chars, no hard limit), tags. **Edit Time** corrects start/end on the pending session (remaps segments; overlap warning). Actions: **Save Session** (empty note OK), **Resume Session**, **Discard Session** (confirm). Draft title/note/tags must persist successfully before Save/Resume. Back/close keeps `completion_pending` and autosaves draft (debounce ~300–750 ms + on blur/lifecycle).

**Markdown:** CommonMark-ish — headings, emphasis, lists, blockquotes, code, links. No remote images, no arbitrary HTML. Render with `flutter_markdown_plus`.

**Edit later:** Title, note, tags, skill, start/end (warns that totals/stats change). Changing skill or times warns on overlap with another session of the destination skill (save anyway allowed). Manual entry supported (no timer). Completed and manual sessions cannot be dated in the future. Delete: Undo snackbar ~5 s, then soft-delete cleanup — no full trash UI in v1.

**Tags:** Global, case-insensitive unique with preserved casing, autocomplete, filterable. Deleting a tag removes associations, not sessions. Typed tag text must become a chip on Done/Enter, suggestion pick, focus loss, or Save/Apply — never discarded because the user skipped Enter. Learning Log filters show existing tags as selectable chips (same pattern as skill chips).

### 2.5 Learning Log

Dedicated journal of sessions (including those without notes — show “No note added”).

- Group by day / week / month (user-selectable).
- Search: title, note, skill names, tags, dates (FTS5). Date queries match ISO `yyyy-MM-dd` / compact `yyyyMMdd` and English month-day-year tokens of the session’s recorded local start (and end, if another calendar day). Search terms keep Unicode letters (not ASCII-stripped).
- Filters (AND): skill, date range, min/max duration, with/without notes, tags, manual/timed.
- Sort: newest (default), oldest, longest, shortest.
- Month-based lazy loading (fetch one local calendar month at a time; load earlier/later months on scroll).
- Compact calendar jump.
- Filters include archived skills (history remains after archive; Home/timer picker still hide them).
- Mobile: timeline + full-screen detail. Desktop: two-pane list + detail.
- Detail: rendered Markdown, metadata, prev/next, Edit / Delete / Copy note.

### 2.6 Statistics

Scope: selected skill, all skills, or multi-skill comparison (recommend max 5 lines). Compact summary always above views.

**Summary metrics:** total active time, progress %, remaining, sessions, rolling 4-week average (explicitly labeled), global streak, projected completion when calculable.

**Views:** Cumulative chart (default) / Calendar heatmap / Summary table — desktop tabs, mobile segmented control.

**Cumulative chart:** Ranges 7d / 30d / 3mo / 6mo / 1yr / all / custom (mobile simplifies). The selected preset or custom date range is the time window — there is no gesture pinch/zoom or chart pan. Auto aggregation (daily ≤31d; weekly to 6mo; monthly beyond). Hover/tap tooltips; milestones 10/100/500/1k/5k/goal; goal line; fullscreen; PNG export; projection from 4-week average.

**Heatmap:** Previous 12 months default + year selector. Fixed buckets: none / 1–30m / 31–60m / 1–2h / 2–4h / 4h+. Day tap → total time + Open in Learning Log. Colour not sole indicator (focus/selection exposes duration). Advanced Settings may override bucket thresholds.

**Summary table:** Day/week/month/year switchable. Columns: period, total, sessions, avg session, active days, % change vs prior (em dash / “New” when prior is zero).

**Streak:** Across **all** skills; a day qualifies if ≥ **120 seconds** completed active time in configured timezone; consecutive calendar days; no freezes. Threshold adjustable in Settings (default 2 minutes). Sessions under threshold still count in totals/history.

### 2.7 Import, export, backup

**Live store:** SQLite via Drift. **Canonical portable backup:** `.skilltracker` ZIP (manifest + payload JSON + checksums). See [backup-format.md](../architecture/backup-format.md).

**Exports:**

| Format | Restore? | Purpose |
|---|---|---|
| `.skilltracker` | Yes | Full backup / merge |
| Human-readable JSON | Yes | Transparent interchange |
| Consistent SQLite snapshot | Yes (mainly replace) | Exact DB copy |
| CSV sessions | No | Spreadsheet |
| Per-skill Markdown | No | Readable journal |

Filename: `ayutam-backup-YYYY-MM-DD-HHmmss.skilltracker` (no skill name).

**Import:** Validate → preview → user chooses Merge or Replace → safety snapshot → transactional apply. Corrupted/checksum-failed rejected with no mutation. Backward format migrations mandatory; newer unsupported format rejected with update message. LWW by UUID + `updated_at`; equal timestamp + different content → conflict UI (default keep current). Active timer in backup needs explicit confirmation. No direct Drive/Dropbox/GitHub APIs.

**Reminders:** Weekly default; Settings shows “Last backup: N days ago · M sessions changed since”.

**Safety snapshots:** Keep last 3 local DB snapshots before import/destructive ops; restorable from Settings.

### 2.8 Pomodoro (v1)

Configurable: focus 25m, short break 5m, long break 15m, long break every 4 focus intervals (defaults). Auto-start break/next focus configurable (default off).

- Flip clock shows **phase countdown** large; session active + skill total smaller.
- Focus time → active; breaks → paused accounting (reuse pause mechanism).
- One session for the whole run until Stop → completion panel (work-only active total).
- Persist phase transitions before alerts. Manual pause during focus freezes countdown and does not count as active.
- Skippable breaks. Recovery restores phase, cycle, remaining.

### 2.9 Settings (v1)

**Appearance:** theme (system/light/dark), reduced motion, date/number format, 12/24h (device default), week start (locale or Monday), skill colours.

**Timer:** keep screen awake, force landscape on Android timer, default mode, Pomodoro params + auto-start, sound/vibration, 8h warning, shortcut reference.

**Statistics:** default range, heatmap ranges (advanced), streak minimum, timezone (default device).

**Backup & data:** export/import, last backup indicator, weekly reminder, default export location where OS allows, snapshots, integrity check, delete all data. Encryption reserved in format; implementation post-core (see ADR).

**Privacy & security:** optional app lock (off by default; Phase 8), diagnostic export, update-check preference when implemented, privacy statement (no telemetry).

### 2.10 Onboarding

Three steps: track skills → local-only / no accounts → manual backup responsibility. Then create first skill or empty Skills home. Shown only when no skills / onboarding incomplete.

---

## 3. Feature inventory

| ID | Feature | Priority | Acceptance summary |
|---|---|---|---|
| F-001 | Skill CRUD / archive / delete | P0 | Create/edit/archive/restore; type-name delete cascades sessions after snapshot |
| F-002 | Skills home | P0 | Panels, Play, progress, expand history, empty state |
| F-003 | Stopwatch + segments | P0 | Start/pause/resume/stop durable; kill/reopen within 10s tolerance |
| F-004 | Flip clock | P0 | Separate digit cards; unbounded hours; reduced motion |
| F-005 | Completion + notes/tags | P0 | `completion_pending` before panel; empty note OK; autosave draft |
| F-006 | Learning Log | P0 | Group/search/filters/lazy load/detail; FTS usable at 10k+ sessions |
| F-007 | Drift persistence | P0 | Schema, migrations, transactions, integrity |
| F-008 | Portable backup export | P0 | Verified `.skilltracker`; counts/totals match |
| F-009 | Replace + Merge import | P0 | Preview, snapshot, LWW, principal E2E round-trip |
| F-010 | Statistics summary | P0 | Totals, progress, 4-week avg, streak, projection |
| F-011 | Cumulative chart | P0 | Range presets + custom date range, milestones, overlay, export PNG |
| F-012 | Heatmap | P0 | Fixed buckets; day → total + open log |
| F-013 | Summary table | P1 | Switchable granularity + change column |
| F-014 | Pomodoro | P1 | Work-only totals; phase recovery |
| F-015 | Manual session | P1 | Historical entry + overlap warn; no future timestamps |
| F-016 | Android notification | P1 | Persistent; Pause/Stop same commands |
| F-017 | Desktop tray + shortcuts | P1 | Tray live state; keyboard when focused |
| F-018 | Backup reminders | P1 | Weekly + last-backup indicator |
| F-019 | SQLite/CSV/Markdown exports | P1 | Snapshot consistent; reports non-importable |
| F-020 | Local snapshots | P1 | Last 3; restorable |
| F-021 | App lock | P2 | Optional, off by default (Phase 8) |
| F-022 | Encrypted backup | P2 | After core backup proven |
| F-023 | GitHub update check | P2 | Opt-in; no custom backend |
| F-024 | Store packaging | Future | Additive packaging only |

P0 = usable RC. P1 = required for v1 complete. P2 = may follow first stable release without architecture change.

---

## 4. Calculation definitions

**Total active (skill):** sum of `active_seconds` for completed, non-deleted sessions of that skill.

**Progress:** `total / target`; may exceed 100%. **Remaining:** `max(target − total, 0)`.

**Rolling 4-week average:** active seconds allocated to previous 28 local calendar days ÷ 4. Label “4-week average”.

**Projection:** remaining ÷ weekly average → date. Unavailable if target reached, average zero, or insufficient window (~7 days). Soft language (“At your recent 4-week average…”).

**Global streak:** split completed active segments by configured timezone; day qualifies at ≥ streak minimum seconds (default 120); count consecutive days. Freeze exact “today grace” rule in tests (recommended: streak may continue through yesterday until day ends if today still below threshold).

**% change:** `(current − previous) / previous × 100`; prior zero + current positive → “New”; both zero → em dash.

---

## 5. Version boundaries

**In v1:** All P0/P1 features above, MIT FOSS, Android/Windows/Linux, Pomodoro, merge/replace backups, accessibility baseline.

**Out of v1:** See §1.5. Also: automatic CSV import, fuzzy duplicate detection, full permanent audit log, field-level merge UI, multiple local profiles.

**Scope-control rule:** Agents must not add “small useful” features unless listed here or required for safety/testability of a listed feature. Suggestions go to issues / future ADRs.
