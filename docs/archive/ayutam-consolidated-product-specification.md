> **SUPERSEDED — do not use as implementation source of truth.**
>
> This document is retained for historical traceability only. The authoritative specification lives under `docs/` (see [docs/README.md](../README.md)). An implementing agent must follow `AGENTS.md` and the current docs, not this archive file.
>
> Archived: 2026-07-22

---
# Ayutam — Consolidated Product, UX, and Technical Specification

**Document status:** Implementation baseline  
**Product type:** Local-first, offline skill-practice tracker  
**Primary framework:** Flutter  
**Initial platforms:** Android, Windows, and Linux  
**Distribution:** Sideloaded APK and desktop packages through GitHub Releases; store-ready architecture for later Play Store and Microsoft Store distribution  
**Repository licence:** MIT  
**Backend:** None  
**Accounts, authentication, telemetry, advertisements, and automatic cloud synchronization:** Permanently out of scope  
**Source requirements:** Consolidated from the answered product questionnaire and prior product discussions  
**Intended audience:** Product designer, UI/UX designer, Flutter developer, QA engineer, and coding agents such as Codex or Claude Code

---

## Document purpose

This document is the single source of truth for building **Ayutam**, a minimal, durable, user-owned tracker for accumulating deliberate-practice time toward long-term skill goals. It combines the product requirements document, functional specification, feature specification, UI/UX specification, responsive layouts, technical architecture, data model, backup design, timer model, testing plan, coding-agent instructions, and implementation phases.

The document deliberately prefers a small, maintainable product over a broad productivity suite. Every feature must directly support one of these jobs:

1. Start and accurately track practice.
2. Preserve a trustworthy history of completed sessions.
3. Make progress understandable over months and years.
4. Let the user own, export, restore, and move all data without a backend.

Anything that does not support one of these jobs requires a separate architectural decision record before implementation.

---

# 0. Executive decisions and requirement normalization

## 0.1 Product definition

Ayutam is an offline Flutter application for tracking time spent developing one or more skills. Each skill has an independently configurable target, defaulting to 10,000 hours. The user launches a stopwatch or Pomodoro session from a skill card, sees an immersive flip-clock interface, optionally writes a Markdown learning note after stopping, and reviews progress through a Learning Log, cumulative chart, calendar heatmap, and summary table.

SQLite is the live database. The user moves data between devices through explicit export and import. The app has no server, account, remote database, or hidden synchronization process.

## 0.2 Non-negotiable principles

| Principle | Requirement |
|---|---|
| Local-first | Every core feature works without a network connection. |
| User-owned data | The complete dataset is exportable in documented, versioned formats. |
| No backend | No API, hosted database, authentication service, or mandatory cloud dependency. |
| Crash-safe timer | Starting, pausing, resuming, and stopping are persisted immediately. |
| One active session | Only one skill timer may be active at any moment. |
| Cross-platform | Android, Windows, and Linux share one Flutter codebase and domain layer. |
| Minimal UI | The Skills home page and immersive flip clock are the primary experience. |
| Long-term reliability | The design must support at least 20 years and 100,000 sessions. |
| Privacy | No analytics, advertisements, remote crash reporting, or automatic data upload. |
| Maintainability | Prefer mature, permissively licensed packages and clear module boundaries. |

## 0.3 Resolved contradictions and assumptions

The questionnaire contains a few overlapping answers. This specification resolves them as follows:

1. **Streak threshold:** A day counts toward the streak when the combined completed active time across all skills is at least **120 seconds**. This specific answer overrides the later generic “use recommended default” response.
2. **Navigation:** Skills is the default home page. The active Timer is a dedicated immersive route launched from a skill card, not a duplicate permanent navigation destination. Primary navigation is Skills, Learning Log, Statistics, and Settings.
3. **Learning Log desktop layout:** The later explicit approval of the recommended hybrid layout takes precedence. Desktop uses a two-pane layout when width permits; the implementation remains in the same shared Flutter codebase.
4. **Import behavior:** Both **Merge** and **Replace** are supported. Merge uses stable UUIDs and last-write-wins conflict resolution. Replace is the safest and simplest recovery path.
5. **Raw SQLite versus portable backup:** The canonical portable backup is a versioned `.skilltracker` archive containing JSON and checksums. A consistent raw SQLite snapshot is an advanced full-backup option. CSV and Markdown exports are reporting formats and are not restorable backups.
6. **Application lock:** A cross-platform local PIN lock is included as an optional setting. Android biometric unlock and Windows Hello are future enhancements because they add platform-specific complexity.
7. **Optional backup encryption:** Architecture and file format must reserve encryption metadata in version 1. Initial implementation may ship unencrypted export first, followed by passphrase encryption within the version-1 development programme after core backup reliability is proven.
8. **Pomodoro details:** The default is 25 minutes work, 5 minutes short break, 15 minutes long break after four work intervals. Durations and auto-start behavior are configurable. Only work intervals contribute to tracked skill time.
9. **Linux baseline:** Support Ubuntu 20.04–24.04 LTS and Debian 10–13 on x64 initially. Arm64 desktop packaging is optional after x64 acceptance tests pass.
10. **Maximum-session warning:** Warn at 8 hours but never stop automatically.
11. **Timer accuracy:** Persisted duration may deviate by no more than 10 seconds under normal operation, excluding deliberate system-clock manipulation and time the device was fully powered off where the shutdown timestamp cannot be known exactly.

## 0.4 Product success criteria

Ayutam is successful when a user can:

- create a skill in under one minute;
- start a session from the home screen with no more than two intentional actions;
- recover an active session after application termination or device restart;
- export the entire dataset and restore it on another supported platform without losing totals, notes, tags, timestamps, or settings;
- understand cumulative progress and consistency without reading a long raw list;
- continue using the app for years without a subscription or service dependency.

## 0.5 Terminology

| Term | Definition |
|---|---|
| Skill | A tracked area of practice, such as AI Learning or Guitar. |
| Target | The desired cumulative active duration for a skill. Defaults to 10,000 hours. |
| Session | One saved period of practice associated with one skill. |
| Active time | Time counted toward the skill target. |
| Paused time | Time inside a session that does not count toward progress. |
| Pomodoro work interval | A timed work segment that counts as active time. |
| Pomodoro break | A timed rest segment that does not count as active time. |
| Learning note | Optional Markdown text attached to a completed session. |
| Learning Log | Searchable and grouped history of sessions and notes. |
| Working database | The live local SQLite database used by the application. |
| Portable backup | A versioned `.skilltracker` archive intended for restore and device transfer. |
| Snapshot | An automatic local safety copy created before destructive operations. |

---

# 1. Product requirements document

## 1.1 Problem statement

Existing skill trackers commonly make one of four compromises: local data is lost when the application is removed or the device fails; reliable synchronization is placed behind a subscription; the application contains advertisements; or long-term access depends on a vendor-hosted service. Ayutam removes these dependencies by treating the local database as the active working copy and a user-managed export as the durable portable copy.

The product is not intended to compete through social features, recommendations, gamification, or cloud convenience. Its value is accuracy, clarity, portability, and long-term maintainability.

## 1.2 Target user

The primary user is an individual who deliberately practices one or more skills over months or years and wants:

- accurate cumulative time;
- meaningful session notes;
- visible long-term progress;
- no account or subscription;
- full control of backup location;
- the same application on Android and desktop.

The product is single-user by design. It does not attempt to model organizations, teams, classrooms, coaches, or shared goals.

## 1.3 Core jobs to be done

### Job A — Track practice

> When I begin focused work, I need to start a reliable timer with almost no setup so that the time is attributed to the correct skill.

### Job B — Remember what happened

> When I finish, I need an optional place to capture what I learned, completed, or struggled with so that the accumulated hours retain context.

### Job C — See long-term progress

> When motivation or planning requires perspective, I need charts, totals, consistency indicators, and projections that explain how far I have come.

### Job D — Protect ownership

> When I change or lose a device, I need to restore all skills, sessions, notes, settings, and active-timer state from a file I control.

## 1.4 Product goals

1. Record stopwatch and Pomodoro sessions accurately.
2. Make the flip-clock timer visually distinctive without compromising accessibility or battery use.
3. Keep the home page centered on skills rather than dashboards or settings.
4. Provide an intuitive Learning Log that scales to years of notes.
5. Provide useful statistics without turning the app into an analytics product.
6. Make backup health visible and restoration safe.
7. Keep all domain behavior independent of the operating system and UI where practical.
8. Prepare the codebase for future store distribution without requiring store-specific work during early development.

## 1.5 Non-goals

Ayutam will not provide:

- user accounts or identity management;
- automatic cross-device synchronization;
- hosted storage or APIs;
- advertisements or subscription plans;
- shared skills, teams, or leaderboards;
- public profiles;
- AI-generated notes or summaries;
- media attachments;
- browser/PWA delivery;
- iOS or macOS in version 1;
- multiple concurrent timers;
- automatic idle detection;
- social, coaching, or marketplace features.

## 1.6 Platforms and support policy

### Version-1 platforms

| Platform | Minimum target | Primary distribution |
|---|---|---|
| Android | Android 10 / API 29 | Sideloaded release APK; Play Store later |
| Windows | 64-bit Windows 10 and 11 | ZIP or installer through GitHub Releases; Microsoft Store later |
| Linux | Ubuntu 20.04–24.04 LTS and Debian 10–13, x64 | `.deb`, archive, or AppImage through GitHub Releases |

Platform-specific enhancements are allowed only behind interfaces in the shared codebase:

- Android foreground notification and notification actions;
- Windows/Linux system tray;
- desktop keyboard shortcuts;
- desktop drag-and-drop import;
- desktop chart hover behavior;
- responsive two-pane Learning Log.

No feature should require maintaining separate application forks.

## 1.7 Product constraints

- The app must remain fully usable with network permissions absent.
- GitHub release checks, when implemented, must be optional and user initiated or opt-in.
- The database is stored only in the platform application-data directory.
- Core functionality must not depend on proprietary SDKs.
- Every third-party package must have a documented purpose, licence, platform matrix, and replacement plan.
- No database mutation may depend solely on an in-memory timer or widget lifecycle.

## 1.8 Primary metrics

Because there is no telemetry, these are acceptance and self-evaluation metrics rather than remotely collected product analytics:

- timer recovery success rate in automated tests: 100%;
- successful portable-backup round trip: 100%;
- migration test pass rate across all retained schema versions: 100%;
- no partial imports after induced failure: 100%;
- home-to-running-session path: no more than two intentional actions;
- initial Skills page render with 100 skills: under 500 ms on the baseline test device after database initialization;
- Learning Log query for one month within a 100,000-session dataset: under 300 ms on desktop and under 500 ms on baseline Android hardware;
- chart aggregation should not block the UI thread for more than one frame budget.

---

# 2. Functional specification

## 2.1 Skills

### Create skill

The user can create an unlimited number of skills. The creation form contains:

- **Name** — required, trimmed, 1–100 Unicode characters;
- **Description** — optional Markdown/plain text, up to 2,000 characters recommended but not hard-limited below database limits;
- **Target duration** — defaults to 10,000 hours; accepts hours and optional minutes; must be greater than zero;
- **Creation date** — defaults to the current date in the configured application timezone and can be changed;
- **Accent colour** — optional; chosen from an accessible palette or custom colour picker.

The following lifecycle values are internal and not required as creation-form fields:

- `active`;
- `completed`;
- `archived`.

A skill is marked completed automatically when completed active time reaches or exceeds the target. Tracking remains permitted beyond the target.

### Edit skill

The user can rename a skill, change description, target, creation date, and colour. Changing the target recalculates progress immediately but does not alter session data.

### Archive and restore

Archiving removes the skill from the default active list but keeps sessions, notes, statistics, and exports. Archived skills are accessible through an Archived filter and can be restored.

### Delete

Permanent deletion removes the skill and all related sessions, tags associations, and statistics. The app must:

1. show record count and tracked duration affected;
2. recommend creating a backup;
3. require a destructive confirmation, including typing the skill name or a second explicit confirmation;
4. create a local safety snapshot before deletion;
5. offer an immediate Undo only if the deletion has not yet been compacted and the snapshot remains valid.

## 2.2 Skills home page

The Skills page is the default route and primary dashboard.

Each skill panel displays:

- skill name;
- optional description excerpt;
- target duration;
- accumulated active duration;
- progress percentage;
- remaining duration, clamped to zero once the target is passed;
- skill accent colour;
- primary Play button;
- overflow menu for edit, archive, export, and delete;
- expandable recent-history area.

Selecting the card body expands it to show the most recent sessions, using compact rows or tabs as space permits. The expanded area displays up to five sessions and a **View all in Learning Log** action. Selecting Play opens the pre-session sheet.

The page includes:

- Create Skill action;
- search field that becomes prominent when more than ten active skills exist;
- Active, Completed, and Archived filters;
- last-backup status in a subtle non-blocking banner when backup is overdue.

## 2.3 Pre-session sheet

Before starting, show a compact bottom sheet on mobile and dialog/popover on desktop containing:

- selected skill name and current total;
- mode selector: Stopwatch or Pomodoro;
- Pomodoro settings summary when selected;
- optional session title placeholder;
- Start button;
- Cancel action.

The previously used mode for that skill may be preselected, but the app must not start a timer without an explicit action.

If another session is active, replace Start with:

- Open active timer;
- Stop active session and start this skill;
- Cancel.

Starting a second timer silently is prohibited.

## 2.4 Stopwatch session

When the user starts Stopwatch mode:

1. Create a persisted session record with status `active`.
2. Create the first active segment with UTC and monotonic timing anchors.
3. Start the Android foreground notification when applicable.
4. Open the immersive Timer route.
5. On Android phone layouts, request landscape orientation and restore the prior orientation after leaving the timer.

The Timer route shows:

- skill name in a subdued header;
- large accumulated skill time in separate flip cards for hours, minutes, and seconds;
- smaller current-session active duration;
- icon-only Pause/Resume and Stop controls with semantic labels and tooltips;
- Pomodoro information only when that mode is active;
- optional screen-awake indicator.

The timer is calculated from persisted timestamps and accumulated durations. Visual ticking is a rendering concern, not the source of truth.

## 2.5 Pause and resume

Pause:

- closes the current active segment;
- persists its duration;
- creates or records a pause segment;
- updates session state to `paused`;
- excludes subsequent elapsed time from progress;
- updates Android notification and desktop tray state.

Resume:

- closes the pause segment;
- creates a new active segment;
- updates session state to `running`;
- resumes rendering from persisted totals.

Pause/resume does not create separate sessions.

## 2.6 Pomodoro mode

Default configuration:

- work: 25 minutes;
- short break: 5 minutes;
- long break: 15 minutes;
- long break after four work intervals;
- auto-start break: off;
- auto-start next work interval: off;
- sound/vibration: local and configurable.

Functional rules:

- work intervals count toward active skill time;
- breaks do not count toward active time;
- manual pauses inside a work interval do not count;
- the entire Pomodoro run is one session until the user stops or finalizes it;
- each work, pause, and break is retained as a segment for recovery and audit;
- the large timer shows current phase countdown in Pomodoro mode because phase completion is the immediate task;
- accumulated skill duration and accumulated active time in the current session remain visible in smaller form;
- completing a work interval must persist before any sound, animation, or transition;
- stopping during a break saves only completed and partially completed work time;
- a user may end the run after any interval and proceed to the completion panel.

## 2.7 Background, termination, and restart recovery

The session must survive:

- app minimization;
- screen lock;
- desktop minimization;
- accidental window close where tray mode remains active;
- operating-system process termination;
- application relaunch;
- device restart.

Recovery behavior:

1. Read the active or paused persisted session before showing the normal start screen.
2. Recalculate elapsed active time from timestamps.
3. Validate wall-clock and monotonic anchors where available.
4. If the interruption is normal, reopen the Timer route automatically.
5. If the elapsed gap is unusual, such as more than 8 hours or across a restart, show a recovery review:
   - Continue counting;
   - Stop at last known application/device shutdown time when available;
   - Edit end time;
   - Discard session.
6. Never silently discard an in-progress session.

A foreground service or tray process improves visibility but is not the sole basis of duration calculation.

## 2.8 Maximum-session warning

After 8 hours of active time, show a non-destructive warning in the timer and notification/tray:

> This session has been running for 8 hours. Confirm that it is still active.

Options:

- Continue;
- Pause;
- Stop and review.

The application must never automatically stop solely because of duration.

## 2.9 Stop and completion workflow

When Stop is selected:

1. Debounce the action to prevent duplicate stops.
2. Close the current segment.
3. Calculate active and paused totals.
4. Change the persisted session status to `completion_pending` immediately.
5. Stop or update foreground integrations.
6. Open the completion panel.

The completion panel shows read-only calculated information:

- skill;
- date;
- start time;
- end time;
- active duration;
- paused/break duration;
- timer mode.

Editable fields:

- optional title;
- optional Markdown note;
- tags;
- start/end/duration correction through an Edit Time action.

Actions:

- **Save Session** — valid whether note is empty or populated;
- **Resume Session** — returns the session to active state and opens a new active segment;
- **Discard Session** — destructive confirmation required;
- system back/close — leaves the record as `completion_pending` and autosaves title, note, and tags.

On next launch, a completion-pending session is presented before starting a new session.

## 2.10 Notes and Markdown

Notes are stored as Markdown source. The editor behaves like a plain multiline text field and supports a preview toggle. Minimum supported syntax:

- headings;
- emphasis;
- ordered and unordered lists;
- task lists when supported by the renderer;
- blockquotes;
- inline code and fenced code blocks;
- links.

Inline HTML is not required. Remote images must not be fetched or rendered in version 1. Notes autosave as the user types, using a short debounce such as 300–750 ms and immediate persistence when the editor loses focus or the app lifecycle changes.

## 2.11 Tags

Tags are global reusable labels. Requirements:

- create while editing a session;
- case-insensitive uniqueness with preserved display casing;
- optional colour is not required in version 1;
- autocomplete existing tags;
- rename and delete from Settings or tag management;
- deleting a tag removes associations, not sessions;
- filter and search Learning Log by tags.

## 2.12 Manual session entry

The user can add a completed session without using a timer. Required fields:

- skill;
- start date/time and end date/time, or date plus duration;
- active duration greater than zero;
- optional title, note, and tags.

The form warns about overlaps but allows saving. Manual sessions are marked `source = manual` and are included in all statistics.

## 2.13 Edit completed session

The user may edit title, note, skill, tags, start, end, and active duration. Editing time:

- shows the old and new duration;
- warns that totals, streaks, heatmap, and projections will change;
- validates end after start;
- warns on overlap;
- updates `updated_at` and source-device metadata;
- recalculates aggregate queries automatically.

For a simple duration correction, segment detail may be replaced with one adjusted active segment and an audit note in local diagnostics. A complete permanent audit trail is not required.

## 2.14 Delete completed session

Deleting a session immediately removes it from normal queries and shows Undo. Internally, use a short-lived soft-delete marker or in-memory undo command. Once the undo window expires, permanently remove the session and its associations. A snapshot is required before bulk deletion, not necessarily before every individual session deletion.

## 2.15 Overlapping and cross-midnight sessions

- Overlapping sessions are permitted after warning.
- Overlap is not an import conflict unless records share the same UUID.
- For daily statistics, active segments crossing midnight are split precisely at local-day boundaries in the user-configured timezone.
- One session remains one record in Learning Log even when its duration contributes to multiple heatmap days.

## 2.16 Learning Log

The Learning Log displays all completed sessions, including sessions without notes.

Capabilities:

- group by day, week, or month;
- compact calendar navigation;
- search title, note, skill, tags, and normalized date text;
- filters for skill, date range, minimum/maximum duration, note presence, tags, and manual/timed source;
- sort newest, oldest, longest, or shortest;
- month-based lazy loading;
- complete note detail with Markdown rendering;
- edit, delete, copy note, and previous/next navigation;
- open prefiltered from a heatmap day or skill card;
- clear “No note added” presentation for empty notes.

## 2.17 Statistics

Statistics support:

- selected-skill view;
- all-skills aggregate view;
- multi-skill line comparison, with a recommended maximum of five visible lines;
- compact summary card above every statistics view;
- cumulative line chart;
- calendar heatmap;
- switchable summary table.

### Summary metrics

For selected skill:

- total active time;
- progress percent;
- remaining duration;
- completed sessions;
- rolling four-week average;
- global current streak;
- projected target-completion date when calculable.

For all skills:

- sum of active time;
- weighted progress = total active time / sum of targets;
- sum of positive remaining durations;
- total sessions;
- rolling four-week aggregate average;
- global streak;
- projection based on aggregate target and aggregate average.

### Cumulative line chart

Time ranges:

- 7 days;
- 30 days;
- 3 months;
- 6 months;
- 1 year;
- all time;
- custom.

Automatic aggregation:

| Selected span | Default points |
|---|---|
| Up to 31 days | Daily |
| 32 days to 6 months | Weekly |
| More than 6 months | Monthly |

Interactions:

- hover on desktop;
- tap on mobile;
- tooltip with date, cumulative total, and time added in period;
- zoom and pan;
- date-range control;
- fixed milestone lines at 10, 100, 500, 1,000, 5,000 hours, and goal;
- goal line;
- full-screen chart;
- export chart as PNG;
- legend and skill selection for comparison mode.

### Calendar heatmap

- Default window: previous 12 months.
- Year selector available.
- Fixed intensity ranges:
  - no activity;
  - 1–30 minutes;
  - 31–60 minutes;
  - 1–2 hours;
  - 2–4 hours;
  - more than 4 hours.
- Selecting a day shows total active time and an **Open in Learning Log** action.
- Keyboard focus and screen readers expose date, duration, and session count.

### Summary table

Switchable daily, weekly, monthly, and yearly aggregation. Columns:

- period;
- total active time;
- session count;
- average session duration;
- active days;
- change versus previous comparable period.

## 2.18 Streak calculation

- Scope: all skills combined.
- Qualifying day: at least 120 seconds of completed active time.
- Date grouping: application-configured timezone.
- Consecutive calendar days only.
- No freeze days, rest-day schedule, or grace period in version 1.
- Sessions shorter than two minutes remain in history and totals but do not independently qualify a day unless combined daily time reaches two minutes.

## 2.19 Backup and restore

### Manual export

The user can export:

1. Full portable `.skilltracker` backup.
2. Human-readable JSON data export.
3. Consistent raw SQLite snapshot.
4. CSV session report.
5. One selected skill and its notes as Markdown.

Only the first three are considered restoration sources. CSV and Markdown are reports.

### Reminder

- Default reminder: weekly.
- Settings shows last successful backup timestamp and sessions created or changed since backup.
- Reminder is local and dismissible.
- It must never imply that data has been backed up automatically when only a reminder was shown.

### Import

Before changing data, import must:

1. read and validate the file in a staging area;
2. verify supported format and schema versions;
3. verify checksums;
4. verify referential integrity and totals;
5. show preview metadata;
6. create a local safety snapshot;
7. offer Merge or Replace where the format supports it;
8. execute transactionally;
9. run database integrity checks;
10. recalculate and verify statistics;
11. report the result.

Raw SQLite import is replace-only unless a temporary database is opened and normalized through the standard merge pipeline.

## 2.20 Settings

Settings categories:

### Appearance

- theme: system, light, dark;
- reduced motion;
- date and number format;
- 12/24-hour mode, default device preference;
- week-start day, default device locale or Monday;
- skill accent-colour management.

### Timer

- keep screen awake;
- force landscape during Android timer;
- default mode;
- Pomodoro work, short-break, long-break, and cycle settings;
- auto-start preferences;
- sound/vibration;
- long-session warning threshold, default 8 hours;
- keyboard-shortcut reference.

### Statistics

- default date range;
- heatmap ranges;
- streak minimum, default 2 minutes;
- timezone, default device timezone.

### Backup and data

- export and import;
- last backup and changed-session count;
- weekly reminder configuration;
- default export location where the platform permits;
- optional backup encryption;
- local snapshots and restore;
- database integrity check;
- delete all local data.

### Privacy and security

- optional local PIN lock;
- diagnostic-log export;
- update-check preference when implemented;
- privacy statement explaining no telemetry and no backend.

## 2.21 Onboarding

Three concise screens:

1. **Track your skills** — create a skill and start a stopwatch or Pomodoro session.
2. **Your data stays here** — explain local storage and absence of accounts/cloud synchronization.
3. **Back up your progress** — explain manual export and recommend a safe external location.

The final onboarding action creates the first skill or enters the empty Skills screen.


---

# 3. Feature specification

## 3.1 Feature inventory and priorities

| ID | Feature | Priority | Version-1 acceptance summary |
|---|---|---:|---|
| F-001 | Skill creation and management | P0 | Create, edit, archive, restore, complete, delete. |
| F-002 | Skills home page | P0 | Skill panels, play action, progress, expandable recent history. |
| F-003 | Stopwatch timer | P0 | Start, pause, resume, stop, crash/restart recovery. |
| F-004 | Flip-clock presentation | P0 | Separate cards, responsive, reduced motion, unbounded hours. |
| F-005 | Session completion and notes | P0 | Completion-pending persistence, Markdown note, title, tags. |
| F-006 | Learning Log | P0 | Grouping, search, filters, lazy loading, details, editing. |
| F-007 | SQLite persistence | P0 | Drift schema, migrations, transactions, integrity checks. |
| F-008 | Portable backup | P0 | Export, verify, preview, replace restore, checksum. |
| F-009 | Merge import | P0 | Stable IDs, LWW conflicts, transactional merge. |
| F-010 | Statistics summary | P0 | Totals, progress, remaining, sessions, average, streak. |
| F-011 | Cumulative chart | P0 | Ranges, tooltips, milestones, responsive interactions. |
| F-012 | Calendar heatmap | P0 | 12 months, fixed ranges, day navigation. |
| F-013 | Summary table | P1 | Daily/weekly/monthly/yearly switch. |
| F-014 | Pomodoro mode | P1 | Work/break phases, configurable, recovery, work-only totals. |
| F-015 | Manual session entry | P1 | Add historical sessions and overlap warnings. |
| F-016 | Android foreground notification | P1 | Persistent notification and pause/stop controls. |
| F-017 | Desktop tray and shortcuts | P1 | Tray state/actions and keyboard controls. |
| F-018 | Backup reminders | P1 | Weekly reminder and last-backup status. |
| F-019 | Raw SQLite export | P1 | Consistent snapshot and replace restore. |
| F-020 | CSV and Markdown reports | P1 | Sessions CSV and selected-skill notes export. |
| F-021 | Local safety snapshots | P1 | Last three before import/destructive operations. |
| F-022 | PIN lock | P2 | Optional app-level PIN. |
| F-023 | Encrypted backup | P2 | Passphrase encryption after base backup is proven. |
| F-024 | GitHub release check | P2 | Optional, no custom backend. |
| F-025 | Store packaging | Future | Play Store and Microsoft Store readiness. |

P0 is required for a usable release candidate. P1 is required before declaring version 1 complete. P2 may ship after the first stable release without changing the version-1 architecture.

## 3.2 Feature acceptance details

### F-001 — Skill management

- Name cannot be blank after trimming.
- Duplicate names are allowed only after a warning because two goals may intentionally share a name.
- Target may be changed without rewriting history.
- Archiving an active-timer skill is blocked until the session is stopped.
- Completed state is derived from totals and may return to active if the target is increased.
- Delete cascades only after explicit confirmation and snapshot creation.

### F-002 — Skills home

- Initial empty state has one dominant Create Skill action.
- Skill cards are sorted by user order, then creation date if no order exists.
- Drag-to-reorder is optional on mobile; explicit Move Up/Down actions are an accessible fallback.
- Expanding one card does not automatically collapse another unless mobile height becomes constrained.
- Recent sessions show duration, date, title or note excerpt, and source icon.

### F-003 — Stopwatch

- Start becomes durable before the UI reports Running.
- Button double taps cannot create duplicate sessions or segments.
- Pause and stop commands are idempotent.
- Reopening after process termination reconstructs the same duration from persisted anchors.
- Wall-clock discontinuity produces a review state rather than negative or implausible duration.

### F-004 — Flip clock

- Hours are not capped at 99 or 999.
- The component dynamically adds hour digits as required.
- Each digit has top and bottom panels, central hinge line, and optional shadow.
- Only changed digits animate.
- Reduced Motion replaces the flip with an immediate value transition or subtle fade.
- The clock remains legible at 200% text scaling.

### F-005 — Completion and notes

- Stop creates `completion_pending` before navigation.
- Closing the note editor cannot lose typed text.
- Empty note is valid.
- Markdown source is preserved exactly.
- Save changes status to `completed` in one transaction.

### F-006 — Learning Log

- First page loads the current month and surrounding metadata.
- Additional months load on demand.
- Search uses FTS when available and falls back gracefully during migration or repair.
- Search and filters combine with AND semantics; multiple selected tags may use ANY by default with an ALL option later.
- Clearing filters restores the previous scroll position when feasible.

### F-008/F-009 — Backup and import

- Export is marked successful only after the generated file can be parsed and verified.
- Import never mutates the active database before preview and confirmation.
- Replace imports restore settings and optional active timer after a separate confirmation.
- Merge imports do not treat overlapping times as duplicate sessions.
- Same UUID and same content is skipped.
- Same UUID and different content keeps the record with the newest `updated_at`.
- Equal timestamps with different hashes are surfaced as a conflict; default action keeps the current record unless the user explicitly prefers imported data.

### F-010 — Summary

- All durations are calculated from integer seconds.
- UI formatting never becomes the stored source of truth.
- Progress may exceed 100% and should show the exact value while visually indicating target completion.
- Remaining duration never displays a negative number.

### F-014 — Pomodoro

- Transition between phases persists state before alerting.
- A break may be skipped.
- Pausing a phase freezes the countdown.
- Restart recovery restores phase, cycle number, and remaining duration.
- Work completed before a crash is never lost.

### F-016 — Android notification

- Notification appears only during running or paused sessions.
- It includes skill name, mode/phase, and a system chronometer or derived elapsed display where feasible.
- Pause/Resume and Stop actions are routed through the same idempotent application commands as the UI.
- Android 14+ foreground-service type and Play declaration must be reviewed before store release; the implementation must not assume a generic service will always pass store policy.

### F-017 — Desktop integration

- Closing the window while a session is active may minimize to tray after explaining this behavior once.
- Tray menu: Show, Pause/Resume, Stop, Exit.
- Exit during an active session requires confirmation or leaves recovery state.
- Keyboard shortcuts are disabled while text fields are focused unless explicitly scoped.

---

# 4. UI/UX specification

## 4.1 Visual direction

Ayutam uses Material 3 as the structural design system with a dark productivity aesthetic and restrained GitHub-inspired visual language for data-dense components such as heatmaps, tags, and activity summaries.

Visual qualities:

- dark neutral surfaces rather than pure black everywhere;
- high-contrast flip cards as the hero element;
- subtle borders and elevation;
- monospace or tabular numerals for durations;
- one skill accent colour at a time in focused contexts;
- minimal gradients;
- animation used only to explain state or support the flip-clock identity;
- no decorative illustrations that compete with tracked information.

Both light and dark themes must exist. The default follows the operating system.

## 4.2 Design tokens

The final values belong in the design system, not repeated across features.

### Spacing

Use a 4-pixel base grid:

- `space-1`: 4;
- `space-2`: 8;
- `space-3`: 12;
- `space-4`: 16;
- `space-5`: 24;
- `space-6`: 32;
- `space-7`: 48;
- `space-8`: 64.

### Shape

- skill card radius: 16;
- dialogs and sheets: 20–28 depending on platform;
- small chips: fully rounded or 8 radius;
- flip cards: 8–16 radius with visible center split;
- focus outline: at least 2 logical pixels.

### Typography

- Use Material typography roles for labels and body text.
- Use tabular figures for all duration values.
- Flip-clock digits must be locally available and licensed for redistribution; a platform monospace fallback must be defined.
- Notes use readable proportional text; code uses monospace.

### Colour

- Theme neutral palette supplies background and surface colours.
- Skill accent colours must be checked against both themes.
- Heatmap uses five intensity steps plus empty state.
- Colour never acts as the only state indicator.

## 4.3 Information architecture

Primary navigation:

1. **Skills**
2. **Learning Log**
3. **Statistics**
4. **Settings**

Nested destinations:

- Create/Edit Skill;
- Immersive Timer;
- Session Completion;
- Session Detail/Edit;
- Manual Session;
- Backup Preview;
- Import Conflict Review;
- Diagnostics;
- Local Snapshots.

The Timer is intentionally nested because it only has meaning after selecting a skill.

## 4.4 Skills screen

### Mobile

- App bar: product name, search, overflow/settings shortcut.
- Optional backup-due banner below app bar.
- Filter chips: Active, Completed, Archived.
- Single-column skill panels.
- Floating or prominent bottom Create Skill button.
- Bottom navigation remains visible unless a sheet is open.

### Skill panel anatomy

1. Accent strip or subtle tinted border.
2. Skill name and overflow menu.
3. Accumulated / target duration.
4. Progress bar and percentage.
5. Remaining duration.
6. Large accessible Play icon button.
7. Expand/collapse affordance.
8. Expanded recent sessions and View All action.

The Play action must be visually dominant but not so large that every card becomes a control panel.

### Desktop

- Left navigation rail.
- Centered single-column skill list with a maximum readable width, approximately 900–1,100 logical pixels.
- Create Skill button in the top toolbar.
- Optional persistent search field.
- Avoid turning the home page into a dense multi-column dashboard.

## 4.5 Pre-session UI

Mobile bottom sheet and desktop dialog:

```text
AI Learning
220h 35m of 10,000h

[ Stopwatch ] [ Pomodoro ]
Pomodoro: 25m focus · 5m break · 4 cycles

Optional session title

[Cancel]                         [Start]
```

The mode selector remembers the last mode for the skill. Advanced Pomodoro settings remain one tap away and do not clutter the main sheet.

## 4.6 Immersive timer UI

### Stopwatch mode

```text
AI Learning

┌────┐ ┌────┐ ┌────┐
│220 │:│35  │:│42  │   <- accumulated skill time, dominant
└────┘ └────┘ └────┘
 HOURS  MINUTES SECONDS

Current session  02:14:08

          [ Pause ]    [ Stop ]
```

Controls are icons visually, but every control has:

- semantic label;
- tooltip on desktop;
- accessible name announced by screen readers;
- keyboard focus indication;
- minimum 48x48 touch area.

### Pomodoro mode

```text
AI Learning · Focus 2 of 4

┌────┐ ┌────┐
│18  │:│42  │          <- current phase countdown, dominant
└────┘ └────┘

Session active 42m 10s
Skill total 221h 17m

          [ Pause ]    [ Stop ]
```

### Orientation and chrome

- On Android phones, enter landscape when the timer opens if the setting is enabled.
- Hide normal bottom navigation and nonessential app chrome.
- Restore the prior allowed orientation when the timer route closes.
- Desktop opens an immersive responsive layout but does not force window fullscreen.
- Keep-screen-awake is applied only while the timer is visible and the setting is enabled.

## 4.7 Flip-clock motion specification

Each digit consists of:

- static previous lower half;
- animated previous top flap rotating downward;
- animated next lower flap completing the transition;
- static next upper half;
- center hinge/seam;
- subtle shadow changing during rotation.

Timing:

- total transition: approximately 350–550 ms;
- easing: fast-out-slow-in or a custom physical curve;
- second digits may use a shorter transition to avoid perpetual overlap;
- only the digit that changes animates;
- minute/hour cascades are sequenced within one frame window.

Battery and accessibility:

- do not animate unchanged digits;
- reduced motion disables 3D rotation;
- pause rendering updates when the app is not visible, while timestamps remain authoritative;
- do not use continuous particle, glow, or background animation.

## 4.8 Completion panel

Mobile: full-height bottom sheet or page. Desktop: centered modal with responsive width.

Sections:

1. Session summary card.
2. Optional title.
3. Markdown editor with Edit/Preview control.
4. Tag selector.
5. Edit Time action.
6. Save, Resume, and Discard actions.

The main action label remains **Save Session**, not “Save Note,” because the note is optional.

Autosave status appears subtly:

- Saving…
- Saved locally
- Save failed — Retry

## 4.9 Learning Log experience

### Mobile

- Top search field.
- Grouping selector: Day, Week, Month.
- Filter button showing active-filter count.
- Compact calendar accessible from the toolbar.
- Group headers remain sticky where practical.
- Session cards expand inline or open a detail page.

### Desktop

At widths of roughly 1,000 logical pixels and above:

- left pane: calendar, search/filter controls, grouped session list;
- right pane: selected session detail and rendered Markdown;
- divider is resizable only if implementation remains simple; otherwise fixed responsive proportions;
- selected card remains highlighted.

### Session card

Collapsed content:

- title, or first non-empty note line, or “Untitled session”;
- skill with accent indicator;
- date and start–end time;
- active duration;
- tag chips, limited with overflow count;
- note preview;
- source indicator for manual/Pomodoro/stopwatch;
- more menu.

Do not place permanent Edit and Delete buttons on every mobile card. Keep them in the detail view or overflow menu.

## 4.10 Statistics UX

### Header and scope

- Skill scope control: one skill, all skills, compare.
- Compact summary metrics remain visible above chart tabs.
- On mobile, summary metrics use a horizontally scrollable card row or two-column grid.
- On desktop, use a single compact row where width permits.

### View selector

- Mobile: segmented control for Progress, Activity, Summary.
- Desktop: tabs for Cumulative, Heatmap, Summary Table.

### Line chart

- Preserve a minimum chart height of 280 on mobile and 420 on desktop.
- Tooltips never obscure the selected point when avoidable.
- Range controls collapse into a menu on narrow layouts.
- Zoom reset action appears after zooming.
- Comparison mode uses both colour and line/dash/marker differences.

### Heatmap

- GitHub-inspired weekly columns and weekday rows.
- Month labels remain readable at small widths through horizontal scroll or compact sizing.
- Legend explains fixed ranges.
- Focus/tap shows exact date and duration.
- Selecting a day offers Open in Learning Log.

### Summary table

- Desktop uses a table with sortable period rows if useful.
- Mobile transforms each row into a compact period card or horizontally scrollable table.
- Change values include arrow/icon and text, not colour alone.

## 4.11 Backup UX

### Backup status card

```text
Backup status
Last successful backup: 18 days ago
27 sessions changed since backup
[Export now]
```

States:

- recent;
- due;
- never backed up;
- last export failed.

### Import preview

Display:

- file name;
- created date;
- source application version;
- format/schema version;
- source device ID shortened for readability;
- skills count;
- sessions count;
- total duration;
- active/pending timer presence;
- checksum and integrity result;
- encryption status.

Then show Merge and Replace with concise consequences.

## 4.12 Empty states

### No skills

> Create your first skill to begin tracking deliberate practice.

Primary action: Create Skill.

### No sessions

> Your completed sessions and learning notes will appear here.

Secondary action: Start a Session.

### No search results

> No sessions match the current search and filters.

Action: Clear Filters.

### No statistics

> Complete a session to begin building your progress chart.

### Never backed up

> Your progress currently exists only on this device.

Action: Create Backup.

## 4.13 Confirmation and undo model

Use Undo for:

- individual session delete;
- tag association removal;
- archive where easy to reverse.

Use explicit confirmation for:

- discarding active/completion-pending session;
- permanent skill delete;
- Replace import;
- Delete All Local Data;
- restoring an old local snapshot;
- exiting while an active timer would be affected.

---

# 5. Responsive mobile and desktop layout specification

## 5.1 Breakpoints

Use layout capabilities rather than device names, but the following starting points are acceptable:

| Width | Layout class |
|---:|---|
| `< 600` | Compact phone |
| `600–839` | Large phone / small tablet |
| `840–1199` | Tablet / compact desktop |
| `1200–1599` | Desktop |
| `>= 1600` | Wide desktop |

Breakpoints must be validated through actual content, text scaling, and window resizing.

## 5.2 Adaptive navigation

| Layout | Navigation |
|---|---|
| Compact and medium mobile | Bottom NavigationBar |
| Tablet/desktop | NavigationRail |
| Wide desktop | Extended NavigationRail or compact sidebar |
| Immersive timer | Navigation hidden |

## 5.3 Screen-by-screen adaptation

### Skills

- Compact: single-column cards, full-width.
- Tablet: single-column with larger margins; optional two-column only after usability review.
- Desktop: single centered column with max width and more information per card.
- Wide desktop: keep the central list; optionally show a narrow backup/recent-activity side panel only if it does not change the product’s minimal character.

### Timer

- Compact portrait before start; landscape during active timer when enabled.
- Landscape phone: clock consumes 60–75% of height.
- Tablet: centered clock with large digits; no forced orientation required.
- Desktop: responsive digit size limited to avoid comically large cards; controls remain reachable.

### Learning Log

- Compact: single-pane list and separate detail route.
- Large phone/tablet: list with expandable details.
- Desktop: two-pane master/detail.
- Wide desktop: calendar/filter column, session list, and detail may become three regions only if tested; two-pane remains the baseline.

### Statistics

- Compact: stacked summary cards, segmented view, horizontally scrollable heatmap.
- Tablet: two-column summary metrics and larger chart.
- Desktop: full summary row, tabs, hover tooltips.
- Full-screen chart can temporarily hide surrounding controls.

### Settings

- Compact: grouped list with nested setting pages.
- Desktop: category list on left and setting panel on right.

## 5.4 Input adaptation

- Touch: minimum 48x48 logical-pixel targets.
- Mouse: hover states, tooltips, context menus where conventional.
- Keyboard: tab order, shortcuts, Enter/Space activation, Escape close.
- Drag and drop: desktop import drop zone, with File Picker fallback.
- External keyboard on Android: standard focus and shortcuts where safe.

## 5.5 Orientation behavior

- General Android UI supports portrait and landscape.
- Active timer requests landscape on phones by default.
- User may disable forced landscape.
- If system rotation is locked and the platform refuses orientation change, the timer remains usable in portrait.
- Do not force orientation on desktop or large tablets.

---

# 6. Technical architecture

## 6.1 Architecture style

Use a **feature-based modular architecture** with explicit presentation, application, domain, and data boundaries. Avoid strict enterprise Clean Architecture ceremony such as one class per trivial operation, but preserve dependency direction.

```text
Flutter UI / Platform Views
        │
        ▼
Presentation state and controllers (Riverpod)
        │
        ▼
Application services / use cases
        │
        ▼
Domain models and repository contracts
        │
        ▼
Repositories
   ┌────┴───────────┬─────────────────┐
   ▼                ▼                 ▼
Drift/SQLite   File/backup I/O   Platform services
                                    │
                    Android foreground service,
                    desktop tray, shortcuts,
                    orientation, wakelock
```

Rules:

- Widgets do not execute SQL.
- Platform plugins do not determine domain truth.
- Repositories are the only source of persisted domain data.
- Application commands own transactions and validation.
- Statistics queries may use specialized read services but remain testable.
- Timer truth is persisted state plus timestamps, not animation ticks.

## 6.2 Recommended stack

- Flutter stable channel pinned through repository tooling.
- Dart null safety and strict analysis.
- Material 3.
- Riverpod for state management and dependency injection.
- Drift using native SQLite for Android, Windows, and Linux.
- Standard `Navigator`/`MaterialPageRoute` for version 1 unless route complexity grows; do not use legacy named routes.
- `fl_chart` as initial line-chart library behind a small chart adapter.
- Custom heatmap widget for precise GitHub-inspired behavior and reduced dependency count.
- Custom flip-clock widget rather than relying on an inflexible novelty package.

### Navigation decision

Declarative routing such as `go_router` provides centralized route configuration, deep-link handling, nested navigation, redirects, and route-state restoration. Ayutam has no web URLs, no authentication redirects, and a modest route tree. Standard Navigator APIs are therefore sufficient and simpler for version 1.

Use `go_router` later if any of these become real requirements:

- deep links to skills or sessions;
- complex nested shell navigation;
- platform app links;
- restoration of multiple navigation stacks;
- route-level guards that become difficult to test imperatively.

Do not use `Navigator.pushNamed`; use typed route-builder functions or `MaterialPageRoute` so arguments remain compile-time visible.

## 6.3 Component responsibilities

### Presentation

- adaptive screens and components;
- form validation messages;
- visual timer rendering;
- chart rendering;
- accessibility semantics;
- no direct file or database mutation.

### Application services

Examples:

- `StartSessionService`;
- `PauseSessionService`;
- `ResumeSessionService`;
- `StopSessionService`;
- `FinalizeSessionService`;
- `RecoverSessionService`;
- `ImportBackupService`;
- `ExportBackupService`;
- `MergeDatasetService`;
- `StatisticsService`;
- `SnapshotService`.

Each service accepts domain input, coordinates repositories, and returns a typed result.

### Domain

Contains:

- entities;
- value objects such as `DurationSeconds`, `SkillTarget`, and `TimeRange`;
- timer state machine;
- calculation policies;
- repository interfaces;
- conflict-resolution policy;
- validation rules.

It must not import Flutter widgets or platform plugins.

### Data

- Drift tables and DAOs;
- repository implementations;
- JSON mappers;
- backup archive reader/writer;
- checksum service;
- local snapshot manager;
- diagnostic logger.

### Platform services

Interfaces in shared code with platform implementations:

- `ForegroundTimerService`;
- `TrayService`;
- `ShortcutService`;
- `OrientationService`;
- `ScreenAwakeService`;
- `FileDialogService`;
- `UpdateCheckService`.

## 6.4 Concurrency and isolates

- Run the Drift database in a background isolate where supported.
- Heavy JSON serialization, archive compression, checksum computation, large CSV export, and statistics aggregation over large ranges should run outside the UI isolate.
- All database writes go through one coordinated database connection to preserve transaction behavior.
- UI state observes repository streams or invalidates providers after command completion.
- Do not use multiple independent SQLite writers.

## 6.5 Offline and network model

Core build behavior:

- no network is required;
- no startup request;
- no remote fonts;
- no remote Markdown assets;
- no telemetry endpoint;
- no backend configuration.

Optional GitHub release checks:

- are isolated behind `UpdateCheckService`;
- may use the public GitHub Releases API or release feed;
- require no custom backend;
- are disabled or manual by default;
- failure never affects app startup or core behavior.

## 6.6 Android foreground behavior

The timer remains accurate from timestamps even without continuously executing Dart. A foreground service is used for a visible ongoing notification and action controls, not as the only clock.

Implementation requirements:

- begin only after a user starts a session;
- stop when no session is running or paused;
- persist action commands before updating notification state;
- declare current Android foreground-service permissions and type correctly;
- perform a Play policy review before store submission;
- avoid boot-time service restart unless platform rules and policy permit it;
- on device boot, the app can recover persisted timer state when opened even if a service did not restart.

A plugin may be used after a proof-of-concept, but the platform interface must allow replacement with native Kotlin if policy or plugin maintenance requires it.

## 6.7 Desktop lifecycle

- Window close with no active session exits normally.
- Window close with active session defaults to minimize-to-tray after first-run explanation.
- Explicit Exit runs a guarded command.
- System tray and global shortcuts must be optional features that degrade gracefully on unsupported Linux desktop environments.
- The database remains valid if tray initialization fails.

## 6.8 Error model

Use typed results and domain failures, not unstructured strings.

Example categories:

- validation failure;
- database failure;
- file permission failure;
- unsupported backup version;
- checksum failure;
- integrity failure;
- conflict requiring input;
- platform integration unavailable;
- clock discontinuity;
- insufficient storage;
- encryption failure.

Every user-facing error contains:

- concise explanation;
- whether data was changed;
- retry/recovery action;
- diagnostic code suitable for logs.

## 6.9 Logging

Local structured logs only:

- rolling files with size/count limits;
- no note content by default;
- no PIN, passphrase, or encryption key;
- record IDs may be shortened or hashed in normal logs;
- user can export diagnostics explicitly;
- debug builds may log more detail but must never log secrets.

## 6.10 Packaging and release architecture

Repository must support:

- Android debug APK and signed release APK/AAB later;
- Windows build and installer packaging;
- Linux x64 build with `.deb` and/or AppImage packaging;
- GitHub Actions matrix for tests and release artifacts;
- semantic versioning;
- generated changelog or release notes;
- reproducible dependency lockfile;
- store metadata kept outside core application code.


---

# 7. Flutter project structure

## 7.1 Recommended repository layout

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
├── .github/
│   ├── workflows/
│   │   ├── validate.yml
│   │   ├── android-release.yml
│   │   ├── windows-release.yml
│   │   └── linux-release.yml
│   ├── ISSUE_TEMPLATE/
│   └── pull_request_template.md
├── docs/
│   ├── architecture/
│   │   ├── decisions/
│   │   ├── database.md
│   │   ├── backup-format.md
│   │   └── timer-recovery.md
│   ├── testing/
│   ├── release/
│   └── design/
├── assets/
│   ├── icons/
│   ├── sounds/
│   └── licences/
├── lib/
│   ├── main.dart
│   ├── bootstrap.dart
│   ├── app/
│   │   ├── ayutam_app.dart
│   │   ├── app_theme.dart
│   │   ├── app_routes.dart
│   │   └── app_lifecycle.dart
│   ├── core/
│   │   ├── errors/
│   │   ├── result/
│   │   ├── time/
│   │   ├── logging/
│   │   ├── constants/
│   │   ├── validation/
│   │   └── widgets/
│   ├── database/
│   │   ├── app_database.dart
│   │   ├── tables/
│   │   ├── daos/
│   │   ├── migrations/
│   │   ├── fts/
│   │   └── database_provider.dart
│   ├── features/
│   │   ├── skills/
│   │   │   ├── domain/
│   │   │   ├── application/
│   │   │   ├── data/
│   │   │   └── presentation/
│   │   ├── timer/
│   │   │   ├── domain/
│   │   │   ├── application/
│   │   │   ├── data/
│   │   │   └── presentation/
│   │   ├── sessions/
│   │   ├── learning_log/
│   │   ├── statistics/
│   │   ├── backup/
│   │   ├── settings/
│   │   ├── onboarding/
│   │   └── diagnostics/
│   └── platform/
│       ├── foreground_timer/
│       ├── tray/
│       ├── shortcuts/
│       ├── orientation/
│       ├── screen_awake/
│       ├── file_dialogs/
│       └── update_check/
├── test/
│   ├── unit/
│   ├── database/
│   ├── migrations/
│   ├── widgets/
│   ├── fixtures/
│   └── golden/               # limited, only stable core components
├── integration_test/
│   ├── timer_recovery_test.dart
│   ├── backup_round_trip_test.dart
│   ├── cross_platform_fixture_test.dart
│   └── primary_user_journey_test.dart
├── tool/
│   ├── generate_large_fixture.dart
│   ├── verify_backup.dart
│   ├── export_schema.dart
│   └── licence_report.dart
├── android/
├── windows/
└── linux/
```

## 7.2 Feature module pattern

Each significant feature may contain:

```text
feature/
├── domain/
│   ├── entities/
│   ├── value_objects/
│   ├── repositories/
│   └── policies/
├── application/
│   ├── services/
│   ├── commands/
│   ├── queries/
│   └── dto/
├── data/
│   ├── repositories/
│   ├── mappers/
│   └── data_sources/
└── presentation/
    ├── controllers/
    ├── screens/
    ├── widgets/
    └── models/
```

Do not create empty layers merely to satisfy the pattern. Small features can combine files while preserving dependency direction.

## 7.3 Naming rules

- Screens: `SkillsScreen`, `LearningLogScreen`.
- Controllers/notifiers: `SkillsController`, `TimerController`.
- Application services: verb-first names such as `StartSessionService`.
- Repositories: `SessionRepository` interface and `DriftSessionRepository` implementation.
- Drift tables: plural Dart class names mapped to snake_case SQL tables.
- DTOs must not leak into the domain or widgets without explicit mapping.
- Avoid generic names such as `Helper`, `Manager`, or `Utils` unless scope is extremely clear.

## 7.4 Build configuration

Recommended flavors or build configurations:

- `dev` — diagnostics enabled, test database tools available;
- `staging` — release-like build using local data only;
- `prod` — normal user release.

No flavor requires a backend URL. Build variants may differ in logging level, application ID, signing, and update channel.

---

# 8. State-management design

## 8.1 Riverpod role

Riverpod is used for:

- dependency injection;
- screen-level asynchronous state;
- repository streams;
- command coordination;
- form drafts where persistence is also handled by application services;
- platform-service availability.

Riverpod must not become an alternate database. Long-lived state belongs in SQLite.

## 8.2 Provider categories

### Infrastructure providers

- database connection;
- repositories;
- clock abstraction;
- file-dialog service;
- platform integrations;
- logger;
- checksum/encryption services.

### Query providers

- active skills;
- recent sessions by skill;
- active session;
- completion-pending session;
- Learning Log page/query;
- summary metrics;
- cumulative series;
- heatmap data;
- backup status.

### Controller providers

- skills controller;
- timer controller;
- completion controller;
- Learning Log filter controller;
- statistics controller;
- backup/import controller;
- settings controller.

## 8.3 State rules

1. Persist first, then publish success.
2. Commands expose `loading`, `success`, and typed failure.
3. Repeated commands are idempotent or rejected by state preconditions.
4. UI timers may rebuild every second, but database writes occur only on state transitions or periodic safety checkpoints, not every second.
5. A screen must recover from provider recreation using repository state.
6. Provider overrides are used in tests for fake clocks, temporary databases, and platform services.

## 8.4 Timer controller

The timer controller observes the persisted active session and produces a display model:

```text
TimerDisplayState
- sessionId
- skillId
- mode
- machineState
- accumulatedSkillSeconds
- currentSessionActiveSeconds
- currentPhaseRemainingSeconds
- pomodoroCycle
- longSessionWarningDue
- recoveryReviewRequired
```

The controller does not increment the canonical duration. It asks a clock abstraction for `now`, combines it with persisted anchors, and formats the result.

## 8.5 Learning Log filter state

```text
LearningLogFilter
- searchQuery
- skillIds
- fromDate
- toDate
- minDurationSeconds
- maxDurationSeconds
- notePresence
- tagIds
- sources
- sortOrder
- grouping
```

The filter is serializable to local UI preferences if desired but is not included in backups unless treated as a user setting.

## 8.6 Statistics state

```text
StatisticsSelection
- scope: selectedSkill | allSkills | comparison
- skillIds
- view: cumulative | heatmap | summary
- presetRange
- customRange
- summaryGranularity
```

Chart data is immutable and computed by query services. Zoom/pan viewport is ephemeral UI state.

---

# 9. Database schema

## 9.1 Database choice

Use Drift with native SQLite on Android, Windows, and Linux. SQLite is appropriate because the data is structured, relational, local, and query-heavy enough to benefit from indexes and transactions. The projected note volume is modest; 100,000 sessions with several kilobytes of text remains well within SQLite’s practical capabilities.

The database file should be stored in the platform application-support/data directory, not a user-selected arbitrary path. User-selected files are exports, not the live database.

## 9.2 General conventions

- IDs: UUID strings, preferably UUID v4 unless a maintained UUID v7 implementation is selected and documented.
- Timestamps: integer microseconds or milliseconds since Unix epoch in UTC; use one precision consistently.
- Durations: integer seconds.
- Booleans: SQLite integer mapped by Drift.
- Enumerations: stable text values or validated integers; text improves backup readability.
- Every mutable syncable record includes `created_at_utc`, `updated_at_utc`, and `source_device_id`.
- Foreign keys enabled.
- WAL mode permitted for normal use, with consistent backup APIs rather than raw file copy.
- Statistics are derived, not stored as authoritative counters.

## 9.3 Tables

### `skills`

| Column | Type | Rules |
|---|---|---|
| `id` | TEXT PK | UUID |
| `name` | TEXT | required, trimmed |
| `description_markdown` | TEXT NULL | optional |
| `target_seconds` | INTEGER | > 0, default 36,000,000 |
| `created_local_date` | TEXT | ISO `YYYY-MM-DD` |
| `accent_argb` | INTEGER NULL | nullable colour |
| `status` | TEXT | active/completed/archived |
| `sort_order` | INTEGER | stable home ordering |
| `created_at_utc` | INTEGER | required |
| `updated_at_utc` | INTEGER | required |
| `source_device_id` | TEXT | required |

Indexes:

- `skills(status, sort_order)`;
- optional case-folded name index for search.

`status = completed` may be reconciled from totals and target during startup/migrations. Archived state must not be overwritten by completion derivation.

### `sessions`

| Column | Type | Rules |
|---|---|---|
| `id` | TEXT PK | UUID |
| `skill_id` | TEXT FK | references skills |
| `title` | TEXT NULL | optional |
| `note_markdown` | TEXT NULL | optional |
| `mode` | TEXT | stopwatch, pomodoro, manual |
| `status` | TEXT | active, paused, completion_pending, completed |
| `source` | TEXT | timer, manual, imported |
| `start_at_utc` | INTEGER | required |
| `end_at_utc` | INTEGER NULL | null until stopped |
| `active_seconds` | INTEGER | >= 0 |
| `paused_seconds` | INTEGER | >= 0 |
| `timezone_id_at_creation` | TEXT | IANA identifier |
| `offset_minutes_at_start` | INTEGER | audit/display fallback |
| `created_at_utc` | INTEGER | required |
| `updated_at_utc` | INTEGER | required |
| `source_device_id` | TEXT | required |
| `deleted_at_utc` | INTEGER NULL | short-lived undo/soft delete |

Indexes:

- `sessions(skill_id, status, start_at_utc DESC)`;
- `sessions(status, start_at_utc DESC)`;
- `sessions(updated_at_utc)` for merge;
- `sessions(deleted_at_utc)`.

Application invariant: at most one session is `active`, `paused`, or `completion_pending`. Enforce through transactions and, where reliable, a partial unique index on a constant expression for active states.

### `session_segments`

| Column | Type | Rules |
|---|---|---|
| `id` | TEXT PK | UUID |
| `session_id` | TEXT FK | cascade delete |
| `segment_type` | TEXT | work, pause, pomodoro_break |
| `pomodoro_phase` | TEXT NULL | focus, short_break, long_break |
| `cycle_number` | INTEGER NULL | 1-based |
| `start_at_utc` | INTEGER | required |
| `end_at_utc` | INTEGER NULL | current segment may be open |
| `duration_seconds` | INTEGER | persisted closed duration |
| `created_at_utc` | INTEGER | required |
| `updated_at_utc` | INTEGER | required |

Indexes:

- `session_segments(session_id, start_at_utc)`;
- `session_segments(start_at_utc)` for daily split queries if required.

Segments provide recovery, cross-midnight allocation, and Pomodoro detail. `sessions.active_seconds` and `paused_seconds` are cached canonical totals maintained transactionally from segments and verified by integrity checks.

### `timer_runtime`

Singleton row for state that is operational rather than historical.

| Column | Type | Rules |
|---|---|---|
| `singleton_id` | INTEGER PK | always 1 |
| `session_id` | TEXT FK NULL | active/pending session |
| `machine_state` | TEXT | idle, running, paused, focus, short_break, long_break, completion_pending, recovery_review |
| `current_segment_id` | TEXT NULL | open segment |
| `phase_planned_seconds` | INTEGER NULL | Pomodoro |
| `phase_started_at_utc` | INTEGER NULL | Pomodoro |
| `phase_accumulated_seconds` | INTEGER | excludes pause |
| `current_cycle` | INTEGER | default 1 |
| `monotonic_anchor_micros` | INTEGER NULL | valid only within process/boot |
| `wall_clock_anchor_utc` | INTEGER NULL | persisted recovery anchor |
| `last_checkpoint_at_utc` | INTEGER | required |
| `recovery_reason` | TEXT NULL | restart, clock_change, long_gap |
| `updated_at_utc` | INTEGER | required |

All transitions that change a session also update this row in the same transaction.

### `tags`

| Column | Type | Rules |
|---|---|---|
| `id` | TEXT PK | UUID |
| `name` | TEXT | required |
| `normalized_name` | TEXT UNIQUE | case-folded/trimmed |
| `created_at_utc` | INTEGER | required |
| `updated_at_utc` | INTEGER | required |
| `source_device_id` | TEXT | required |

### `session_tags`

| Column | Type | Rules |
|---|---|---|
| `session_id` | TEXT FK | cascade delete |
| `tag_id` | TEXT FK | cascade delete |

Composite primary key: `(session_id, tag_id)`.

### `app_settings`

| Column | Type | Rules |
|---|---|---|
| `key` | TEXT PK | documented setting key |
| `value_json` | TEXT | JSON scalar/object |
| `updated_at_utc` | INTEGER | required |
| `source_device_id` | TEXT | required for mergeable settings |

Settings keys must be defined centrally with typed codecs and defaults.

### `backup_history`

| Column | Type | Rules |
|---|---|---|
| `id` | TEXT PK | UUID |
| `backup_type` | TEXT | portable, json, sqlite, csv, markdown |
| `destination_display` | TEXT NULL | sanitized path/name |
| `created_at_utc` | INTEGER | attempt start |
| `verified_at_utc` | INTEGER NULL | only on success |
| `session_high_watermark_utc` | INTEGER NULL | newest updated record included |
| `skills_count` | INTEGER | export summary |
| `sessions_count` | INTEGER | export summary |
| `total_active_seconds` | INTEGER | export summary |
| `file_sha256` | TEXT NULL | when available |
| `status` | TEXT | success, failed, cancelled |
| `error_code` | TEXT NULL | no sensitive detail |

### `local_snapshots`

| Column | Type | Rules |
|---|---|---|
| `id` | TEXT PK | UUID |
| `file_path` | TEXT | app-private location |
| `reason` | TEXT | pre_import, pre_delete, pre_restore, migration |
| `created_at_utc` | INTEGER | required |
| `schema_version` | INTEGER | required |
| `file_sha256` | TEXT | required |
| `size_bytes` | INTEGER | required |
| `is_valid` | INTEGER | integrity status |

Retain the latest three valid snapshots by default, excluding a snapshot currently needed for recovery.

### `device_identity`

Singleton:

| Column | Type | Rules |
|---|---|---|
| `device_id` | TEXT PK | random UUID, no hardware identifier |
| `created_at_utc` | INTEGER | required |
| `display_name` | TEXT NULL | optional user label such as “Windows laptop” |

Never use IMEI, serial number, advertising ID, or another stable hardware identifier.

### `schema_metadata`

| Column | Type | Rules |
|---|---|---|
| `key` | TEXT PK | metadata key |
| `value` | TEXT | value |

Includes logical data-format version independently from Drift’s schema version when needed.

## 9.4 Full-text search

Use SQLite FTS5 for:

- session title;
- note Markdown source;
- skill-name projection if useful;
- tag-name projection if denormalized.

Recommended virtual table:

```sql
CREATE VIRTUAL TABLE session_search USING fts5(
  session_id UNINDEXED,
  title,
  note_markdown,
  skill_name,
  tags_text,
  tokenize = 'unicode61 remove_diacritics 2'
);
```

Maintain through explicit repository updates or triggers. Rebuild command must exist in diagnostics. Search results always join back to non-deleted completed sessions.

## 9.5 Daily allocation query

Statistics must allocate each work segment across configured-timezone day boundaries. Do not assign an entire cross-midnight session to its start date.

Implementation options:

1. calculate allocations in Dart from segment ranges for requested date windows;
2. maintain a derived `daily_skill_totals` cache rebuilt transactionally;
3. use SQL recursive/time functions cautiously.

Recommended initial design: calculate from indexed segments for normal ranges and introduce a derived cache only after profiling the 100,000-session fixture. Correctness takes priority over premature caching.

## 9.6 Integrity checks

Run or expose checks for:

- `PRAGMA foreign_key_check`;
- `PRAGMA integrity_check` or quick check during normal diagnostics;
- no negative durations;
- no end before start;
- closed completed sessions have no open segment;
- session cached totals equal segment sums;
- at most one non-completed session;
- timer runtime references a valid active/pending session;
- tag associations reference valid rows;
- skill target greater than zero;
- backup-history success rows contain verification timestamp.

## 9.7 Migrations

Every schema version must include:

- forward migration;
- generated schema snapshot;
- migration test from each supported prior release;
- integrity assertions after migration;
- backup import compatibility test;
- recovery behavior if migration fails.

Before a risky migration, create an app-private SQLite snapshot. On failure, do not repeatedly attempt destructive migration without presenting recovery options.

---

# 10. Import/export file schema

## 10.1 Export types

| Format | Extension | Restore capable | Purpose |
|---|---|---:|---|
| Portable archive | `.skilltracker` | Yes | Canonical cross-platform backup and merge |
| Human-readable JSON | `.json` | Yes | Transparent interchange/debugging |
| SQLite snapshot | `.sqlite` | Yes, primarily replace | Exact database snapshot |
| Session CSV | `.csv` | No | Spreadsheet/report use |
| Skill notes Markdown | `.md` or `.zip` | No | Human-readable journal export |

## 10.2 Portable archive structure

File name:

```text
ayutam-backup-YYYY-MM-DD-HHmmss.skilltracker
```

Do not include a skill name in full backup names.

Archive contents:

```text
manifest.json
payload/data.json
checksums.sha256
README.txt                 # optional human recovery note
```

Encrypted variant:

```text
manifest.json              # non-sensitive format/encryption metadata
payload/data.enc           # AES-256-GCM encrypted JSON or compressed JSON
checksums.sha256
```

The archive uses ZIP compression. Paths are fixed and extraction rejects path traversal, duplicate names, symlinks, unexpected executables, and excessive decompressed size.

## 10.3 Manifest schema

Example:

```json
{
  "format": "ayutam-portable-backup",
  "formatVersion": 1,
  "createdAtUtc": "2026-07-21T12:30:45.123Z",
  "applicationVersion": "1.0.0",
  "databaseSchemaVersion": 1,
  "sourcePlatform": "windows",
  "sourceDeviceId": "d644fe5e-646e-4d79-b6c1-4a4e4016df08",
  "timezone": "Asia/Kolkata",
  "encrypted": false,
  "compression": "zip-deflate",
  "payload": {
    "path": "payload/data.json",
    "mediaType": "application/json",
    "sha256": "...",
    "uncompressedBytes": 123456
  },
  "summary": {
    "skills": 4,
    "sessions": 1284,
    "completedActiveSeconds": 8662500,
    "tags": 17,
    "containsActiveOrPendingSession": false
  }
}
```

When encrypted, include:

```json
{
  "encryption": {
    "algorithm": "AES-256-GCM",
    "keyDerivation": "Argon2id",
    "saltBase64": "...",
    "nonceBase64": "...",
    "memoryKiB": 65536,
    "iterations": 3,
    "parallelism": 1
  }
}
```

Exact cryptographic parameters require a security review and performance testing on baseline Android devices. Never invent a custom cipher.

## 10.4 Data payload schema

Top-level example:

```json
{
  "dataVersion": 1,
  "exportedAtUtc": "2026-07-21T12:30:45.123Z",
  "skills": [],
  "sessions": [],
  "sessionSegments": [],
  "tags": [],
  "sessionTags": [],
  "settings": [],
  "timerRuntime": null,
  "deviceMetadata": [],
  "backupMetadata": {
    "lastSuccessfulBackupAtUtc": "2026-07-21T12:30:45.123Z"
  }
}
```

### Skill record

```json
{
  "id": "uuid",
  "name": "AI Learning",
  "descriptionMarkdown": "",
  "targetSeconds": 36000000,
  "createdLocalDate": "2026-07-09",
  "accentArgb": 4283215696,
  "status": "active",
  "sortOrder": 0,
  "createdAtUtc": "2026-07-09T10:00:00Z",
  "updatedAtUtc": "2026-07-20T12:00:00Z",
  "sourceDeviceId": "uuid"
}
```

### Session record

```json
{
  "id": "uuid",
  "skillId": "uuid",
  "title": "Transformer attention study",
  "noteMarkdown": "Studied **attention mechanisms**...",
  "mode": "stopwatch",
  "status": "completed",
  "source": "timer",
  "startAtUtc": "2026-07-09T13:30:00Z",
  "endAtUtc": "2026-07-09T15:30:00Z",
  "activeSeconds": 7200,
  "pausedSeconds": 0,
  "timezoneIdAtCreation": "Asia/Kolkata",
  "offsetMinutesAtStart": 330,
  "createdAtUtc": "2026-07-09T13:30:00Z",
  "updatedAtUtc": "2026-07-09T15:35:00Z",
  "sourceDeviceId": "uuid"
}
```

The JSON format must document every field, nullability, enum value, and migration rule in `docs/architecture/backup-format.md`, even though this consolidated document remains the primary product specification.

## 10.5 Checksum file

Example:

```text
<sha256>  manifest.json
<sha256>  payload/data.json
```

The manifest payload hash must match the checksum file. Import validates archive entries before parsing full data.

## 10.6 Human-readable JSON export

The standalone JSON export uses the same logical payload and data version as the portable archive. It may omit archive manifest details but must include:

- format identifier;
- format version;
- export timestamp;
- application version;
- checksum stored alongside or embedded over a canonical payload representation.

Because whitespace and key ordering can change, do not calculate a checksum over a JSON object after reparsing unless canonical JSON rules are defined. Prefer hashing the exact UTF-8 file bytes.

## 10.7 SQLite snapshot export

Do not copy the live `.sqlite` file directly while WAL writes may be active. Use a consistent SQLite backup mechanism such as `VACUUM INTO` or the Online Backup API through supported bindings.

Snapshot workflow:

1. block new destructive commands briefly;
2. flush pending database work;
3. create snapshot into a new temporary file;
4. run integrity check on the snapshot;
5. calculate SHA-256;
6. move/copy through the platform save dialog;
7. re-open or inspect schema metadata to verify;
8. record backup success.

SQLite snapshots are tied more closely to database schema than portable JSON. Newer apps must migrate older snapshots after replace restore. Forward-incompatible snapshots are rejected.

## 10.8 CSV export

UTF-8 with header row. Recommended columns:

```text
session_id,skill_name,title,start_time,end_time,timezone,
active_seconds,paused_seconds,mode,source,tags,note_markdown
```

Requirements:

- RFC 4180-compatible quoting;
- preserve newlines within quoted notes;
- optionally omit note text through an export option;
- timestamps in ISO 8601 using configured timezone plus offset;
- no formula execution mitigation is optional but recommended: prefix cells beginning with `=`, `+`, `-`, or `@` when exporting user-controlled text for spreadsheet safety, with a documented choice.

CSV is not importable in version 1.

## 10.9 Markdown skill export

One selected skill exports:

```markdown
# AI Learning

Target: 10,000 hours  
Tracked: 220h 35m  
Exported: 21 July 2026

## 9 July 2026 — Transformer attention study

- Time: 7:00 PM–9:00 PM
- Duration: 2h
- Tags: transformers, study

Studied **attention mechanisms**...
```

If multiple files are generated, package as ZIP with one Markdown file per month or year and an index. This export is human-readable and not intended for restore.

---

# 11. Backup migration and conflict-resolution specification

## 11.1 Validation stages

### Stage 1 — File validation

- supported extension or recognizable magic/format;
- maximum file and decompressed size;
- readable permissions;
- valid ZIP structure where applicable;
- no unsafe archive entries.

### Stage 2 — Manifest validation

- correct product format;
- supported format version;
- required fields;
- payload path exists;
- encryption metadata valid;
- application version informational only;
- database schema version checked for SQLite snapshots.

### Stage 3 — Cryptographic/integrity validation

- checksum file valid;
- payload hash matches;
- decryption authentication succeeds;
- JSON parses under bounded resource limits.

### Stage 4 — Semantic validation

- UUID format;
- required relationships;
- non-negative durations;
- end not before start;
- valid enum values;
- no duplicate primary IDs within payload;
- cached active totals agree with segments within a documented tolerance;
- one active/pending session maximum;
- settings use known or safely ignorable keys.

### Stage 5 — Preview

No active data has changed. Show counts, totals, versions, source, active timer presence, and warnings.

## 11.2 Replace import

Replace is the recommended restore method when the backup is the authoritative latest copy.

Process:

1. Acquire import lock.
2. Ensure no unreviewed active session, or include it in the pre-import snapshot.
3. Create and verify local snapshot.
4. Build a new temporary database from imported normalized data.
5. Run migrations to current schema.
6. Run integrity checks and summary verification.
7. Atomically swap databases where platform file semantics permit, or replace data in one transaction.
8. Reopen database and verify again.
9. Keep pre-import snapshot until at least the next successful startup.
10. Update backup history and display completion report.

The user must separately confirm restoration of an active/paused timer because it may begin counting immediately.

## 11.3 Merge import

Merge is supported without a backend because every mergeable entity has a globally unique ID and update timestamp.

### Merge identity

- Same UUID means the same logical record lineage.
- Different UUIDs are distinct records even if their timestamps overlap or content appears similar.
- Do not use time overlap, title, or note similarity as automatic duplicate criteria.

### Last-write-wins rule

For each matching UUID:

1. If content hashes match, skip.
2. If imported `updated_at` is newer, use imported record.
3. If current `updated_at` is newer, keep current record.
4. If timestamps are equal and hashes differ, create a conflict item.
5. Conflict default is Keep Current; user may choose Prefer Imported for all or individually.

This implements the user decision “keep newest” while preventing arbitrary loss on timestamp ties.

### Deletions

Version 1 does not synchronize permanent-deletion tombstones indefinitely. Therefore:

- a record deleted on device A and still present in an older device B backup may reappear during merge;
- Replace avoids this issue;
- merge preview must state this limitation;
- future format versions may include tombstones with retention windows.

For individual session soft deletes that have not been purged, include `deleted_at` and apply newest-state logic.

### Referential ordering

Merge in this order:

1. devices and metadata;
2. skills;
3. tags;
4. sessions;
5. session segments;
6. session-tag links;
7. mergeable settings;
8. timer runtime after separate conflict review.

### Settings merge

- User-specific display settings: newest update wins.
- Device-specific settings such as export path, window size, tray behavior, and notification permission are never imported over the current device.
- Timezone and theme are portable user settings.
- Local PIN hash, secure-storage references, and device permissions are never exported or merged.

## 11.4 Import of active session

If the backup contains an active, paused, or completion-pending session:

- preview clearly identifies it;
- if current app also has one, merge cannot silently select between them;
- choices:
  - keep current active session and import the other as completion-pending;
  - replace current with imported active session after snapshot;
  - import the other as a completed/manual session with reviewed end time;
  - cancel.

Only one active timer invariant remains mandatory.

## 11.5 Backward and forward compatibility

- Newer app versions must import every released older portable format through explicit migrations.
- A backup with a newer unsupported format is rejected without mutation and shows the minimum required application version when present.
- Unknown optional fields are ignored and preserved only if the data model supports extension storage; unknown required fields or enum values fail validation.
- Export format version changes independently from database schema version.

## 11.6 Recovery after failed import

If failure occurs before commit, rollback and leave current data unchanged.

If failure occurs during database swap or application restart:

1. detect incomplete import marker;
2. validate current database;
3. restore pre-import snapshot if current database is invalid;
4. retain failed import diagnostics;
5. explain recovery result to the user.

No import code path may leave a partially merged dataset without an explicit error and recovery marker.

---

# 12. Timer state machine

## 12.1 States

```text
IDLE
  │ start stopwatch
  ▼
RUNNING ──pause──> PAUSED
  │                  │
  │ stop             │ resume
  ▼                  ▼
COMPLETION_PENDING <-┘
  │ save
  ▼
COMPLETED

RUNNING/PAUSED ──crash, restart, clock anomaly──> RECOVERY_REVIEW
RECOVERY_REVIEW ──continue──> RUNNING or PAUSED
RECOVERY_REVIEW ──stop/edit──> COMPLETION_PENDING
RECOVERY_REVIEW ──discard──> IDLE
```

Pomodoro expands running states:

```text
FOCUS_RUNNING <-> FOCUS_PAUSED
      │ phase complete
      ▼
BREAK_READY -> SHORT_BREAK_RUNNING / LONG_BREAK_RUNNING
      │ break complete or skip
      ▼
FOCUS_READY -> FOCUS_RUNNING
```

All non-idle states reference one persisted session.

## 12.2 Transition table

| Current | Command/event | Preconditions | Persisted effects | Next |
|---|---|---|---|---|
| Idle | Start stopwatch | no active session | create session, work segment, runtime | Running |
| Idle | Start Pomodoro | no active session | create session, focus segment, config/runtime | Focus Running |
| Running | Pause | open work segment | close segment, open pause, update totals | Paused |
| Paused | Resume | open pause segment | close pause, open work | Running |
| Running/Paused | Stop | valid session | close segment, set end/totals/status | Completion Pending |
| Completion Pending | Resume | pending session exists | clear end, open work, status active | Running |
| Completion Pending | Save | valid fields | finalize status completed | Idle |
| Completion Pending | Discard | confirmed | delete pending session/runtime | Idle |
| Any active | Process termination | persisted state exists | no immediate mutation | same logical state |
| App startup | Recover | active/pending exists | recalc, validate | active or Recovery Review |
| Active | Clock anomaly | discrepancy over tolerance | persist reason | Recovery Review |
| Focus Running | Phase complete | remaining <= 0 | close work, update totals | Break Ready/Running |
| Break Running | Phase complete | remaining <= 0 | close break | Focus Ready/Running |

## 12.3 Atomic transition rule

A transition is successful only when all relevant records commit in one database transaction. Example Pause transaction:

1. verify runtime state is running and command token has not already been applied;
2. close current work segment;
3. increment session active total;
4. insert pause segment;
5. update runtime current segment/state/anchors;
6. update session `updated_at`;
7. commit;
8. update notification/tray;
9. publish UI state.

If platform notification update fails after commit, the timer remains paused and the UI reports an integration warning. Domain state does not roll back because notification is secondary.

## 12.4 Idempotency

Commands carry a generated operation ID or verify state/version before mutation.

Examples:

- two Stop events: first transitions to completion-pending; second returns existing pending session without creating a duplicate;
- notification Pause after UI Pause: command observes already paused and succeeds as no-op;
- repeated phase-complete event: only one next segment is created.

## 12.5 Time calculation

Within one running process/boot:

- use a monotonic clock for elapsed display and transition duration;
- also persist wall-clock UTC anchors.

After restart:

- monotonic anchor is invalid;
- use persisted UTC times and session totals;
- detect large gaps or system-clock changes;
- request recovery review when confidence is low.

Canonical current active duration:

```text
closed work-segment seconds
+ elapsed seconds since current work segment started
```

Paused and Pomodoro-break segments are excluded.

## 12.6 Checkpoints

Persist on every state transition. Optional periodic checkpoint every 1–5 minutes may update recovery metadata but must not rewrite all session rows each second. A foreground notification chronometer can display elapsed time without database writes every second.

## 12.7 Device shutdown limitation

A normal application cannot always know the exact instant a device loses power. Therefore:

- if the timer was running, reopening can continue counting across the shutdown based on wall-clock time;
- recovery review allows the user to set the end time to the last known checkpoint or a manual time;
- the app must never claim exact active-time knowledge across an unexpected power loss without user review when the gap is unusual.


---

# 13. User flows

## 13.1 First launch and first session

```text
Launch
→ Onboarding: local-first explanation
→ Onboarding: backup responsibility
→ Create first skill
→ Skills home with new card
→ Tap Play
→ Choose Stopwatch
→ Start
→ Immersive timer
→ Stop
→ Completion panel
→ Add optional title/note/tags
→ Save Session
→ Skill card updates
→ Backup reminder explains first export
```

Acceptance:

- No account prompt.
- No network request.
- Skill and start state are durable before timer animation begins.

## 13.2 Resume normal stopwatch session

```text
Skills
→ Play on skill card
→ Stopwatch preselected
→ Start
→ Timer
→ Pause
→ Leave app
→ Reopen app
→ Paused timer restored
→ Resume
→ Stop
→ Save without note
```

## 13.3 Crash recovery

```text
Running session
→ Process killed
→ App relaunched
→ Database discovers running session
→ Recalculate elapsed time
→ Normal gap: open timer automatically
   OR
→ Unusual gap: Recovery Review
→ User continues, edits end, or stops
```

## 13.4 Pomodoro session

```text
Play skill
→ Select Pomodoro
→ Start focus
→ Focus completes
→ Persist work interval
→ Notify break ready
→ Start/auto-start short break
→ Break completes
→ Start next focus
→ User stops after several intervals
→ Completion panel shows total work and break time
→ Save one session
```

## 13.5 Manual entry

```text
Learning Log or skill overflow
→ Add Manual Session
→ Select skill/date/time or duration
→ Add note/tags
→ Overlap check
→ Save
→ Statistics update
```

## 13.6 Review Learning Log

```text
Learning Log
→ Search “attention”
→ Filter AI Learning + last 3 months
→ Group by month
→ Select session
→ Read Markdown note
→ Edit duration
→ Confirm statistics impact
→ Save
```

## 13.7 Heatmap to session history

```text
Statistics
→ Activity tab
→ Select heatmap day
→ View total duration
→ Open in Learning Log
→ Learning Log filtered to exact day
→ Open session detail
```

## 13.8 Full backup export

```text
Settings → Backup & Data
→ Export Full Backup
→ Optional passphrase choice when available
→ Choose destination
→ Generate staging archive
→ Parse and verify generated archive
→ Save/move to destination
→ Verify final file where platform permits
→ Record successful backup
→ Update last-backup indicator
```

Cancellation before final verification must not update last successful backup.

## 13.9 Replace restore on another device

```text
Fresh installation
→ Import
→ Select .skilltracker
→ Validate and preview
→ Choose Replace
→ Confirm
→ Create local safety snapshot if data exists
→ Build/validate imported database
→ Commit
→ Show counts and totals
→ Skills home restored
```

## 13.10 Merge divergent devices

```text
Existing local data
→ Import backup from second device
→ Validate and preview
→ Choose Merge
→ Show new/updated/skipped/conflict counts
→ Resolve equal-timestamp conflicts if any
→ Create safety snapshot
→ Merge transaction
→ Integrity and statistics verification
→ Completion report
```

## 13.11 Restore local safety snapshot

```text
Settings → Local Snapshots
→ Select snapshot
→ View reason/date/schema/counts
→ Confirm current data will be replaced
→ Create snapshot of current state
→ Restore selected snapshot
→ Verify and restart data layer
```

## 13.12 Delete all data

```text
Settings → Delete All Local Data
→ Explain scope and backup recommendation
→ Require typed confirmation
→ Optional Export First
→ Create safety snapshot
→ Delete database contents and secure local settings
→ Return to onboarding/empty Skills screen
```

---

# 14. Navigation model

## 14.1 Route inventory

```text
/
├── /onboarding
├── /skills
│   ├── /skills/create
│   ├── /skills/:skillId/edit
│   └── /skills/:skillId/start
├── /timer/:sessionId
├── /session/:sessionId/complete
├── /learning-log
│   ├── /session/:sessionId
│   ├── /session/:sessionId/edit
│   └── /session/manual
├── /statistics
├── /settings
│   ├── /settings/appearance
│   ├── /settings/timer
│   ├── /settings/statistics
│   ├── /settings/backup
│   ├── /settings/security
│   ├── /settings/snapshots
│   └── /settings/diagnostics
├── /backup/import-preview
└── /backup/conflicts
```

These are conceptual route names even if standard Navigator APIs use typed builders rather than path strings.

## 14.2 Startup route decision

```text
Database unavailable/corrupt
→ Recovery screen

Completion-pending session exists
→ Completion panel

Active/paused session exists
→ Timer or Recovery Review

No skill exists and onboarding incomplete
→ Onboarding

Otherwise
→ Skills
```

## 14.3 Back behavior

- Timer back on Android minimizes/returns after warning but does not stop the session.
- Completion panel back preserves completion-pending draft.
- Replace-import confirmation cannot be dismissed while commit is executing.
- Desktop Escape closes modal layers, not the active application session.
- Navigation must not create multiple Timer routes for the same session.

## 14.4 Navigation-state restoration

Version 1 restores domain state first. Full arbitrary screen-stack restoration is not required. On restart:

- active timer takes priority;
- otherwise return to Skills;
- selected Learning Log filters may be restored as preferences;
- modal dialogs are not restored except session completion and recovery.

---

# 15. Error, loading, and empty states

## 15.1 Error catalogue

| Code family | Example | User behavior |
|---|---|---|
| `VAL-*` | invalid target or end time | Inline correction |
| `DB-*` | write, migration, integrity failure | Retry, diagnostics, restore snapshot |
| `TIMER-*` | clock discontinuity or invariant violation | Recovery Review |
| `FILE-*` | permission denied, destination unavailable | Choose another location |
| `BACKUP-*` | unsupported format, checksum mismatch | Reject without mutation |
| `IMPORT-*` | semantic invalidity or conflict | Preview details/cancel |
| `PLATFORM-*` | tray/notification unavailable | Continue core app with warning |
| `SEC-*` | wrong passphrase, auth failure | Retry without revealing detail |
| `UPDATE-*` | release check unavailable | Non-blocking message |

## 15.2 Database startup failure

Recovery screen options:

- Retry open;
- Run integrity check;
- Restore latest valid local snapshot;
- Import external backup;
- Export diagnostics;
- Reset only after explicit destructive confirmation.

Do not silently initialize a new empty database over an unreadable existing database.

## 15.3 Import errors

Examples:

- **Checksum mismatch:** “This backup failed integrity verification. No data was changed.”
- **Newer format:** “This backup was created by a newer Ayutam version. Update the app before importing.”
- **Broken relationship:** “The backup contains sessions whose skills are missing. No data was changed.”
- **Wrong passphrase:** “The backup could not be decrypted. Check the passphrase.”

Never expose stack traces in normal UI.

## 15.4 Timer anomaly states

- Negative elapsed duration: force Recovery Review.
- Current segment missing: reconstruct from last checkpoint only after user review.
- More than one active session found: block timer start, present conflict-recovery screen, and preserve both records.
- Foreground service unavailable: show local warning while continuing timestamp-based timing.

## 15.5 Loading behavior

- Initial database open uses a branded but minimal splash.
- Skill list uses skeletons only if query exceeds a short threshold; avoid fake loading for local operations.
- Long exports/imports show stage labels and progress where calculable.
- Import commit is cancellable only before transaction/swap begins.
- Charts show cached/current query result while recomputing filters when safe.

## 15.6 Empty states

All empty states include:

- a precise explanation;
- one primary next action;
- no blame language;
- no unnecessary illustration requirement.

## 15.7 Offline update-check state

If update checks are enabled but offline, display only when the user requests a check. Do not show persistent errors for a non-core optional feature.

---

# 16. Accessibility requirements

## 16.1 Standards target

Aim for WCAG 2.2 AA principles where applicable to native Flutter interfaces and follow Android/Windows/Linux accessibility conventions.

## 16.2 Semantics

- Every icon-only control has a semantic label and state.
- Timer announces “Pause session,” “Resume session,” and “Stop session.”
- Flip clock exposes one concise combined duration rather than announcing every digit separately.
- Chart points and heatmap cells expose text alternatives.
- Skill progress bars announce tracked, target, and percentage.
- Autosave and import results use appropriate live-region behavior without excessive repetition.

## 16.3 Keyboard

- All actionable elements are keyboard reachable.
- Focus order follows reading order.
- Visible focus indicators meet contrast requirements.
- Shortcuts have menu/help discovery.
- Text-input focus suppresses conflicting global shortcuts.
- Escape behavior is predictable and non-destructive.

## 16.4 Text scaling

- Support at least 200% text scale without clipping critical content.
- Flip digits may scale within constraints but combined semantic duration remains available.
- Tables adapt to cards or horizontal scroll rather than shrinking text below readability.

## 16.5 Motion

Reduce Motion setting:

- disables 3D digit flips;
- reduces large route transitions;
- avoids animated chart drawing;
- does not disable functional state feedback.

The setting defaults from platform accessibility preferences where Flutter exposes them.

## 16.6 Colour and contrast

- Text and icons meet AA contrast against their surfaces.
- Skill colours are accents, not the sole skill identifier.
- Heatmap cells have tooltips/labels and optional patterns/borders for focused or selected state.
- Comparison lines use dash/marker differences.

## 16.7 Touch and pointer

- Minimum touch target: 48x48 logical pixels.
- Pointer targets can be visually smaller only when hit region remains sufficient.
- Destructive actions are not adjacent to primary actions without spacing or confirmation.

## 16.8 Accessibility testing

- Flutter semantics tests for critical components.
- Android TalkBack manual pass.
- Windows Narrator and keyboard-only pass.
- Linux Orca pass on supported desktop environment where feasible.
- Contrast and text-scale test matrix.
- Reduced-motion test.

---

# 17. Security and privacy requirements

## 17.1 Privacy model

- All skills, notes, sessions, settings, and diagnostics remain local unless the user exports a file.
- No telemetry, analytics, advertising SDK, remote logging, or crash-reporting SDK.
- No account identifier.
- Random device ID exists only for merge lineage.
- Privacy documentation must explain the exact optional network behavior of update checks.

## 17.2 Permissions

Request the minimum platform permissions:

### Android

- notifications when foreground timer controls are enabled and required by platform;
- foreground-service permission/type required for the ongoing timer notification;
- storage access through modern system file pickers rather than broad filesystem permissions;
- no contacts, location, camera, microphone, or advertising permissions;
- internet permission only if optional release checking is included in that build.

### Desktop

- user-selected file access through file dialogs;
- tray/notification integration;
- no elevated privileges.

## 17.3 Backup security

Unencrypted backups may contain private notes. The export UI must state this clearly.

Encrypted backup design:

- AES-256-GCM authenticated encryption;
- Argon2id passphrase key derivation;
- random salt and nonce from a cryptographically secure RNG;
- no passphrase stored;
- optional temporary key only in memory;
- wrong passphrase and corrupted ciphertext produce the same general failure category where practical;
- do not invent recovery questions or backdoors.

## 17.4 PIN lock

Version-1 cross-platform baseline:

- optional local PIN;
- store only a salted password hash or secure platform secret, never plaintext;
- rate-limit retries in app;
- PIN protects casual access, not a rooted/fully compromised device;
- forgetting the PIN requires resetting the lock through a documented local recovery mechanism that may require data re-import; do not weaken encryption to recover a forgotten PIN.

Biometric and Windows Hello integrations are future platform enhancements behind `AppLockService`.

## 17.5 Markdown safety

- Render Markdown without arbitrary HTML execution.
- External links require confirmation or use the platform browser.
- Do not auto-load remote images.
- Code blocks are display-only.
- Export preserves text but does not execute it.

## 17.6 Archive safety

Import must defend against:

- zip-slip/path traversal;
- decompression bombs;
- excessive record counts or note sizes;
- duplicate archive paths;
- malformed UTF-8;
- recursive archives;
- unexpected executable content.

Set reasonable configurable limits well above legitimate 100,000-session usage.

## 17.7 CSV injection

User-controlled fields beginning with spreadsheet formula markers should be escaped or prefixed in CSV exports. Document the behavior so a user can recover the original text if necessary.

## 17.8 Supply-chain security

- Commit lockfile.
- Pin compatible dependency ranges.
- Review package publisher, maintenance, licence, platform support, and transitive dependencies.
- Run dependency vulnerability and licence checks in CI where tooling permits.
- Do not add a package for a trivial function available in Dart/Flutter.
- Record major package choices in ADRs.

## 17.9 Data deletion

Delete All Local Data removes:

- database;
- app-private snapshots;
- diagnostic logs;
- cached exports inside app-private directories;
- local PIN material;
- user preferences.

It cannot delete copies already saved by the user outside the app.

---

# 18. Testing strategy

## 18.1 Test pyramid

### Unit tests

Cover:

- duration and formatting;
- target/progress calculations;
- streak algorithm;
- daily cross-midnight allocation;
- rolling four-week average;
- projection logic;
- state-machine transitions;
- conflict resolution;
- validation and value objects;
- backup schema codecs;
- timezone grouping.

### Database tests

Use temporary native/in-memory databases where supported:

- CRUD and constraints;
- one-active-session invariant;
- segment totals;
- FTS index maintenance;
- query pagination;
- transaction rollback;
- integrity checks;
- 100,000-session performance fixture.

### Migration tests

For every schema version:

- open old schema fixture;
- insert representative edge-case data;
- migrate to current;
- compare expected schema;
- verify data and totals;
- export and re-import after migration.

### Widget tests

- skill card states;
- flip-clock digit changes and reduced motion;
- timer controls and semantics;
- completion autosave indicators;
- Learning Log filters;
- import preview;
- empty and error states;
- responsive breakpoints.

### Integration tests

- full timer lifecycle;
- process/restart simulation where tooling supports;
- portable backup round trip;
- replace and merge;
- conflict tie review;
- active-session import;
- cross-platform fixtures;
- notification/tray commands with platform-specific test harnesses.

### Accessibility tests

- semantic labels;
- focus traversal;
- large text;
- reduced motion;
- colour-independent state.

## 18.2 Clock testing

Use an injectable fake clock with both wall-clock and monotonic time.

Scenarios:

- normal elapsed time;
- pause/resume;
- app closed for 30 minutes;
- device restart invalidates monotonic anchor;
- wall clock moves backward;
- wall clock moves forward several hours;
- DST transition in a configured timezone;
- timezone setting changes;
- session crosses midnight;
- repeated notification/UI commands;
- Pomodoro phase boundary while app is backgrounded.

## 18.3 Backup test matrix

| Case | Expected |
|---|---|
| Empty database export/import | Valid empty restore |
| 100,000 sessions | Completes within resource budget |
| Unicode notes and emoji | Exact round trip |
| Multiline Markdown/code blocks | Exact round trip |
| Corrupted payload byte | Checksum rejection |
| Missing skill reference | Semantic rejection |
| Newer format version | Safe rejection |
| Old format version | Migration success |
| Wrong encryption passphrase | No mutation |
| Cancel preview | No mutation |
| Failure during merge | Full rollback |
| Raw SQLite with WAL active | Consistent snapshot |
| Same backup imported twice | No duplicates |
| Divergent same UUID | Newest wins |
| Overlap with different UUID | Both retained |

## 18.4 Performance tests

Fixture target:

- 100 skills;
- 100,000 sessions;
- average note 2 KB;
- 300,000 segments;
- 1,000 tags and realistic associations;
- 20 years of dates.

Measure:

- startup database open;
- Skills list;
- current-month Learning Log query;
- FTS search;
- 12-month heatmap aggregation;
- all-time line aggregation;
- export memory and duration;
- import validation and commit;
- migration duration.

Define baseline hardware in the repository before enforcing thresholds.

## 18.5 Platform tests

### Android

- Android 10 baseline and a current Android version;
- notification permission denied/granted;
- screen locked;
- app swiped away;
- process killed;
- device restart;
- battery saver;
- orientation locked;
- file picker providers such as Downloads and Drive exposed by Android system UI.

### Windows

- Windows 10 and 11;
- tray availability;
- installer/portable upgrade preserving data;
- file paths with Unicode;
- sleep and wake;
- keyboard shortcuts;
- multiple monitors and scaling.

### Linux

- Ubuntu 22.04 primary CI/manual target;
- Ubuntu 20.04/24.04 and supported Debian smoke tests;
- GNOME and at least one additional common desktop environment;
- tray unavailable scenario;
- Wayland and X11 where feasible;
- packaging install/upgrade/uninstall behavior.

## 18.6 Visual tests

Use limited golden tests only for stable core visuals:

- flip-clock digit/card;
- skill card light/dark;
- heatmap legend/cell states;
- summary metric card.

Do not overuse goldens during active design iteration.

## 18.7 CI gates

Every pull request:

- format check;
- static analysis with no warnings;
- unit/database/widget tests;
- migration tests;
- dependency licence report;
- generated-code consistency;
- build smoke tests on supported runners where practical.

Release candidate:

- all integration tests;
- cross-platform fixture round trip;
- signed/packaged artifacts;
- manual accessibility checklist;
- migration from previous release;
- backup/restore disaster drill.

---

# 19. End-to-end acceptance criteria

## 19.1 Principal cross-platform scenario

1. Install Ayutam on Android.
2. Complete onboarding.
3. Create three skills with different targets and colours.
4. Record multiple stopwatch sessions, including pause/resume and a cross-midnight session.
5. Record a Pomodoro session with at least two focus intervals.
6. Add Markdown notes, titles, and tags.
7. Add one manual historical session.
8. Verify Skills totals, Learning Log, chart, heatmap, summary table, and two-minute global streak.
9. Export a portable backup.
10. Verify last-backup status updates only after file verification.
11. Install Ayutam on Windows.
12. Import using Replace.
13. Verify exact skills, targets, colours, notes, tags, timestamps, totals, segments, settings, charts, and streak.
14. Create and edit a session on Windows.
15. Export a new backup.
16. On Android, create a divergent session with a different UUID.
17. Import Windows backup using Merge.
18. Verify both divergent sessions remain, matching UUID updates follow newest timestamp, and no duplicates appear.
19. Export final backup and restore on Linux.
20. Verify all results again.

## 19.2 Timer recovery acceptance

- Start session, force-close app, wait, reopen: correct duration within 10 seconds.
- Pause, force-close, reopen: paused duration does not increase.
- Restart device: active session is discovered and reviewed/restored.
- Change system clock backward: no negative duration; Recovery Review appears.
- Stop twice through UI and notification: one completion-pending session only.

## 19.3 Import guarantees

Import is successful only when:

- file and payload checksums pass;
- record counts match expected normalized counts;
- referential integrity passes;
- total active duration matches the payload summary;
- session segment totals reconcile;
- database integrity check passes;
- statistics queries recalculate without error;
- post-import active-session invariant holds;
- completion report is persisted.

## 19.4 Data-loss acceptance

Induced failure during:

- export generation;
- import validation;
- merge halfway through;
- database swap;
- migration;

must result in either the original valid data or the fully committed new data. A partially committed state is a release-blocking defect.

## 19.5 Usability acceptance

- First skill creation is understandable without documentation.
- Starting the last-used timer requires no more than two intentional actions.
- Stop and save without a note is obvious.
- Backup status cannot be mistaken for automatic cloud sync.
- Learning Log remains navigable with a 10-year fixture.
- Icon-only timer controls are understandable through placement, tooltips, and accessibility labels.


---

# 20. Phased implementation plan

## 20.1 Phase 0 — Repository and architectural foundation

Deliverables:

- Flutter project for Android, Windows, and Linux;
- MIT licence, README, CONTRIBUTING, SECURITY, AGENTS;
- strict analysis and formatting;
- Riverpod bootstrap;
- Drift database opening in background isolate;
- clock, UUID, logger, and platform-service interfaces;
- initial ADRs;
- CI for analyze/test/build smoke checks;
- Material 3 theme and responsive shell.

Exit criteria:

- empty app builds on all three platforms;
- temporary database tests run;
- no backend or network dependency;
- dependency policy documented.

## 20.2 Phase 1 — Vertical slice: skill to completed stopwatch session

Deliver:

- skill create/edit/list/archive;
- Skills home panels;
- custom flip-clock prototype;
- pre-session sheet;
- stopwatch state machine;
- pause/resume/stop;
- completion-pending record;
- save without note;
- basic recent sessions;
- process termination recovery.

This phase must prove the hardest invariant early: timer state is durable independently of widget lifetime.

Exit criteria:

- one complete session updates skill total;
- force-close/reopen recovery works;
- duplicate commands do not duplicate sessions;
- Android and desktop builds share domain logic.

## 20.3 Phase 2 — Notes, tags, and Learning Log

Deliver:

- Markdown title/note editor and preview;
- note autosave;
- tags;
- manual sessions;
- edit/delete/undo;
- FTS5 search;
- grouped Learning Log;
- filters, sorting, calendar navigation;
- desktop two-pane layout.

Exit criteria:

- 10-year fixture remains usable;
- exact Markdown round trip;
- note closing/crash does not lose draft.

## 20.4 Phase 3 — Statistics

Deliver:

- calculation services;
- summary card;
- cumulative chart;
- heatmap;
- summary table;
- global 2-minute streak;
- rolling four-week average;
- target projection;
- selected/all/comparison scopes;
- chart image export.

Exit criteria:

- cross-midnight and timezone tests pass;
- 100,000-session aggregation meets baseline;
- chart interactions work with touch, pointer, and keyboard.

## 20.5 Phase 4 — Backup, restore, and migration

Deliver:

- portable format v1;
- JSON export;
- verified export pipeline;
- replace import;
- merge import and conflict review;
- raw SQLite snapshot;
- CSV and Markdown reports;
- backup history and weekly reminder;
- last three local snapshots;
- database integrity screen;
- migration test infrastructure.

Exit criteria:

- Android → Windows → Linux round trip passes;
- induced import failure leaves original data intact;
- same backup imported twice creates no duplicates;
- old-format fixture migration is proven before first post-v1 schema change.

## 20.6 Phase 5 — Platform integrations

Deliver:

- Android ongoing notification and actions;
- Android orientation and screen-awake behavior;
- Windows/Linux tray;
- desktop shortcuts;
- drag-and-drop import;
- application lifecycle integration;
- permission/error fallbacks.

Exit criteria:

- core timer works when integrations are unavailable;
- foreground-service implementation receives policy review before store work;
- Linux tray failure does not prevent startup.

## 20.7 Phase 6 — Pomodoro

Deliver:

- Pomodoro configuration;
- focus/break segments;
- countdown interface;
- alerts;
- recovery across background/restart;
- work-only statistics;
- settings and tests.

Pomodoro is deliberately implemented after the stopwatch state machine because it extends that model rather than creating a parallel timer architecture.

## 20.8 Phase 7 — Security, accessibility, and release hardening

Deliver:

- optional PIN lock;
- optional encrypted backup after security review;
- accessibility passes;
- performance fixture and profiling;
- packaging and upgrade tests;
- diagnostics export;
- release documentation;
- GitHub Releases automation;
- optional update check.

## 20.9 Later store readiness

Without changing domain architecture:

- Android signing and AAB;
- Play data-safety declaration;
- foreground-service declaration and evidence;
- store screenshots/listing;
- Windows MSIX and Microsoft Store identity;
- privacy policy page;
- automated update strategy review;
- release-channel/version migration testing.

---

# 21. Version-1 and future-feature boundaries

## 21.1 Included in version 1

- unlimited independent skills;
- configurable targets;
- skill colours and lifecycle;
- Skills home and recent history;
- custom flip-clock stopwatch;
- one active timer;
- pause/resume/recovery;
- Pomodoro mode;
- optional Markdown notes, title, tags;
- manual entry and session editing;
- Learning Log search/filter/grouping;
- cumulative chart, heatmap, summary table;
- selected/all/comparison statistics;
- global two-minute streak;
- projection;
- SQLite internal database;
- portable JSON archive, JSON, SQLite, CSV, and Markdown export paths;
- merge and replace import;
- checksums, preview, transactions, snapshots, migrations;
- weekly backup reminder;
- Android notification;
- desktop tray and shortcuts;
- light/dark/system theme;
- accessibility baseline;
- local diagnostics;
- optional local PIN;
- encrypted backup before final v1 completion if security review and device performance pass.

## 21.2 Explicitly excluded from version 1

- accounts and authentication service;
- backend/API;
- cloud synchronization;
- direct Google Drive/OneDrive/Dropbox/GitHub storage integration;
- multi-user profiles;
- teams or shared goals;
- leaderboards or social feeds;
- AI summaries or recommendations;
- image/audio/video attachments;
- nested subskills/projects;
- multiple simultaneous timers;
- automatic idle detection;
- calendar integration;
- complex recurring goals;
- streak freezes/rest schedules;
- public profile;
- browser/PWA;
- wearable app;
- iOS/macOS;
- automatic CSV import;
- automatic fuzzy duplicate detection;
- full permanent audit event log.

## 21.3 Candidate future features

A feature enters planning only through a new specification and ADR:

- Android biometrics and Windows Hello;
- automatic file-system backup to a user-selected folder where platform rules permit;
- optional Git-based backup helper without hosted service dependency;
- calendar export;
- session templates;
- subskills;
- attachments;
- widgets/quick settings;
- store distribution;
- iOS/macOS;
- cloud sync only if the foundational “no backend ever” product rule is intentionally reversed by the owner. Under the current product decision, cloud sync remains permanently out of scope.

## 21.4 Scope-control rule

During implementation, agents must not add a “small useful feature” unless it is listed in version 1 or required to make a listed feature safe and testable. Suggestions belong in an issue or Future Features section, not in the current code change.

---

# 22. Instructions for Codex, Claude Code, or another coding agent

## 22.1 Operating mandate

Build the smallest correct implementation of the documented behavior. Preserve local-first data ownership and crash safety above visual novelty. Do not reinterpret the product into a cloud application, SaaS, habit social network, or generic productivity suite.

## 22.2 Required workflow for every substantial task

1. Read `AGENTS.md`, this specification, relevant ADRs, and existing tests.
2. Inspect the current repository before proposing new architecture.
3. Restate the task as concrete acceptance criteria in the work log or pull request.
4. Identify affected domain invariants and migration implications.
5. Prefer extending existing interfaces over introducing parallel abstractions.
6. Implement the smallest vertical change.
7. Add or update tests at the appropriate layers.
8. Run formatting, analysis, unit, database, migration, and relevant integration tests.
9. Update documentation and ADRs when a decision changes.
10. Report assumptions, residual risks, and exact verification performed.

## 22.3 Prohibited agent behavior

- Do not add Firebase, Supabase, a REST API, authentication, analytics, advertisements, or remote crash reporting.
- Do not store canonical timer state only in Riverpod, widget state, a periodic loop, or notification state.
- Do not copy the live SQLite file as a backup without a consistent backup operation.
- Do not modify database schema without a migration and migration test.
- Do not add a dependency without licence/maintenance/platform review.
- Do not replace stable UUID merge identity with timestamp or content heuristics.
- Do not silently discard or auto-correct corrupt imports.
- Do not claim a backup succeeded before verifying the generated file.
- Do not add PWA/web support in version 1.
- Do not create separate Android/Windows/Linux business-logic implementations.
- Do not change the two-minute global streak definition without an ADR.
- Do not implement Pomodoro as a second unrelated timer engine.

## 22.4 Decision freedom

The implementation agent may choose a better maintained library or implementation technique when all of the following are true:

- it satisfies the same functional and platform requirements;
- it uses a permissive licence compatible with MIT distribution;
- it does not add a backend or proprietary dependency;
- it reduces maintenance or correctness risk;
- tests prove compatibility;
- the choice is documented in an ADR and dependency inventory.

## 22.5 Definition of done for a feature

A feature is done when:

- acceptance criteria pass;
- failure and empty states exist;
- accessibility semantics exist;
- persistence/recovery behavior is defined;
- unit and integration coverage is appropriate;
- no new analysis warnings;
- documentation is updated;
- supported platforms build or platform exceptions are documented;
- no unrelated feature creep is included.

## 22.6 Pull request template guidance

Each PR should include:

```text
Summary
- What changed and why.

Requirements
- Specification/issue references.

Data impact
- Schema, migration, backup-format, or merge implications.

Platform impact
- Android / Windows / Linux behavior.

Verification
- Commands and manual scenarios executed.

Risks and follow-ups
- Known limitations; no hidden TODOs.
```

## 22.7 High-risk change checklist

For timer, database, migration, backup, import, encryption, or platform-service changes:

- failure injection test;
- transaction boundary review;
- idempotency review;
- process/restart review;
- old-data compatibility;
- backup before destructive operation;
- no secrets or notes in logs;
- cross-platform fixture test.

---

# 23. Suggested `AGENTS.md`

The following can be placed at the repository root as `AGENTS.md`.

```markdown
# AGENTS.md — Ayutam

## Mission

Ayutam is a local-first Flutter skill-practice tracker for Android, Windows, and Linux. It has no backend, accounts, analytics, advertisements, or automatic cloud synchronization. SQLite is the live store. Users own and move their data through explicit backups.

Read `docs/` and the consolidated product specification before making architectural or product decisions.

## Non-negotiable invariants

1. At most one session may be active, paused, or completion-pending.
2. Timer truth is persisted timestamps and segments, not UI ticks.
3. State transitions are transactional and idempotent.
4. Completed progress is integer active seconds.
5. Pauses and Pomodoro breaks never count as active skill time.
6. Cross-midnight active segments are split by configured timezone for daily statistics.
7. The global streak requires at least 120 completed active seconds per local calendar day.
8. Backups are marked successful only after verification.
9. Imports validate before mutation and create a safety snapshot.
10. Schema changes require migrations and migration tests.
11. No backend, auth, telemetry, ads, or automatic cloud sync.
12. Android, Windows, and Linux share domain and application logic.

## Architecture

Use a feature-based modular structure:

- presentation: Flutter widgets and Riverpod controllers;
- application: commands, queries, and orchestration;
- domain: entities, policies, state machines, repository contracts;
- data: Drift/SQLite, file formats, repository implementations;
- platform: foreground notification, tray, shortcuts, orientation, wakelock, file dialogs.

Widgets must not execute SQL. Platform plugins must not define canonical domain state.

## Technology baseline

- Flutter stable, pinned by repository tooling;
- Material 3;
- Riverpod;
- Drift with native SQLite;
- standard Navigator route builders unless an ADR approves go_router;
- custom flip-clock and heatmap where practical;
- permissively licensed, maintained packages only.

Do not add a package for trivial functionality available in Dart or Flutter.

## Data model rules

- UUID IDs;
- UTC timestamps plus relevant timezone metadata;
- integer seconds for durations;
- `created_at`, `updated_at`, and random `source_device_id` on mergeable records;
- foreign keys enabled;
- derived statistics are not authoritative stored counters;
- do not directly copy a live WAL database for export.

## Timer work

Before changing timer code, inspect the state machine and recovery tests.

Every transition must:

1. validate current persisted state;
2. change session, segment, and runtime records in one transaction;
3. commit before updating notification/tray/UI;
4. tolerate duplicate commands;
5. preserve recovery after process termination.

Use an injectable wall clock and monotonic clock in tests.

## Backup/import work

Canonical backup: versioned `.skilltracker` archive containing JSON and checksums.

Import stages:

1. file safety;
2. manifest/version;
3. checksum/decryption;
4. semantic validation;
5. preview;
6. safety snapshot;
7. transactional replace/merge;
8. integrity and totals verification.

Same UUID is the same logical record. Different UUIDs are distinct even when times overlap. Newest `updated_at` wins; equal timestamp with different content requires conflict handling.

Never update `lastSuccessfulBackupAt` before verifying the output.

## Product boundaries

Do not add:

- Firebase/Supabase/backend/API;
- login or user accounts;
- social or leaderboard features;
- AI summaries;
- media attachments;
- multiple active timers;
- web/PWA support;
- iOS/macOS in version 1;
- automatic cloud sync;
- unrelated gamification.

Place suggestions in an issue. Do not implement them opportunistically.

## UI rules

- Skills is the home page.
- Timer is an immersive nested route.
- Large accumulated flip clock in Stopwatch mode.
- Pomodoro uses a large phase countdown and smaller accumulated totals.
- Icon-only timer controls require semantics, tooltips, focus, and 48x48 hit targets.
- Support light, dark, system theme, reduced motion, 200% text scale, keyboard navigation, and colour-independent states.

## Testing requirements

Run before completion:

```bash
flutter format --set-exit-if-changed .
flutter analyze
flutter test
```

Also run relevant database, migration, integration, and platform tests.

High-risk changes require:

- failure injection;
- transaction rollback test;
- idempotency test;
- restart/recovery test;
- backup compatibility test;
- cross-platform fixture validation.

## Documentation requirements

Update documentation when changing:

- user-visible behavior;
- database schema;
- backup format;
- state machine;
- package choice;
- platform permissions;
- security model.

Create or update an ADR for material decisions.

## Dependency review

For every new dependency document:

- purpose;
- current version selected;
- publisher/repository;
- licence;
- Android/Windows/Linux support;
- maintenance signals;
- fallback/replacement plan.

## Completion response

Report:

- files changed;
- behavior implemented;
- tests executed and results;
- migrations/data implications;
- supported-platform implications;
- remaining limitations.
```

---

# 24. Recommended Flutter packages and dependency rationale

Package versions below reflect the research date and must be rechecked before implementation. Pin a tested compatible set rather than automatically taking every newest release.

## 24.1 Core candidates

| Capability | Candidate | Rationale | Policy |
|---|---|---|---|
| State/DI | `flutter_riverpod` | Testable asynchronous state and dependency injection; MIT | Recommended |
| Database | `drift`, `drift_dev`, `sqlite3` | Typed SQLite, reactive queries, transactions, migrations, Android/desktop native support; permissive | Required unless ADR replaces |
| Code generation | `build_runner` | Drift/Riverpod generation where used | Dev dependency |
| File locations | `path_provider` | Platform application directories | Recommended |
| File selection | `file_picker` | Android, Windows, Linux file dialogs | Recommended after platform tests |
| Paths | `path` | Safe path operations | Recommended |
| IDs | `uuid` or equivalent | Random device/record UUIDs | Recommended |
| Date formatting | `intl` | Locale-aware display | Recommended |
| Timezone | `timezone` plus device-zone adapter | IANA timezone calculations | Recommended |
| Charts | `fl_chart` | MIT, cross-platform, customizable line charts | Initial choice behind adapter |
| Markdown | `flutter_markdown_plus` | Maintained cross-platform Markdown renderer; BSD | Recommended after security review |
| ZIP | `archive` | MIT, ZIP/gzip support, streaming APIs | Recommended |
| Hashing | `crypto` | SHA-256 checksums | Recommended |
| Encryption | `cryptography` | AES-GCM and Argon2id support | Phase 7, security review |
| Screen awake | `wakelock_plus` | Android/Windows/Linux support | Recommended |
| App metadata | `package_info_plus` | Version shown in backups/diagnostics | Recommended |

## 24.2 Platform candidates

| Capability | Candidate | Notes |
|---|---|---|
| Android ongoing timer | `flutter_foreground_task` or native Kotlin service | Prototype package, but retain replaceable interface and verify Android/Play policy |
| Desktop window lifecycle | `window_manager` | Useful for close/minimize behavior |
| Desktop tray | `tray_manager` or `system_tray` | Test Linux dependencies and Wayland behavior |
| Desktop hotkeys | Flutter `Shortcuts`/`Actions` first; `hotkey_manager` only for global shortcuts | Prefer framework-scoped shortcuts before plugin |
| Drag/drop | maintained desktop drop package or platform file APIs | Add only after platform matrix review |
| Secure storage | maintained cross-platform secure-storage package | Required only for PIN/secret material; verify Linux backend |
| Local notifications | platform notification package if foreground plugin does not provide controls | Avoid duplicate notification stacks |
| Share/save | system file picker/save APIs; `share_plus` only where needed | Desktop save path must be tested |

## 24.3 Custom components instead of packages

Implement in-project:

- flip-clock widget;
- GitHub-style heatmap;
- duration formatting;
- progress calculations;
- state machine;
- merge/conflict policy;
- backup manifest/schema mapping;
- responsive shell components.

These are central product behavior or small enough that package dependency would reduce control.

## 24.4 Package selection checklist

Before adding or upgrading:

- package supports Android, Windows, and Linux where required;
- licence is MIT, BSD, Apache-2.0, or otherwise compatible and approved;
- recent maintenance and issue response are acceptable;
- no mandatory hosted service;
- transitive dependencies are reasonable;
- no conflict with current Flutter/Dart SDK;
- release build tested on all target platforms;
- migration/backup behavior unaffected;
- replacement interface exists for high-risk platform plugins.

## 24.5 Navigation package conclusion

Use standard Navigator and typed route builders initially. `go_router` is valuable for deep linking and complex nested route state, but those benefits do not currently outweigh another dependency. Revisit through an ADR if navigation complexity materially increases.

---

# 25. Open questions and architectural decision records

## 25.1 Non-blocking open questions

These do not prevent implementation because this specification defines defaults, but they should be validated during prototypes:

1. **Product name:** “Ayutam” is treated as the working/final name. Confirm branding, package ID, and repository name before public release.
2. **Flip-clock font:** Select and document a redistributable font or system fallback after visual prototyping.
3. **Linux package formats:** Start with `.deb` plus archive; decide whether AppImage or Flatpak is worth ongoing maintenance.
4. **Linux tray support:** Validate GNOME/Wayland and define acceptable graceful degradation.
5. **Android foreground-service classification:** Confirm the valid service type and Play Console evidence immediately before store submission because Android policy evolves.
6. **PIN recovery:** Finalize user-facing reset behavior after secure-storage proof-of-concept.
7. **Encryption parameters:** Benchmark Argon2id on baseline Android hardware before freezing parameters.
8. **Pomodoro alerts:** Select bundled sound/vibration defaults and verify licence/accessibility.
9. **Comparison chart limit:** Default maximum five skills; adjust only after usability testing.
10. **Skill home ordering:** Start with manual sort order plus creation fallback; validate whether drag reorder is necessary.

## 25.2 ADR-001 — Flutter native application

**Status:** Accepted  
**Decision:** Flutter for Android, Windows, and Linux; no PWA.  
**Reason:** One codebase, native local storage, stronger OS integration, predictable application data lifecycle, and no backend requirement.  
**Consequences:** Platform build/signing and desktop packaging are required; public-computer browser access is not supported.

## 25.3 ADR-002 — No backend or automatic synchronization

**Status:** Accepted and permanent unless product direction is explicitly changed.  
**Decision:** All core data remains local; transfer is manual export/import.  
**Consequences:** User owns backup responsibility; merge must be deterministic; no account recovery.

## 25.4 ADR-003 — Drift with native SQLite

**Status:** Accepted.  
**Decision:** Drift/native SQLite is the working database on all initial platforms.  
**Reason:** Relational structure, typed queries, migrations, transactions, reactive reads, and current cross-platform native support.  
**Consequences:** Generated schema and migration discipline are mandatory.

## 25.5 ADR-004 — Portable JSON is the canonical interchange model

**Status:** Accepted.  
**Decision:** `.skilltracker` archive containing versioned JSON and checksums is the canonical cross-platform backup.  
**Reason:** Decouples backups from live schema and allows future implementation migration.  
**Consequences:** Export/import mappers and format migrations are first-class code.

## 25.6 ADR-005 — Raw SQLite is advanced snapshot, not primary interchange

**Status:** Accepted.  
**Decision:** Provide a consistent SQLite snapshot for exact backup, but prefer portable archive for merging and long-term compatibility.  
**Consequences:** Never copy a live WAL database directly.

## 25.7 ADR-006 — Feature-based modular architecture

**Status:** Accepted.  
**Decision:** Feature modules with domain/application/data/presentation boundaries; no excessively ceremonial Clean Architecture.  
**Consequences:** Clear test seams without one-file-per-trivial-use-case overhead.

## 25.8 ADR-007 — Riverpod

**Status:** Accepted.  
**Decision:** Riverpod for state and DI.  
**Consequences:** Database remains source of truth; provider state cannot replace persistence.

## 25.9 ADR-008 — Standard Navigator initially

**Status:** Accepted.  
**Decision:** Typed imperative Navigator routes; no legacy named routes and no routing package initially.  
**Consequences:** Revisit if deep links or nested route state emerge.

## 25.10 ADR-009 — Timestamp/segment timer model

**Status:** Accepted.  
**Decision:** Persist session segments and reconstruct elapsed time; animation loops are display-only.  
**Consequences:** Reliable recovery; requires clock-anomaly review logic.

## 25.11 ADR-010 — One active timer

**Status:** Accepted.  
**Decision:** One active/paused/completion-pending session across all skills.  
**Consequences:** Starting another skill requires resolving the current session.

## 25.12 ADR-011 — Global streak with two-minute threshold

**Status:** Accepted.  
**Decision:** Combined completed active time across all skills must reach 120 seconds in the configured timezone.  
**Consequences:** Very short sessions are retained but may not qualify a day.

## 25.13 ADR-012 — Last-write-wins merge

**Status:** Accepted.  
**Decision:** UUID identity; newest `updated_at` wins; equal timestamp/different content requires conflict handling.  
**Consequences:** Simple offline merge, but permanent deletion resurrection remains possible without tombstones.

## 25.14 ADR-013 — Custom flip clock and heatmap

**Status:** Accepted.  
**Decision:** Build the distinctive flip clock and heatmap in the app.  
**Reason:** They are central to product identity and require custom responsiveness/accessibility.  
**Consequences:** More UI test responsibility, fewer inflexible dependencies.

## 25.15 ADR-014 — Platform integrations are secondary

**Status:** Accepted.  
**Decision:** Notification, tray, and shortcuts invoke the same application commands but never become canonical state.  
**Consequences:** Core timer survives plugin failures and can replace platform packages later.

---

# Appendix A. Calculation definitions

## A.1 Total active time

```text
totalActiveSeconds(skill) =
  sum(session.activeSeconds)
  where session.skillId = skill.id
  and session.status = completed
  and session.deletedAt is null
```

## A.2 Progress

```text
progress = totalActiveSeconds / targetSeconds
progressPercent = progress × 100
remainingSeconds = max(targetSeconds - totalActiveSeconds, 0)
```

Do not clamp displayed progress to 100%; visual progress bar may show a completed state while text displays values above 100%.

## A.3 Rolling four-week average

```text
rollingFourWeekAverage =
  active seconds allocated to the previous 28 local calendar days / 4
```

Label explicitly as “4-week average.”

## A.4 Projection

```text
remainingWeeks = remainingSeconds / rollingFourWeekAverageSeconds
projectedDate = today + remainingWeeks × 7 days
```

Show unavailable when:

- target already reached;
- average is zero;
- fewer than a configurable minimum data window exists, recommended 7 days;
- projected date exceeds date-library limits.

Use language such as “At your recent 4-week average…” rather than presenting certainty.

## A.5 Global streak

1. Convert/split completed active segments into local dates using configured timezone.
2. Sum all skills per local date.
3. Qualifying date has at least 120 seconds.
4. Count backward from today if today qualifies; if today does not qualify but is not over yet, optionally show the streak through yesterday while clearly defining behavior. Recommended: current streak may continue through yesterday until the local day ends, then resets if today remains below threshold.

Freeze the exact “today grace” rule in tests and UI copy.

## A.6 Percentage change

```text
changePercent =
  (currentPeriodSeconds - previousPeriodSeconds)
  / previousPeriodSeconds × 100
```

When previous period is zero:

- current zero → 0% or em dash;
- current positive → “New” rather than infinity.

---

# Appendix B. Screen inventory

| Screen/component | Route/type | Primary responsibility |
|---|---|---|
| Splash/bootstrap | startup | Database, migration, recovery decision |
| Onboarding | page flow | Explain tracking and backup model |
| Skills | primary | Create/select/manage skills |
| Skill form | page/sheet | Create/edit skill |
| Pre-session | sheet/dialog | Select mode and start |
| Timer | immersive page | Active stopwatch/Pomodoro |
| Recovery Review | page/dialog | Resolve uncertain active session |
| Completion | page/sheet | Finalize note/title/tags/time |
| Learning Log | primary | Search and review history |
| Session detail | page/pane | Render complete session/note |
| Session edit | page/dialog | Correct metadata/time |
| Manual session | page/dialog | Add historical work |
| Statistics | primary | Summary, chart, heatmap, table |
| Settings | primary | App preferences and data tools |
| Import preview | page/dialog | Validate and choose strategy |
| Conflict review | page | Resolve merge ties/active conflict |
| Snapshots | settings page | Review/restore local snapshots |
| Diagnostics | settings page | Integrity, logs, environment |
| App lock | overlay | Optional local PIN gate |

---

# Appendix C. Release and data-compatibility checklist

Before every release:

- [ ] Increment semantic version.
- [ ] Confirm database schema version and migration.
- [ ] Confirm portable format version.
- [ ] Generate migration schema snapshots.
- [ ] Run old backup fixtures.
- [ ] Run principal cross-platform fixture.
- [ ] Export and re-import encrypted and unencrypted backups when encryption is enabled.
- [ ] Verify Android permissions and foreground-service declarations.
- [ ] Verify Windows/Linux upgrade preserves application-data directory.
- [ ] Generate dependency and licence report.
- [ ] Update changelog and user-facing migration notes.
- [ ] Create a real backup using the release candidate and restore it using a clean installation.

---

# Appendix D. Technical references used for architectural validation

The implementation agent should recheck current documentation before pinning SDK and package versions.

- Flutter supported platforms: https://docs.flutter.dev/reference/supported-platforms
- Flutter architecture recommendations: https://docs.flutter.dev/app-architecture/recommendations
- Flutter navigation and routing: https://docs.flutter.dev/ui/navigation
- Flutter deployment: https://docs.flutter.dev/deployment
- Drift platform support: https://drift.simonbinder.eu/platforms/
- Drift native cross-platform database: https://drift.simonbinder.eu/platforms/vm/
- Drift transactions: https://drift.simonbinder.eu/dart_api/transactions/
- Drift migrations and migration testing: https://drift.simonbinder.eu/migrations/ and https://drift.simonbinder.eu/migrations/tests/
- SQLite `VACUUM INTO`: https://www.sqlite.org/lang_vacuum.html
- SQLite Online Backup API: https://www.sqlite.org/backup.html
- Android foreground services: https://developer.android.com/develop/background-work/services/fgs
- Android foreground-service types: https://developer.android.com/develop/background-work/services/fgs/service-types
- Google Play foreground-service requirements: https://support.google.com/googleplay/android-developer/answer/13392821
- Riverpod: https://pub.dev/packages/flutter_riverpod
- fl_chart: https://pub.dev/packages/fl_chart
- file_picker: https://pub.dev/packages/file_picker
- wakelock_plus: https://pub.dev/packages/wakelock_plus
- flutter_foreground_task: https://pub.dev/packages/flutter_foreground_task
- timezone: https://pub.dev/packages/timezone
- archive: https://pub.dev/packages/archive
- cryptography: https://pub.dev/packages/cryptography
- flutter_markdown_plus: https://pub.dev/packages/flutter_markdown_plus

---

# Final implementation directive

Build Ayutam as a trustworthy local application first and a visually distinctive flip-clock product second. The clock attracts the user; the database, state machine, migration discipline, and verified backups keep the user for years.
