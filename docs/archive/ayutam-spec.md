> **SUPERSEDED — do not use as implementation source of truth.**
>
> This document is retained for historical traceability only. The authoritative specification lives under `docs/` (see [docs/README.md](../README.md)). An implementing agent must follow `AGENTS.md` and the current docs, not this archive file.
>
> Archived: 2026-07-22

---
# Ayutam — Product & Technical Specification (v1.0)

**A local-first, cross-platform 10,000-hour skill tracker built in Flutter, with zero backend, zero accounts, and manual file-based backup as the only sync mechanism.**

| | |
|---|---|
| **Document status** | Final v1 specification — ready for implementation |
| **Audience** | Coding agent (Claude Code, Codex, or human developer), and the product owner (ABR) |
| **Source material** | Two structured requirements interviews (Claude web + ChatGPT web), synthesized and reconciled into this document |
| **License** | MIT (FOSS) |
| **Working name** | Ayutam |

## How to use this document

This is one consolidated specification covering product requirements, functional and feature behavior, UI/UX, technical architecture, data model, and delivery plan. It is written to be handed directly to a coding agent as its primary source of truth. Where the two source interviews gave answers that were incomplete, ambiguous, or in tension with each other, this document resolves them explicitly — every resolution is logged in **Part 25: Open Questions & ADRs**, so ABR can review and override any of them before implementation starts.

**Table of contents** (numbers match the 25 deliverables requested):

1. Product Requirements Document
2. Functional Specification
3. Feature Specification
4. UI/UX Specification
5. Responsive & Platform Layout Specification
6. Technical Architecture
7. Flutter Project Structure
8. State Management Design
9. Database Schema
10. Import/Export File Schema
11. Backup Migration & Conflict-Resolution Specification
12. Timer State Machine
13. User Flows
14. Navigation Model
15. Error & Empty States
16. Accessibility Requirements
17. Security & Privacy Requirements
18. Testing Strategy
19. End-to-End Acceptance Criteria
20. Phased Implementation Plan
21. V1 vs. Future-Feature Boundaries
22. Instructions for Coding Agents
23. Suggested `AGENTS.md`
24. Recommended Flutter Packages & Dependency Rationale
25. Open Questions & Architectural Decision Records

---

# Part 1 — Product Requirements Document

## 1.1 Problem statement

Existing "10,000 hour" / skill-tracking apps force a choice ABR doesn't want to make: pay for the vendor's cloud sync, tolerate ads, or accept that all progress is lost the moment the device is lost, reset, or replaced. There is no backend ABR wants to run or pay for, and he is not a web developer by trade — so long-term maintainability matters more than feature breadth.

## 1.2 Vision

A minimal, good-looking, single-purpose time tracker for deliberate practice. The user creates skills, times sessions against them with a distinctive flip-clock stopwatch, and optionally logs what they learned. All data lives in a local SQLite database on-device. The user owns their data completely: a single **Export** produces one portable backup file they can store anywhere (USB drive, Google Drive, GitHub, a private vault) and **Import** on any other installation of the app, on any supported platform, with no account and no network call required.

## 1.3 Target user

One person: ABR, and by extension anyone with the same profile — a self-directed learner tracking multiple long-horizon skills (e.g., AI Learning, Guitar, Fitness), who is privacy- and cost-conscious, values a minimal and maintainable codebase over a feature-rich one, and is comfortable manually managing a backup file the way they'd manage a password-manager vault or a Beancount ledger.

## 1.4 Goals

- Track time against a skill goal (default 10,000 hours, configurable) via a start/pause/stop stopwatch.
- Capture optional Markdown notes per session, browsable later in a dedicated Learning Log.
- Visualize progress via a cumulative chart, a GitHub-style calendar heatmap, and a summary table.
- Guarantee that all data can leave the device as a single file and be restored losslessly on another installation, with no server involved.
- Ship on Android, Windows, and Linux from one Flutter codebase, architected (but not necessarily released) for Play Store / Microsoft Store distribution later.

## 1.5 Non-goals (explicit, see Part 21 for the full boundary list)

No accounts, no authentication, no backend server, no automatic cloud sync, no social features, no multi-user support — **ever**, not just for v1. No macOS or iOS support. No browser/web build in v1.

## 1.6 Success criteria

- A user can go from "install" to "first logged session with a note" in under two minutes.
- A user can export on Device A and import on Device B and get byte-for-byte-equivalent totals, notes, and timestamps (this is the project's primary acceptance test — see Part 19).
- The codebase is small and legible enough that ABR, coming back to it after months away, can find and modify any given feature without re-learning the architecture from scratch.

---

# Part 2 — Functional Specification

Functional behavior grouped by domain. Each item is a v1 requirement unless marked **(Phase 2)**.

## 2.1 Skills

- A skill has: `name` (required), `description` (optional), `target_hours` (default 10,000, user-configurable, decimal), `color` (optional; auto-assigned from a fixed palette if not chosen), `created_at` (defaults to today, editable).
- Skills are independent and unbounded in number.
- No subskills/categories in v1. Session-level **tags** provide lightweight topical grouping instead (see 2.3).
- Lifecycle: rename, change target, archive, restore from archive, permanent delete. Permanent delete requires the user to type the skill's name to confirm (irreversible, destroys all sessions under it).
- When a skill's accumulated hours reach its target, it is marked **Completed** (a derived/computed state, not a manual field) but tracking continues uninterrupted — the user keeps timing sessions past 10,000 hours if they want to.
- Archiving hides a skill from the primary Skills/Home list and from the timer's skill picker, but its historical sessions remain fully intact and visible in the Learning Log and Statistics. Restoring un-hides it.

## 2.2 Timer

- One active timer across the whole app at a time. Starting a new skill's timer while another is running/paused is not permitted — the UI should make stopping/pausing the current one the obvious next step.
- Controls: **Start**, **Pause/Resume**, **Stop**. Icon-only (no text labels) per visual direction, but every control carries a semantic accessibility label for screen readers regardless of the icon-only visual treatment.
- Two timer **modes**, selectable before starting: **Stopwatch** (open-ended, counts up) and **Pomodoro** (structured focus/break cycles, see 2.8). Both write to the same `sessions` table.
- Elapsed time is never derived from a continuously-running in-memory loop. The moment Start is pressed, a `started_at_utc` timestamp is persisted. Displayed elapsed time is always computed as `now − started_at_utc − paused_duration`, recomputed on every frame and every app resume. This is what makes the timer resilient to backgrounding, app kill, and device restart.
- Pause freezes the displayed counter and accumulates into `paused_duration_seconds`; the session stays open. Resume continues the same session — pause/resume never splits one session into two records.
- If the app is force-closed or the device restarts mid-session: on relaunch, the app detects the persisted running/paused timer and reconstructs elapsed time from the saved timestamp automatically, with no user action required for ordinary gaps. If the gap since the last known heartbeat exceeds a threshold (default 30 minutes, see 12.4), the app shows a **Recovered Session** confirmation dialog: "You have an active AI Learning session that appears to have been running since 2:14 PM (3h 40m ago). Include this full time, or trim it to your last activity?" with **Include full gap** / **Trim to last heartbeat** / **Discard session** options. This satisfies the requirement that time is never silently lost across a crash or restart, while not silently over-counting multi-hour gaps either.
- A warning banner appears after 8 continuous hours on a single session ("This session has been running for 8 hours — still going?") but nothing is auto-stopped.
- No idle/inactivity detection in v1.
- Overlapping sessions (for the same or different skills) are permitted but flagged with a non-blocking warning at save time.
- Android: an active timer shows a persistent, low-priority notification with skill name, live elapsed time, and Pause/Stop actions, so the timer is visible and controllable without opening the app.
- Windows/Linux: the app can minimize to the system tray while a timer runs; the tray icon/tooltip shows the running skill and elapsed time.
- Desktop keyboard shortcuts: `Space` = pause/resume, `Ctrl+Enter` = start, `Ctrl+Shift+Enter` = stop.
- On mobile, when a session starts, the app prompts a rotation to landscape orientation for a more immersive flip-clock display; portrait is used everywhere else. The user is not force-locked — they can rotate back — but landscape is the app's suggested/entered orientation for the running-timer screen.
- "Keep screen awake" is available as a per-session behavior while the timer screen is open (toggle in Settings, default on).

## 2.3 Sessions and notes

- A session record captures: `skill_id`, `start`/`end` timestamps (UTC + originating timezone offset), `active_duration_seconds`, `paused_duration_seconds`, an optional `title`, an optional **Markdown** `note`, zero or more `tags`, `is_manual_entry` flag, `source_device_id`, `created_at`/`updated_at`.
- On Stop, the app immediately persists a completed session record (so nothing is lost even if the app crashes at this exact moment), then opens the **Session Completion** panel showing the computed, read-only Skill / Date / Start–End / Duration, plus editable **Title** (optional), **Note** (optional, Markdown, soft counter appears past 2,000 characters, no hard limit), and **Tags** (optional, freeform with autocomplete from existing tags). One **Save Session** action finalizes it — since the note is optional by design, there is no separate "save without note" button; leaving the note blank and pressing Save is the "skip" path.
- Notes render as Markdown wherever displayed (Learning Log cards, detail view, exports). Headings, bold/italic, lists, and links are supported; no images/attachments in v1.
- Unsaved note text in the completion panel is autosaved as a local draft as the user types, so backgrounding the app or an accidental navigation doesn't lose it.
- Completed sessions are fully editable afterward: title, note, tags, skill, start time, end time (and therefore duration) can all be changed. Editing start/end shows a warning that this will change recorded totals and statistics.
- Manual session entry (no timer involved) is supported from the same Session Completion-style form, for logging time after the fact.
- Deleting a session shows an immediate **Undo** (snackbar-style, ~5 seconds); after that window it is a soft-delete (`deleted_at` set) retained briefly for safety-snapshot recovery, then physically removed on the next scheduled snapshot rotation. No full 30-day trash UI in v1.
- A session whose start/end crosses midnight is stored as a single record, but its duration is split proportionally across the two calendar days for heatmap/daily-statistics purposes (e.g., 11:00 PM–1:00 AM contributes 1h to each day). The Learning Log always shows it as one entry on its start date.

## 2.4 Learning Log

- A dedicated page reviewing all sessions as a structured, scannable journal — never a raw unbroken list (see full UI spec in Part 4).
- Default grouping is by day; the user can switch grouping to week or month.
- Search covers note text, session titles, skill names, tags, and dates.
- Filters (all required for v1): Skill, Date range, Min/max duration, With notes / without notes, Tags, Manual entries / timed sessions.
- Sort: newest first (default), oldest first, longest duration, shortest duration.
- Sessions without notes still appear, with a subtle "No note added" state — they are not hidden.
- Pagination is month-based with lazy loading (load the current month, fetch earlier months as the user scrolls/navigates back), not infinite-scroll-everything or a single virtualized mega-list.
- A compact calendar affordance lets the user jump straight to a specific day's sessions.
- Selecting a session opens a detail view (full note, complete metadata, previous/next navigation, Edit/Delete/Copy actions).

## 2.5 Statistics

- Available both per-skill and as an all-skills combined view, user-switchable.
- A compact summary card (Total hours, Progress % of goal, Remaining, Sessions completed, Rolling 4-week average, Current streak) stays visible above all three statistics sub-views.
- Three sub-views — **Cumulative Chart** (default), **Calendar Heatmap**, **Summary Table** — presented as tabs on desktop and a segmented control on mobile.
- **Cumulative chart**: defaults to one skill; supports overlaying multiple skills for comparison. Time ranges: 7d / 30d / 3mo / 6mo / 1yr / All time / Custom (mobile simplifies the range picker to a shorter default list plus "More"). Aggregation granularity (daily/weekly/monthly) is chosen automatically based on the selected range. Interactions: hover (desktop) / tap (mobile) tooltip showing date, cumulative total, and time added that day; pinch/scroll zoom and pan; explicit date-range selector; fixed milestone lines (10h, 100h, 500h, 1,000h, 5,000h, goal completion); a goal line at the skill's target; full-screen chart mode; export the chart as a PNG image. A projected-completion estimate is shown below the chart (e.g., "At your current 4-week average of 14.5h/week, estimated completion: around March 2039") based on the rolling 4-week average.
- **Calendar heatmap**: GitHub-contribution-graph style, previous 12 months by default with a year selector. Color intensity uses **fixed** buckets (no activity / 1–30m / 31–60m / 1–2h / 2–4h / 4h+) so colors stay comparable across time and across skills — an advanced Settings override lets a user redefine the bucket thresholds if they want (see ADR-005). Tapping/focusing a day shows a lightweight popover with that day's total time; a secondary action in the popover opens the Learning Log filtered to that date for full session detail.
- **Summary table**: rows per period (day/week/month/year, user-switchable) with Total time, Sessions, Average session length, Active days, and % change versus the prior period.
- **Average per week** is defined as a rolling 4-week average, always labeled explicitly as such in the UI so it's never mistaken for an all-time average.
- **Streak** counts a calendar day if at least 2 minutes of active session time was logged that day, across **any** skill (not per-skill). No streak freezes/rest days in v1; a missed day breaks the streak. The 2-minute threshold is user-adjustable in Settings.

## 2.6 Import, export, and backup

- The live application database is **SQLite** (via Drift). The portable backup format is a custom archive, extension `.skilltracker` — a ZIP containing `manifest.json`, `data.json`, and `checksum.sha256` (full schema in Part 10).
- **Export scope**: (a) entire application (all skills, sessions, tags, settings) — the primary backup; (b) a single selected skill and its sessions/notes exported as a human-readable Markdown document (for reading/sharing, not for re-import); (c) a raw SQLite file export (advanced/diagnostic use); (d) a CSV export of sessions (for spreadsheet analysis).
- **Import**: the app parses and validates the backup, shows a preview (backup date, app version, skill/session counts, total recorded time, format version, checksum status, and — where feasible — a diff summary of new/updated/unchanged records versus current data), then the user explicitly chooses **Merge** or **Replace**. Replace fully overwrites local data (with an automatic pre-replace safety snapshot, see below). Merge combines both datasets using last-write-wins conflict resolution keyed on `updated_at` (full algorithm in Part 11).
- A corrupted or checksum-failed backup is rejected outright; local data is never modified until validation fully passes. All imports run inside a single database transaction — a failure partway through leaves the app exactly as it was before the import started.
- Before any Merge or Replace, the app automatically writes a local safety snapshot of the current database (see 2.7).
- Backward compatibility for older backup format versions is mandatory (via versioned migrations); a backup from a *newer* app version than the one currently installed is rejected with a clear "please update the app" message rather than attempting a risky partial import.
- No direct integration with Google Drive / OneDrive / Dropbox / GitHub. The user places the exported file wherever they like via the OS's native file picker / share sheet.
- Export filenames follow `skill-tracker-backup-YYYY-MM-DD-HHMMSS.skilltracker` (no skill name embedded, since full exports cover all skills).

## 2.7 Reliability, backups, and data safety

- Every state-changing action is persisted immediately: timer start/pause/stop, note edits (draft autosave), session save, import initiation.
- The app keeps a small rolling set of **local safety snapshots** (last 3) automatically captured before any import or other destructive/bulk operation, independent of the user-triggered export flow.
- Database integrity is checked on startup; if corruption is detected, the app offers a recovery attempt, the option to export diagnostic information, and restoration from the most recent local safety snapshot.
- Every schema change ships with migration code, migration tests, and backup-compatibility tests.
- Settings surfaces a **backup reminder** (default: weekly) and a persistent **"Last backup: N days ago · M sessions added since"** indicator.

## 2.8 Pomodoro mode

A new v1 feature layered entirely on the existing timer/session model — no separate subsystem:

- Selectable as a timer mode before starting a session (alongside plain Stopwatch).
- Configurable in Settings: focus length (default 25 min), short break (default 5 min), long break (default 15 min), cycles before a long break (default 4). Sensible defaults, fully overridable.
- The flip clock counts **down** during Pomodoro mode instead of up.
- On completing a Focus interval: a local notification/sound fires, that interval's duration is added to the session's `active_duration_seconds`, and a Break countdown begins automatically (skippable).
- Break time accumulates into the same session's `paused_duration_seconds` — i.e., breaks never count toward the skill's tracked hours, reusing the exact mechanism already defined for manual pausing.
- Stopping at any point ends the whole Pomodoro run and drops into the normal Session Completion panel, with the total counted time equal to the sum of completed focus intervals.

## 2.9 Settings

Theme (Light/Dark/Follow system), week-start day (device locale, fallback Monday), 12/24-hour time format (device preference by default, overridable), default statistics period, heatmap intensity range overrides (advanced), backup reminder cadence, reduced motion (disables flip animation), keep-screen-awake toggle, streak minimum duration (default 2 min), date/number format, default export location, optional backup passphrase encryption **(Phase 2)**, optional app lock (biometric/PIN via OS, off by default), diagnostic logging toggle (local-only, opt-in), and — Pomodoro-specific — default focus/break lengths and cycle count.

---

# Part 3 — Feature Specification

Each feature below maps to the functional detail in Part 2 and carries its own acceptance criteria. Status: **V1** (must ship) or **P2** (explicitly deferred, architecture should not block it).

| # | Feature | Status | Acceptance criteria |
|---|---|---|---|
| F-01 | Create / edit / archive / restore / delete skill | V1 | Skill appears on Home immediately after creation with default target 10,000h; archived skills disappear from Home and the timer picker but remain in Learning Log/Stats; permanent delete requires typing the skill name and removes all its sessions. |
| F-02 | Flip-clock stopwatch (start/pause/resume/stop) | V1 | Elapsed time displayed is always `now − start − paused`, verified correct after backgrounding the app for 10+ minutes and reopening. |
| F-03 | Crash/restart timer recovery | V1 | Force-killing the app mid-session and reopening reconstructs elapsed time within the 10-second tolerance (Part 19); gaps over 30 min trigger the Recovered Session dialog. |
| F-04 | Session Completion panel (optional Markdown note, title, tags) | V1 | Pressing Stop always freezes the timer and opens the panel; pressing Save with an empty note field saves successfully with "No note added" shown later. |
| F-05 | Edit/delete a saved session | V1 | Editing start/end recalculates duration and shows a change warning; delete offers a 5-second Undo. |
| F-06 | Manual (timer-less) session entry | V1 | A session can be created purely by entering start/end times, with the same validation as timed sessions. |
| F-07 | Learning Log (grouped timeline, search, filters, calendar jump) | V1 | All Part 2.4 filters function together (AND-combined); search returns results within 300ms for 10,000 sessions on a mid-range Android device. |
| F-08 | Statistics: Cumulative chart | V1 | Switching time range updates aggregation granularity automatically; overlay mode correctly renders 2+ skills with distinct colors and a legend. |
| F-09 | Statistics: Calendar heatmap | V1 | Bucket colors match the fixed thresholds; tapping a day shows accurate total time; the secondary action opens Learning Log pre-filtered to that date. |
| F-10 | Statistics: Summary table | V1 | Switching period (day/week/month/year) recalculates all columns; % change is blank ("—") for the first period with no prior data. |
| F-11 | Full backup export (.skilltracker) | V1 | Export produces a valid ZIP passing its own checksum validation; contains every skill, session, tag, and setting present at export time. |
| F-12 | Full backup import (Merge / Replace, with preview) | V1 | Importing the exact file just exported into a fresh install reproduces identical totals, notes, and timestamps (see Part 19 E2E test). |
| F-13 | Per-skill Markdown export | V1 | Produces one readable `.md` file grouped by date with full note content; not intended or required to be re-importable. |
| F-14 | CSV session export | V1 | One row per session with skill, times, duration, tags, and note text; opens cleanly in a standard spreadsheet app. |
| F-15 | Automatic local safety snapshots | V1 | A snapshot is written immediately before every Merge/Replace/other destructive action; the 3 most recent are retained and restorable from Settings. |
| F-16 | Backup reminder + "last backup" indicator | V1 | Settings always shows an accurate "Last backup: N days ago" and a weekly reminder surfaces if no export has happened. |
| F-17 | Pomodoro mode | V1 | A completed Pomodoro run logs a session whose `active_duration_seconds` equals the sum of completed focus intervals only. |
| F-18 | Android persistent timer notification | V1 | Notification appears within 1s of Start, live-updates elapsed time, and its Pause/Stop actions control the same running timer. |
| F-19 | Windows/Linux system tray timer | V1 | Minimizing during an active timer shows a tray icon with live tooltip; restoring returns to the running timer screen. |
| F-20 | Desktop keyboard shortcuts | V1 | Space/Ctrl+Enter/Ctrl+Shift+Enter function globally while the timer screen has focus. |
| F-21 | Light/Dark/Follow-system theme | V1 | Switching theme applies instantly with no restart; Follow System tracks OS changes live. |
| F-22 | Per-skill accent color | V1 | Auto-assigned from a fixed palette on creation if the user doesn't pick one; used consistently across Home cards, charts, and heatmap-by-skill views. |
| F-23 | Onboarding (3-step, backup emphasis) | V1 | Shown only on first launch with zero skills; explicitly explains local-only storage and manual backup responsibility. |
| F-24 | Optional app lock (biometric/PIN) | V1 | Off by default; when enabled, gates app open using the OS-native prompt (`local_auth`), no custom credential storage. |
| F-25 | Update check via GitHub Releases | P2 | Uses GitHub's public REST API only (no custom backend); opt-in; app functions fully offline if disabled. |
| F-26 | Optional backup passphrase encryption | P2 | When enabled, `data.json` inside the archive is encrypted; unencrypted `.skilltracker` remains the default. |
| F-27 | Play Store / Microsoft Store packaging | P2 | Codebase and CI structured so store builds are an additive packaging step, not a rearchitecture (see Part 20). |

---

# Part 4 — UI/UX Specification

## 4.1 Visual design direction

**Style**: dark-productivity-first, with GitHub-inspired developer-tool touches (flat cards, subtle borders over heavy shadows, monospace numerals for time values, a contribution-graph-style heatmap) built on Material 3 components for consistency and accessibility for free.

**Theme**: Light and Dark both shipped; default is **Follow System**, user-overridable in Settings.

**Typography**: A standard UI sans-serif (Material 3 default, e.g. Roboto/system font) for body text and labels; a monospaced numeric face (e.g. **Roboto Mono** or **JetBrains Mono**) specifically for all duration and timer figures app-wide (flip clock, session cards, summary cards, chart tooltips) — this is what gives the app its "developer tool" numeric identity and distinguishes duration text from prose at a glance.

**Color**: One neutral dark/light base theme; each skill carries its own accent color, auto-assigned from a fixed, colorblind-considerate palette (8–10 hues) when not manually chosen, used consistently for that skill's Home card edge, chart line/legend entry, and (in per-skill heatmap view) cell tint. The all-skills heatmap view uses a single neutral green scale, matching the familiar GitHub contribution-graph convention.

## 4.2 The flip clock (signature component)

Research into the reference apps (Fliqlo and similar split-flap clock apps/screensavers) surfaces a consistent visual language worth matching closely:

- **High-contrast, minimal**: large, bold numerals on a flat, matte card background — classically stark white-on-black, though Ayutam should use the active theme's on-surface/surface colors so it still works in Light theme.
- **Physically legible split-flap card**: each digit sits on its own rectangular "flap" card with a thin horizontal seam across its vertical center (the mechanical split line), a very slight drop-shadow/gradient near that seam to imply the two-half-card structure, and modest rounded corners — not a flat digital-font readout.
- **The flip itself**: when a digit changes, the *top half* of the new digit's card appears to fold down from the top (like a page turning) while the bottom half of the old digit's card appears to still be settling — implemented as a short (~250–350ms) 3D rotation (`Matrix4.rotateX`) of the top-half panel, easing out, rather than a simple crossfade. This should be a custom Flutter widget (see Part 24 — no well-maintained package matches this closely enough), built once as a reusable `FlipDigit` and composed into a `FlipClock` of however many digit cards are needed.
- **No literal skeuomorphic clock face, no screws/bezel graphics** — the aesthetic is the flap cards themselves, on the app's flat background, which is exactly how these apps present on a desk in "study-with-me" videos.
- **Reduced Motion**: when enabled in Settings, digit changes crossfade instantly instead of animating the flip, for battery and comfort.

### Clock layout

Per 3.1/3.2: the **cumulative total** (all-time accumulated hours for the skill) is the dominant, larger clock; the **current session** duration is a visibly smaller readout beneath it. Both use separate flip cards per unit — Hours / Minutes / Seconds — with the Hours group supporting however many digits the accumulated total needs (e.g. a skill approaching 10,000h needs 5 digit-cards for hours: `02220` would be wrong — actually just as many digits as the number requires, unpadded beyond 2 digits, e.g. `220h` `0035m` is unnecessary; render exactly `220 : 35 : 42` scaled to fit, left-padding hours to at least 2 digits only). Example composition at 220h 35m 42s elapsed, mid-session at 12m 04s:

```
┌────┐┌────┐┌────┐   ┌────┐┌────┐        ← Total (large)
│ 2  ││ 2  ││ 0  │ h │ 3  ││ 5  │ m  ...
└────┘└────┘└────┘   └────┘└────┘

        00:12:04                          ← Current session (small, plain mono text, no flip)
```

The current-session readout does not need its own flip-card treatment (that would visually compete with the primary clock) — plain large monospace digits suffice, consistent with "the clock should be the major look, controls should not occupy the screen."

## 4.3 Screens

### 4.3.1 Skills (Home)

This is the app's default screen and doubles as the "Timer" entry point (see Part 14 for the navigation resolution). Vertically stacked **skill panels**, one per active (non-archived) skill:

- Left accent-color edge stripe (the skill's color).
- Skill name, target hours, a thin progress bar, "X% of Ngoal" and "remaining Yh" as compact text.
- A prominent **Play** button that, when tapped, shows a lightweight "Start session for {Skill}?" confirmation, then transitions full-screen into the Timer view (4.3.2).
- Tapping the card body (not Play) expands it in place to show a short **Recent Sessions** strip (last ~5, compact) plus a "View all in Learning Log" link, and an overflow menu (⋯) for Rename / Edit target / Archive / Delete.
- A persistent **+ New Skill** action (FAB on mobile, button in the app bar on desktop).
- Empty state (no skills yet): guided onboarding message, "Create your first skill to begin tracking," with the New Skill action front and center.

### 4.3.2 Timer (entered from a skill's Play button)

Full-screen, minimal chrome: skill name label, the flip clock (4.2), Start/Pause/Stop as icon-only buttons in a small cluster that does not compete visually with the clock, a thin progress indicator toward the goal. On mobile this screen requests landscape orientation. On Stop, this screen transitions directly into the Session Completion panel (4.3.3) — there is no intermediate "are you sure" step for a normal stop, only for sessions under the accidental-short-session threshold (Part 2.2 default-behavior note).

### 4.3.3 Session Completion panel

A modal panel (bottom sheet on mobile, dialog on desktop) showing read-only computed Skill / Date / Start–End / Duration at the top, then editable **Title** (single line, optional), **Note** (multi-line Markdown editor with a Preview toggle, optional, soft counter past 2,000 chars), **Tags** (chip input with autocomplete), and a single primary **Save Session** action. A secondary **Discard** action (with confirmation, since it deletes the just-recorded session) is available for accidental starts.

### 4.3.4 Learning Log

Per 8.1's resolved hybrid layout:
- **Desktop**: two-pane — left pane is the grouped/filterable session list (search bar, filter chips, grouping selector, calendar-jump affordance, then grouped cards); right pane shows the full detail (rendered Markdown note, metadata, prev/next navigation, Edit/Delete/Copy) for whichever card is selected on the left. Nothing needs to navigate away from the page to read a full note.
- **Mobile**: the grouped timeline from the earlier mockup (search bar, horizontally-scrollable filter chips, grouped-by-day/week/month cards with 2-line-clamped note previews), with a calendar/filter drawer accessible from the app bar; tapping a card opens the detail as a full-screen page (not a bottom sheet, since notes can be long) with a back action returning to the exact scroll position.
- Grouping selector (Day/Week/Month) sits near the search bar on both platforms.

*(This refines, not replaces, the standalone Learning Log mockup built earlier in this conversation — that mockup's mobile timeline and card design carry over directly; the addition here is the desktop two-pane layout in place of the single-column timeline previously shown for desktop.)*

### 4.3.5 Statistics

Skill selector (a specific skill, or "All skills") at the top, always-visible summary card beneath it, then the three sub-views as desktop tabs / mobile segmented control: Cumulative Chart (default) / Calendar Heatmap / Summary Table, per Part 2.5.

### 4.3.6 Settings

A single scrollable, grouped list (Appearance, Time & Locale, Timer & Pomodoro, Backup, Privacy & Security, About), each row a standard Material list tile opening the relevant control inline or in a small dialog.

## 4.4 Empty and confirmation patterns

- Guided empty states everywhere data is absent (Skills, Learning Log, Search-no-results — copy patterns given in Part 15).
- **Undo** is preferred over confirmation dialogs for common reversible actions (delete session, discard a draft note). Confirmation dialogs are reserved for destructive/irreversible actions: permanent skill deletion (type-to-confirm), Replace-on-import (explicit warning of what will be overwritten), and Delete All Local Data.

---

# Part 5 — Responsive & Platform Layout Specification

Defined explicitly so an implementing agent doesn't have to guess breakpoints. These are Flutter logical-pixel width breakpoints, checked against `MediaQuery` width.

| Class | Width range | Nav pattern | Layout notes |
|---|---|---|---|
| Compact phone | < 360dp | Bottom nav bar (4 items) | Single-column everything; summary cards horizontally scroll; filter chips horizontally scroll. |
| Large phone | 360–599dp | Bottom nav bar (4 items) | Same as compact, more breathing room; this is the primary phone target. |
| Tablet | 600–839dp | Bottom nav bar OR left rail (rail if landscape) | Learning Log may adopt an early two-pane layout in landscape if width allows ≥ 720dp. |
| Desktop | 840–1439dp | Left navigation rail (4 items, icon + label) | Two-pane Learning Log, tabbed Statistics, full chart interactions (hover, zoom). |
| Wide desktop | ≥ 1440dp | Left navigation rail, can expand to labeled sidebar | Extra horizontal space goes to wider charts and a wider Learning Log detail pane, not more columns of content. |

**Orientation**: portrait and landscape both supported generally. The Timer screen (4.3.2) specifically requests landscape on phones when a session starts (see 2.2); every other screen has no orientation preference.

**Platform-specific enhancements** (explicitly approved, provided they don't require a second codebase — all achievable through Flutter's platform-conditional widgets/plugins within the single codebase):
- Desktop: keyboard shortcuts (2.2), system tray (2.2), drag-and-drop backup file import onto the Import screen, larger default chart canvas.
- Mobile: persistent timer notification (2.2), landscape-on-session-start, bottom nav.
- **Not included**: a side-by-side Learning Log detail panel is desktop-only as described above — this was explicitly the one exception ABR called out as *not* needing to be forced onto mobile, and it isn't; mobile keeps the full-screen detail page pattern instead.

---

# Part 6 — Technical Architecture

## 6.1 Architectural style

**Feature-based modular architecture** with clear repository and service boundaries — not strict enterprise Clean Architecture (too heavy for a single-developer, single-user local app), but with enough layering discipline that business logic never depends directly on Drift/SQLite types or Flutter widgets.

```
UI (widgets, screens)
   │  reads/writes via
   ▼
State layer (Riverpod providers / notifiers)
   │  calls
   ▼
Application/use-case layer (plain Dart classes: StartSessionUseCase, ExportBackupUseCase, ...)
   │  depends on interfaces from
   ▼
Domain layer (entities: Skill, Session, Tag — pure Dart, no Flutter/Drift imports)
   │  implemented by
   ▼
Repository layer (SkillRepository, SessionRepository, SettingsRepository — interfaces + Drift-backed implementations)
   │  reads/writes
   ▼
Data sources (Drift database, file system for backups/snapshots, platform channels for tray/notifications)
```

**Dependency rule**: inner layers (domain, use-cases) never import Flutter or Drift. Repository interfaces live in the domain/application layer; their Drift-backed implementations live in the data layer and are injected via Riverpod providers. This is what lets database tests run without a widget test harness, and lets the DB library be swapped later without touching business logic.

## 6.2 Cross-cutting services

- **TimerService**: owns the single source of truth for "is a timer running/paused, for which skill, since when" — persisted immediately to the `timer_state` table on every transition (see Part 9, Part 12).
- **BackupService**: builds/validates `.skilltracker` archives, runs the merge/replace algorithm (Part 11), and manages the rolling local safety snapshots.
- **NotificationService**: Android persistent notification + local notifications for Pomodoro phase changes.
- **TrayService**: Windows/Linux system tray icon and menu.
- **ClockService**: wraps `DateTime.now()` + a monotonic stopwatch, used everywhere elapsed time is computed, so drift/clock-change validation (5.5) lives in one place.
- **SettingsService**: thin KV-store wrapper over the `app_settings` table.

## 6.3 Error handling strategy

- Repository methods return `Result<T, AppFailure>` (a small sealed-class result type) rather than throwing across layer boundaries — use-cases and providers pattern-match on success/failure and surface user-facing messages from a central catalog (Part 15).
- Database and file-system operations that can partially fail (import, migration) always run inside a transaction; failures roll back completely rather than leaving partial state (2.6, 2.7).
- Uncaught exceptions are caught at the top of the widget tree, logged to a local diagnostic log file (never transmitted anywhere — 17.2), and shown as a generic non-technical error with an "Export diagnostic log" action, not a stack trace.

---

# Part 7 — Flutter Project Structure

```
ayutam/
├── lib/
│   ├── main.dart
│   ├── app.dart                      # MaterialApp, theme, root shell
│   ├── core/
│   │   ├── result.dart                # Result<T, AppFailure> sealed type
│   │   ├── failures.dart
│   │   ├── clock_service.dart
│   │   ├── id_generator.dart          # uuid v4 wrapper
│   │   └── constants.dart             # milestones, default targets, thresholds
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── skill.dart
│   │   │   ├── session.dart
│   │   │   ├── tag.dart
│   │   │   └── timer_state.dart
│   │   └── repositories/              # abstract interfaces only
│   │       ├── skill_repository.dart
│   │       ├── session_repository.dart
│   │       ├── settings_repository.dart
│   │       └── backup_repository.dart
│   ├── data/
│   │   ├── drift/
│   │   │   ├── database.dart          # AppDatabase (Drift), schemaVersion, migrations/
│   │   │   ├── tables/                # one file per table
│   │   │   └── daos/
│   │   ├── repositories_impl/         # Drift-backed implementations of domain interfaces
│   │   └── backup/
│   │       ├── skilltracker_archive.dart   # zip + manifest + checksum read/write
│   │       ├── merge_engine.dart           # Part 11 algorithm
│   │       └── csv_markdown_exporters.dart
│   ├── application/
│   │   ├── timer/                     # StartSession, PauseSession, StopSession, RecoverSession use-cases
│   │   ├── skills/
│   │   ├── sessions/
│   │   ├── stats/                     # aggregation/rollup use-cases feeding charts
│   │   └── backup/
│   ├── state/                         # Riverpod providers/notifiers, one folder per feature, mirrors application/
│   ├── features/
│   │   ├── skills_home/               # screens + feature-local widgets
│   │   ├── timer/
│   │   ├── session_completion/
│   │   ├── learning_log/
│   │   ├── statistics/
│   │   └── settings/
│   ├── widgets/                       # shared, cross-feature widgets
│   │   ├── flip_clock/
│   │   │   ├── flip_digit.dart
│   │   │   └── flip_clock.dart
│   │   ├── heatmap/
│   │   └── charts/
│   ├── platform/
│   │   ├── android_notification/
│   │   ├── desktop_tray/
│   │   └── window_manager/
│   └── l10n/                          # reserved for future localization; English only in v1
├── test/
│   ├── domain/
│   ├── application/
│   ├── data/                          # includes migration + round-trip tests
│   └── widget/
├── integration_test/                  # cross-platform E2E, incl. the Part 19 backup round-trip
├── AGENTS.md                          # see Part 23
├── pubspec.yaml
└── README.md
```

Rationale: `domain/` and `application/` never import `package:flutter` or `package:drift`, which keeps the fast unit-test suite (Part 18) fast and keeps a future non-Flutter reuse (unlikely, but free) possible. `features/` is organized by product feature, not by widget type, so an agent working on "Learning Log" touches one folder.

---

# Part 8 — State Management Design (Riverpod)

Using plain `flutter_riverpod` (no code generation) to avoid stacking a second build_runner-driven codegen tool on top of Drift's — one codegen dependency (Drift) is enough for a small, maintainable app (see ADR-008 rationale by analogy, and Part 24).

## 8.1 Provider inventory

| Provider | Type | Owns |
|---|---|---|
| `appDatabaseProvider` | `Provider<AppDatabase>` | Singleton Drift database instance. |
| `skillRepositoryProvider`, `sessionRepositoryProvider`, `settingsRepositoryProvider`, `backupRepositoryProvider` | `Provider<T>` | Repository implementations, injected with the database. |
| `skillsListProvider` | `StreamProvider<List<Skill>>` | Live (reactive, via Drift's `.watch()`) list of active skills for the Home screen. |
| `archivedSkillsProvider` | `StreamProvider<List<Skill>>` | For the archive-management view. |
| `timerControllerProvider` | `StateNotifierProvider<TimerController, TimerUiState>` | The single source of truth for the active timer's UI state; wraps `TimerService`. Drives the Timer screen and the persistent notification/tray. |
| `sessionCompletionControllerProvider` | `StateNotifierProvider.autoDispose` | Draft title/note/tags while the Session Completion panel is open; autosaves the note draft. |
| `learningLogControllerProvider` | `StateNotifierProvider` | Current filter/sort/grouping selection + paginated (month-windowed) session query results. |
| `statisticsControllerProvider` | `family` `StateNotifierProvider` keyed by skill-or-all | Selected time range, chart data, heatmap data, summary table data for the current selection. |
| `settingsProvider` | `StateNotifierProvider<SettingsController, AppSettings>` | All Settings values; persists on every change. |
| `backupControllerProvider` | `StateNotifierProvider.autoDispose` | Drives export/import flows: progress, validation preview, merge/replace choice. |

## 8.2 Reactivity pattern

Repositories expose `Stream<List<T>>` via Drift's built-in query-watching (`select(...).watch()`), so `skillsListProvider` and similar list providers update automatically whenever the underlying table changes — no manual cache invalidation needed after a session is saved, a skill is archived, etc. One-shot operations (start/stop timer, save session, run import) go through `StateNotifier` methods that call into the application/use-case layer and update local UI state (loading/success/error) while the underlying repositories' streams propagate the actual data change to every screen watching it.

## 8.3 Timer state persistence detail

`TimerController` mirrors the single row in the `timer_state` table (Part 9). Every transition (`start`, `pause`, `resume`, `stop`) first writes to that table, *then* updates in-memory `TimerUiState` — never the reverse — so a kill immediately after any button press still leaves durable state to recover from on next launch (this is what Part 2.2's crash-recovery behavior is built on).

---

# Part 9 — Database Schema

Drift (typed SQL, SQLite underneath) is the canonical live-application store. All timestamps are stored as UTC Unix milliseconds (`INTEGER`); timezone offsets are stored alongside, in minutes, so historical local time can always be reconstructed regardless of the device's current timezone setting (per 5.1/5.2).

```sql
-- Skills -----------------------------------------------------------
CREATE TABLE skills (
  id               TEXT PRIMARY KEY,       -- uuid v4
  name             TEXT NOT NULL,
  description      TEXT,
  target_hours     REAL NOT NULL DEFAULT 10000,
  color            TEXT,                   -- hex, nullable = auto-assign from palette by row order
  status           TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','archived')),
  created_at       INTEGER NOT NULL,       -- utc ms
  archived_at      INTEGER,                -- utc ms, null unless archived
  updated_at       INTEGER NOT NULL,
  deleted_at       INTEGER                 -- soft-delete marker (undo window), null normally
);

-- Sessions -----------------------------------------------------------
CREATE TABLE sessions (
  id                       TEXT PRIMARY KEY,   -- uuid v4
  skill_id                 TEXT NOT NULL REFERENCES skills(id),
  title                    TEXT,
  note                     TEXT,               -- markdown, nullable
  start_utc                INTEGER NOT NULL,
  end_utc                  INTEGER,             -- null while a session is actively running
  start_tz_offset_minutes  INTEGER NOT NULL,    -- e.g. +330 for IST at time of logging
  active_duration_seconds  INTEGER NOT NULL DEFAULT 0,
  paused_duration_seconds  INTEGER NOT NULL DEFAULT 0,
  is_manual_entry          INTEGER NOT NULL DEFAULT 0,  -- boolean
  timer_mode               TEXT NOT NULL DEFAULT 'stopwatch' CHECK (timer_mode IN ('stopwatch','pomodoro')),
  source_device_id         TEXT NOT NULL,
  created_at               INTEGER NOT NULL,
  updated_at               INTEGER NOT NULL,
  deleted_at                INTEGER
);
CREATE INDEX idx_sessions_skill_start ON sessions(skill_id, start_utc);
CREATE INDEX idx_sessions_start       ON sessions(start_utc);   -- global timeline / all-skills views

-- Tags -----------------------------------------------------------
CREATE TABLE tags (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL UNIQUE,
  created_at  INTEGER NOT NULL
);

CREATE TABLE session_tags (
  session_id  TEXT NOT NULL REFERENCES sessions(id),
  tag_id      TEXT NOT NULL REFERENCES tags(id),
  PRIMARY KEY (session_id, tag_id)
);

-- Active/paused timer (singleton row, id is always 1) --------------
CREATE TABLE timer_state (
  id                              INTEGER PRIMARY KEY CHECK (id = 1),
  skill_id                        TEXT REFERENCES skills(id),
  status                          TEXT CHECK (status IN ('idle','running','paused')),
  started_at_utc                  INTEGER,
  accumulated_active_before_pause INTEGER,   -- seconds
  paused_at_utc                   INTEGER,
  timer_mode                      TEXT CHECK (timer_mode IN ('stopwatch','pomodoro')),
  pomodoro_phase                  TEXT CHECK (pomodoro_phase IN ('focus','short_break','long_break')),
  pomodoro_cycle_count             INTEGER,
  last_heartbeat_utc              INTEGER    -- updated periodically while running; used for the 30-min gap check on relaunch
);

-- Settings (simple KV store) ----------------------------------------
CREATE TABLE app_settings (
  key    TEXT PRIMARY KEY,
  value  TEXT NOT NULL     -- JSON-encoded where the value isn't a plain scalar
);

-- Local safety snapshot metadata (files live on disk; this indexes them) --
CREATE TABLE local_snapshots (
  id          TEXT PRIMARY KEY,
  created_at  INTEGER NOT NULL,
  reason      TEXT NOT NULL,   -- 'pre_merge' | 'pre_replace' | 'scheduled'
  file_path   TEXT NOT NULL
);
```

**Notes**:
- Midnight-crossing day-split (2.3) is computed at query time in the statistics/heatmap aggregation queries, not persisted as extra rows — the `sessions` table remains the single source of truth.
- Soft-delete (`deleted_at`) exists on `skills` and `sessions` purely to support the 5-second Undo and the merge engine's tombstone propagation (Part 11); a scheduled cleanup physically removes rows soft-deleted more than a few days ago (well before any safety-snapshot retention would need them).
- Schema versioning and migrations use Drift's built-in `MigrationStrategy`; every version bump requires a paired migration test asserting both the schema change and that pre-existing data survives it (16.3).
- At the target scale (20 years, 100 skills, 100,000 sessions, ~2KB notes) this schema stays comfortably under 300MB even before SQLite compression — no partitioning or archiving strategy is needed; the two composite indexes above are what keep Learning Log and Statistics queries fast at that volume.

---

# Part 10 — Import/Export File Schema

## 10.1 `.skilltracker` backup archive

A ZIP file (any standard zip tool can open it, though the app itself is the only intended consumer) containing exactly three entries:

```
skill-tracker-backup-2026-07-22-193000.skilltracker
├── manifest.json
├── data.json
└── checksum.sha256
```

**`manifest.json`**
```json
{
  "formatVersion": 1,
  "appVersion": "1.0.0",
  "exportedAtUtc": "2026-07-22T13:30:00Z",
  "sourceDeviceId": "b3f1c2a0-....",
  "counts": { "skills": 4, "sessions": 1284, "tags": 37 },
  "totalActiveSeconds": 793234,
  "checksumAlgorithm": "sha256"
}
```

**`data.json`**
```json
{
  "skills": [
    {
      "id": "uuid", "name": "AI Learning", "description": null,
      "targetHours": 10000, "color": "#3E6355", "status": "active",
      "createdAt": "2025-01-04T00:00:00Z", "archivedAt": null,
      "updatedAt": "2026-07-22T13:00:00Z", "deletedAt": null
    }
  ],
  "sessions": [
    {
      "id": "uuid", "skillId": "uuid", "title": null,
      "note": "Studied attention mechanism...", "startUtc": "2026-07-09T13:30:00Z",
      "endUtc": "2026-07-09T15:30:00Z", "startTzOffsetMinutes": 330,
      "activeDurationSeconds": 7200, "pausedDurationSeconds": 0,
      "isManualEntry": false, "timerMode": "stopwatch",
      "sourceDeviceId": "uuid", "createdAt": "...", "updatedAt": "...", "deletedAt": null,
      "tags": ["Transformers", "Attention"]
    }
  ],
  "tags": [ { "id": "uuid", "name": "Transformers", "createdAt": "..." } ],
  "settings": { "theme": "dark", "weekStart": "locale", "streakMinimumMinutes": 2, "...": "..." }
}
```

**`checksum.sha256`**: the SHA-256 hex digest of `data.json`'s exact bytes, one line. Import recomputes this over the extracted `data.json` and rejects the archive on any mismatch, before touching the live database (2.6, 2.7).

Tags are embedded inline on each session (by name) in `data.json` for portability/readability, in addition to being a first-class table in the live SQLite schema — the importer resolves names back to (or creates) `tags` rows and `session_tags` links.

## 10.2 CSV session export

One row per non-deleted session:

```csv
skill_name,title,start_local,end_local,duration_hms,duration_seconds,tags,note
"AI Learning","","2026-07-09 19:00","2026-07-09 21:00","02:00:00",7200,"Transformers;Attention","Studied attention mechanism, practiced transformer architecture diagrams..."
```
Times are rendered in the timezone active in Settings at export time (5.2); the note column preserves the raw Markdown, CSV-escaped.

## 10.3 Per-skill Markdown export

One `.md` file per requested skill, e.g. `ai-learning-2026-07-22.md`, structured as:

```markdown
# AI Learning

## 9 July 2026
**7:00 PM – 9:00 PM · 2h 00m**

Studied attention mechanism, practiced transformer architecture diagrams, and revised tokenization basics.

Tags: Transformers, Attention, Theory

---
## 8 July 2026
...
```
This is a read/share artifact only — it is not a re-importable backup format (10.6 answer).

## 10.4 Raw SQLite export

A direct copy of the live `.sqlite` file, offered only under an "Advanced / Diagnostic" section of Settings, clearly labeled as not portable across app versions the way `.skilltracker` is guaranteed to be.

---

# Part 11 — Backup Migration & Conflict-Resolution Specification

## 11.1 Backup format migrations

`manifest.json.formatVersion` is independent of the app's own version number. On import, if `formatVersion` is older than the app's current supported version, a registered migration function upgrades the parsed `data.json` in memory (never rewriting the archive file itself) before validation and merge/replace proceed. If `formatVersion` is *newer* than anything the installed app understands, import is refused with: "This backup was created by a newer version of Ayutam. Please update the app before importing." (2.6).

## 11.2 Replace strategy

1. Validate archive (checksum, schema) — reject on any failure, no changes made.
2. Write an automatic local safety snapshot of the current database (`reason: 'pre_replace'`).
3. Inside a single DB transaction: delete all current skills/sessions/tags/settings, insert everything from `data.json`.
4. Commit. On any failure inside the transaction, it rolls back completely and the pre-existing data is untouched (the snapshot from step 2 is an extra safety margin, not the primary rollback mechanism — the transaction itself is).

## 11.3 Merge strategy

Applies independently per entity type (`skills`, `sessions`, `tags`), matched by their UUID `id` — never by name or position:

| Local state | Incoming state | Resolution |
|---|---|---|
| Not present locally | Present in backup | Insert as new. |
| Present, `updated_at` identical | Present, identical `updated_at` | No-op (already in sync). |
| Present, unchanged since last known sync point | Present, newer `updated_at` | Take the incoming version (it changed, local didn't). |
| Present, changed locally | Present, `updated_at` older/equal to local | Keep local (local is newer or equal). |
| Present, changed locally | Present, `updated_at` newer than local | **Last-write-wins: take the incoming version wholesale.** No field-level merge, no manual per-conflict prompt — this matches the explicit "keep newest" decision for the two-device scenario (Part 25, and see the note below on why this is deliberately simple). |
| Soft-deleted locally (`deleted_at` set) | Present, older `updated_at` | Deletion wins (it's the newer state change). |
| Present locally | Soft-deleted in backup, newer `updated_at` | Incoming deletion wins; local row is soft-deleted. |

`session_tags` link rows follow their parent session: whichever side's session record wins, that side's tag associations are applied.

**Why whole-record last-write-wins rather than field-level merging or a manual conflict UI**: field-level merge (e.g. keeping a locally-edited note but a remote-edited duration from the same record) requires tracking per-field modification timestamps, which meaningfully increases schema and testing surface for a single-user app where true simultaneous edits to the *same* record on two devices are a rare edge case, not the common path. A manual "resolve every conflict" UI has the same problem in the other direction — it adds a whole interaction surface for something that will almost never fire in practice. Whole-record LWW is simple, predictable, easy to test exhaustively, and was ABR's explicit choice for the concrete two-device scenario (10.9) — this section just generalizes that same rule to every entity type rather than only session totals.

## 11.4 Merge preview

Before the user commits to Merge or Replace, the app computes (read-only, no writes) and displays: counts of records that will be **inserted**, **updated**, and **left unchanged**, plus the manifest summary (10.1). For Replace, it additionally shows what will be **removed** (i.e., everything currently local that isn't in the incoming backup), since that's the more destructive path.

## 11.5 Safety snapshots

Independent of backups the user explicitly exports, the app keeps up to 3 rolling local snapshots (full SQLite file copies) written automatically immediately before any Merge, Replace, or other bulk/destructive operation. Restorable from Settings → Advanced without needing an external file at all. Oldest snapshot beyond 3 is deleted on each new snapshot write.

---

# Part 12 — Timer State Machine

## 12.1 Core states

```
        start()                      pause()
IDLE ───────────► RUNNING ◄─────────────────────► PAUSED
                     │                                │
                     │ stop()                stop()   │
                     ▼                                ▼
               STOPPING (freeze, compute totals) ◄─────┘
                     │
                     ▼
         SESSION_COMPLETION (note panel open)
                     │  save() / discard()
                     ▼
                   IDLE
```

- **IDLE**: no `timer_state` row is "active" (`status = 'idle'`, or no row). Home/Skills screen shows all skill Play buttons enabled.
- **RUNNING**: `timer_state.status = 'running'`, `started_at_utc` set. Elapsed = `now − started_at_utc − accumulated_active_before_pause_adjustments`. Every ~15s while running, `last_heartbeat_utc` is updated (used only for crash-gap detection, not for elapsed-time computation itself, which always derives from `started_at_utc`).
- **PAUSED**: `status = 'paused'`, `paused_at_utc` set, the elapsed-at-pause value frozen into `accumulated_active_before_pause`. Resuming re-enters RUNNING with a fresh effective start reference so the `now − start − paused` formula stays correct.
- **STOPPING**: a transient computation step, not a persisted state — freezes final `active_duration_seconds`/`paused_duration_seconds`, writes a completed `sessions` row immediately (2.3's "save immediately, then open the note panel" behavior), and clears `timer_state` back toward idle.
- **SESSION_COMPLETION**: UI-only state (not persisted to `timer_state`) while the note/title/tags panel is open on the already-saved session; Save/Discard both resolve back to IDLE.

## 12.2 Recovery sub-flow (app relaunch with a persisted RUNNING or PAUSED row)

```
App launch
   │
   ▼
timer_state.status == running/paused? ──No──► normal launch (IDLE)
   │ Yes
   ▼
gap = now − last_heartbeat_utc
   │
   ├─ gap ≤ 30 min  ──► silently resume; elapsed recomputed from started_at_utc as normal
   │
   └─ gap > 30 min  ──► show "Recovered Session" dialog:
                          • Include full gap  → resume with elapsed including the gap
                          • Trim to last heartbeat → set an internal offset so elapsed stops
                                                       counting at last_heartbeat_utc, then
                                                       resumes counting from "now"
                          • Discard session   → drop the in-progress session entirely, IDLE
```

This directly implements the 3.6/3.7 combination: ordinary interruptions resume invisibly; unusually long ones (device off overnight, app killed for days) get a confirmation rather than silently either losing time or over-counting a multi-hour gap.

## 12.3 Pomodoro overlay

Pomodoro is not a separate state machine — it's additional fields on the same RUNNING state (`pomodoro_phase`, `pomodoro_cycle_count`) that drive automatic phase transitions:

```
RUNNING(focus) --[focus duration elapses]--> RUNNING(short_break or long_break, auto-started)
RUNNING(break) --[break duration elapses]--> RUNNING(focus, next cycle)
                                (any phase) --stop()--> STOPPING  (same as stopwatch mode)
```
Focus-phase elapsed time accumulates into `active_duration_seconds`; break-phase elapsed time accumulates into `paused_duration_seconds` — i.e., Pomodoro breaks are implemented as automatic pauses, reusing 100% of the pause/resume machinery already defined above rather than introducing new accounting.

## 12.4 Constants

| Name | Default | Configurable |
|---|---|---|
| Recovery gap threshold | 30 minutes | No (v1 fixed; candidate future setting) |
| Long-session warning | 8 hours | No |
| Streak minimum | 2 minutes | Yes (Settings) |
| Pomodoro focus / short break / long break / cycles | 25m / 5m / 15m / 4 | Yes (Settings) |

---

# Part 13 — User Flows

## 13.1 First launch → first session

1. Onboarding (3 steps: what this app is / local-only + manual backup responsibility / create your first skill) → 2. Create Skill form (name required, everything else optional/defaulted) → 3. Land on Skills/Home with the new skill's panel visible → 4. Tap Play → confirm → 5. Timer screen, flip clock at `000 : 00 : 00`, Start pressed → 6. running; Stop pressed → 7. Session Completion panel, optional note typed, Save → 8. back on Skills/Home, panel now shows updated accumulated time and progress.

## 13.2 Resume after being closed for weeks (ordinary case, no active timer)

1. Launch → 2. `timer_state` is idle → 3. Skills/Home shown directly (no onboarding, since a skill already exists) → 4. all totals reflect exactly what was last saved, since nothing async or server-dependent needed to happen.

## 13.3 Crash mid-session, long gap

1. User starts a session, device loses power → 2. Relaunch hours later → 3. Recovery sub-flow (12.2) detects gap > 30 min → 4. Recovered Session dialog shown → 5. user picks Trim to last heartbeat → 6. session auto-stops at that point → 7. Session Completion panel opens as normal, ready for a note.

## 13.4 Cross-device backup round-trip (also the Part 19 acceptance test)

1. On Android: create a skill, log several sessions with notes → 2. Settings → Export → full backup → `.skilltracker` saved via OS share sheet to, e.g., Google Drive → 3. On Windows: fresh install → Settings → Import → pick the file (drag-and-drop supported per 5) → 4. Preview screen shows exact counts/totals → 5. choose Merge (or Replace, since Windows install is fresh and empty, either yields the same result here) → 6. Windows now shows identical skills, sessions, notes, and stats → 7. add one more session on Windows → 8. export again, import back into the Android install → 9. Android now has both the original data and the Windows-added session, with no duplicates.

## 13.5 Pomodoro session

1. Skills/Home → Play on a skill → mode selector defaults to last-used mode, switch to Pomodoro → 2. confirm → 3. Timer screen shows a 25:00 countdown (flip clock in countdown orientation) → 4. focus interval completes, notification fires, 5:00 break countdown auto-starts → 5. user works through several cycles → 6. presses Stop mid-cycle → 7. Session Completion panel shows total *focus* time only (breaks excluded) → 8. Save.

---

# Part 14 — Navigation Model

**Resolved structure** (see ADR-001 in Part 25 for why this differs slightly from the raw source-document proposal): four primary destinations, not five. The originally proposed separate "Timer" tab is folded into **Skills**, since ABR's own description of the home page *is* the timer's entry point (skill panels with an inline Play button that transitions into the full-screen clock) — a standalone "Timer" destination would either duplicate Skills or sit empty until a skill is selected from it, which conflicts with "same page is enough" (7.4).

```
┌─────────────┬──────────────┬─────────────┬──────────┐
│   Skills    │ Learning Log │ Statistics  │ Settings │
│   (Home)    │              │             │          │
└─────────────┴──────────────┴─────────────┴──────────┘
```

- **Mobile**: bottom navigation bar, these 4 items, always visible except while the full-screen Timer view (entered *from* Skills) or the Session Completion panel is on top — those are pushed as their own routes above the shell, not additional tab destinations.
- **Desktop (Windows/Linux)**: left navigation rail, same 4 destinations, icon + label.
- App launch routing (6.3): if `timer_state` is running/paused, launch directly into the Timer/recovery screen; else if at least one skill exists, land on Skills/Home; else show onboarding.
- The Timer screen and Session Completion panel are modal-ish full-screen routes pushed *from* Skills, not part of the persistent tab structure — this matches "the clock should be the major look" by letting it take over the whole screen without nav chrome competing for space.

---

# Part 15 — Error and Empty States

## 15.1 Empty states

| Context | Copy |
|---|---|
| No skills yet | "Create your first skill to begin tracking." (with New Skill action) |
| Learning Log, no sessions at all | "No session notes yet. Complete a focus session and add a note about what you learned. Your notes will appear here as your learning journal." |
| Learning Log, sessions exist but none have notes | "You have logged sessions, but no notes yet. You can add notes to past sessions to build your learning history." |
| Learning Log search, no matches | "No notes found for “{query}”. Try a different keyword or clear filters." |
| Statistics, skill has zero sessions | "No sessions yet for {Skill}. Start a timer to see your progress here." |
| Archived skills list, empty | "No archived skills." |

## 15.2 Error states (user-facing message catalog)

| Situation | Message | Recovery action offered |
|---|---|---|
| Import: checksum mismatch | "This backup file appears to be corrupted or incomplete and can't be safely imported." | Choose a different file |
| Import: newer format version | "This backup was created by a newer version of Ayutam. Please update the app before importing." | Dismiss |
| Import: transaction failure mid-import | "Something went wrong during import. No changes were made — your existing data is untouched." | Retry, or Export diagnostic log |
| Database integrity check fails on launch | "Ayutam detected a problem with your local data." | Attempt repair / Restore from latest snapshot / Export diagnostic log |
| Overlapping session on save | "This session overlaps with another session on {date}. Save anyway?" | Save anyway / Go back and edit |
| Session shorter than 1 minute stopped | "This session was very short (Xs). Save it anyway?" | Save / Discard |
| Permanent skill deletion | "This will permanently delete {Skill} and its N sessions. Type the skill name to confirm." | Type-to-confirm field |
| Replace-on-import | "Replacing will delete your current N skills and M sessions and replace them with the backup's data. A safety snapshot will be kept, but this cannot be undone from within the app." | Confirm / Cancel |
| Generic uncaught error | "Something unexpected happened." (no stack trace shown) | Export diagnostic log |

## 15.3 Confirmation-vs-undo policy

Undo (5-second snackbar): session delete, tag removal, discarding a note draft.
Explicit confirmation dialog: permanent skill delete (type-to-confirm), Replace import, Delete All Local Data, Discard Session after Stop (since it destroys an already-recorded session).

---

# Part 16 — Accessibility Requirements

- Full screen-reader labeling on every interactive element, including the icon-only Start/Pause/Stop controls (visually icon-only per 13.3, but each carries a semantic label — "Start session", "Pause session", "Stop session" — so the icon-only *visual* choice never becomes an accessibility gap).
- Keyboard navigation across the entire app on desktop, including full keyboard operability of the Timer screen even though it also supports the dedicated shortcuts (Part 2.2).
- Color contrast meets WCAG AA in both Light and Dark themes.
- Text scaling: UI respects the OS/system font-scale setting up to at least 130% without clipping or overlap; duration/flip-clock digits may cap their max scale slightly earlier to preserve the clock layout, but never become unreadable.
- Reduced Motion setting disables the flip-clock animation (crossfade instead) and any chart transition animation.
- The calendar heatmap never relies on color alone: focusing or selecting any cell exposes its exact total duration (and, where relevant, session count) via both a visible label and a screen-reader announcement (13.2).
- Minimum touch target size of 48×48dp on all interactive controls, including chip filters and the flip-clock's own controls.
- All dates and durations are rendered in clear human-readable form everywhere in the UI ("2h 15m", "Today", "Yesterday", full date in detail views) — never raw seconds or ISO timestamps in user-facing text.

---

# Part 17 — Security & Privacy Requirements

- **No accounts, no authentication server, no user identifiers tied to a real identity anywhere** — the only "identifier" in the system is a randomly generated, non-PII local `device_id` used solely for merge-conflict bookkeeping (11.3), never transmitted anywhere since there is nowhere for it to go.
- **No analytics or telemetry of any kind.**
- **No external crash-reporting service.** Diagnostic logs are written locally only and are exportable manually by the user (e.g., to attach to a GitHub issue voluntarily) — the app itself never sends them anywhere.
- **No network access required for core functionality.** The Android manifest should omit the `INTERNET` permission entirely for the v1 feature set; if the Phase-2 GitHub-Releases update check is later enabled, it becomes the one narrowly-scoped exception (a read-only public API call, opt-in, clearly disclosed in Settings) — see ADR-007.
- **Local data protection**: optional app-open lock via the OS-native biometric/PIN prompt (`local_auth`) — off by default, no custom password/credential storage inside the app itself (17.3/10.18, see ADR-006).
- **Backup file protection**: unencrypted by default (it's a file the user already controls the custody of); optional passphrase encryption is a Phase-2 addition once the core is stable (10.17).
- **"Delete All Local Data"** exists in Settings with a strong recommendation to export first, and requires confirmation (15.3).

---

# Part 18 — Testing Strategy

| Level | Scope | Key examples |
|---|---|---|
| Unit tests | Domain entities, use-cases, merge-conflict resolution logic, timer elapsed-time calculation, streak/aggregation math | LWW conflict resolution table (11.3) covered exhaustively per row; elapsed-time formula correctness across pause/resume sequences. |
| Database tests | Drift schema, queries, indices | Query correctness for Learning Log filters (AND-combination of all 6 filter types); midnight-crossing split aggregation; performance sanity at 100,000-session volume. |
| Migration tests | Every schema version bump | Old-schema fixture data survives migration with identical row counts and values. |
| Widget tests | Individual screens/components in isolation | Flip clock digit-change rendering; Session Completion panel validation (title/note/tags optional, save always enabled). |
| Integration tests | Multi-screen flows within one app instance | Full flow 13.1 (onboarding → first session); Pomodoro auto-phase-transition sequence. |
| Import/export round-trip tests | Backup fidelity | Export → wipe local DB → import → assert deep equality of all skills/sessions/tags/settings. |
| Cross-platform compatibility tests | Android, Windows, Linux | Same integration test suite run on all three CI targets. |
| Long-running timer tests | Timer correctness over real or simulated elapsed time | Simulate a 9-hour run, assert the 8-hour warning fires and elapsed time stays accurate throughout. |
| Crash-recovery tests | 12.2 sub-flow | Kill process mid-session at various simulated gap lengths; assert correct branch (silent resume vs. Recovered Session dialog) and correct resulting duration. |
| Accessibility tests | Screen-reader labels, contrast, tap targets | Automated a11y audit in CI where tooling allows, plus a manual checklist pre-release. |

No extensive visual golden-image tests in v1 (designs aren't yet pixel-frozen) — revisit once the UI stabilizes.

---

# Part 19 — End-to-End Acceptance Criteria

**Principal acceptance test** (must pass before v1 is considered done):

1. Create a skill on Android.
2. Record several sessions — a mix of timed (stopwatch), Pomodoro, and manual entries.
3. Add Markdown notes to some, leave others blank.
4. Export a full backup.
5. Transfer the `.skilltracker` file to a Windows machine (any ordinary file-transfer method — the app doesn't care how the file physically moved).
6. Import it on a fresh Windows install.
7. Verify: exact totals, notes (including Markdown formatting), timestamps, tags, statistics, and settings all match the Android source, with **zero** discrepancy.
8. Add one more session on Windows.
9. Export from Windows and import back into the original Android install (Merge).
10. Confirm no duplicate records and no lost data — Android now shows everything from both devices exactly once.

**Supporting acceptance thresholds**:
- Timer accuracy: stored duration deviates by no more than **10 seconds** from wall-clock reality under normal operation (excludes deliberate system-clock manipulation, per 18.3).
- Import is only considered successful when *all* of the following hold: record counts match the manifest, total duration matches, the checksum passes, referential integrity passes (every `session.skill_id` and `session_tags` row resolves to a real record), and all statistics recalculate correctly from the imported data (18.4).

---

# Part 20 — Phased Implementation Plan

| Phase | Scope | Exit criteria |
|---|---|---|
| **0. Project setup** | Repo scaffold (Part 7), CI (Android/Windows/Linux build matrix), lint/format config, `AGENTS.md`, MIT license file, empty Drift database with `schemaVersion = 1`. | CI green on an empty app that launches to onboarding on all 3 platforms. |
| **1. Skills + Timer core** | Skill CRUD, TimerService + state machine (Part 12) without Pomodoro or crash-recovery UI yet, basic Session Completion (note optional), Skills/Home screen. | Flow 13.1 works end-to-end on Android + Windows + Linux. |
| **2. Flip clock + visual identity** | Custom `FlipDigit`/`FlipClock` widgets, Material 3 theme (light/dark/follow-system), per-skill accent colors. | Timer screen visually matches Part 4.2; Reduced Motion toggle works. |
| **3. Crash recovery + Pomodoro** | 12.2 recovery sub-flow, 12.3 Pomodoro overlay, Android persistent notification, desktop tray + shortcuts. | Flows 13.3 and 13.5 pass their integration tests. |
| **4. Learning Log** | Grouped timeline (mobile) + two-pane (desktop), search, all 6 filter types, sort, calendar-jump, detail view with Markdown rendering. | Feature F-07 acceptance criteria pass at a 10,000-session synthetic dataset. |
| **5. Statistics** | Summary card, Cumulative chart (fl_chart), Calendar heatmap (custom), Summary table, all interactions (Part 2.5). | Features F-08–F-10 pass. |
| **6. Backup: export** | `.skilltracker` archive writer, CSV writer, per-skill Markdown writer, safety-snapshot mechanism. | F-11, F-13, F-14, F-15 pass. |
| **7. Backup: import + merge** | Validation/preview, Replace path, Merge engine (Part 11), transactional restore. | F-12 passes; Part 19's principal acceptance test passes in full. |
| **8. Settings + polish** | Full Settings screen (2.9), onboarding (F-23), accessibility pass (Part 16), error/empty-state catalog wired in everywhere (Part 15). | Accessibility checklist signed off; every Part 15 message reachable and correctly triggered. |
| **9. Release prep** | Windows/Linux installers, Android signed APK, GitHub Releases pipeline, README, store-readiness scaffolding (icons, metadata placeholders) without actually submitting. | A GitHub Release produces installable artifacts for all 3 platforms. |
| **Phase 2 (post-v1)** | Update check (GitHub Releases API), optional backup encryption, Play Store / Microsoft Store submission. | Tracked separately; not blocking v1. |

Each phase should land as a mergeable, working increment — the app should never be in a broken state on `main` between phases, consistent with "easy to maintain" as the top priority.

---

# Part 21 — V1 vs. Future-Feature Boundaries

**Excluded from v1, and not architected around either** (deliberately out of scope, per ABR's explicit list):
Accounts/authentication, backend server, automatic cloud synchronization, social features, leaderboards, shared skills, AI-generated learning summaries, attachments/images in notes, nested sub-skills/projects, multiple simultaneous timers, calendar (Google/Outlook) integrations, complex recurring goals, public profiles, browser extension, wearable companion apps.

**In v1, despite being on the "commonly excluded" list elsewhere** — Pomodoro mode is explicitly required (Part 2.8), the one addition ABR made to the standard exclusion list.

**Deferred to Phase 2, but the architecture should not block them later** (see each feature's row in Part 3 and the relevant ADR):
- Update checks via GitHub Releases' public API (F-25) — network access stays fully optional and off by default in v1.
- Optional backup passphrase encryption (F-26).
- Play Store / Microsoft Store distribution (F-27) — Part 7's project structure and Part 20's release phase are set up so this is packaging/signing work later, not a rewrite.
- macOS and iOS support — not currently planned at all (ABR explicitly doesn't need iOS); Flutter's cross-platform nature means it isn't precluded if priorities change, but nothing in this spec optimizes for it.
- Flutter Web/PWA build — considered and explicitly declined in favor of native Flutter (see the earlier architecture discussion); not part of this plan.
- Multiple local profiles, full audit-log history, streak freezes/rest days, field-level merge conflict UI — all considered and deliberately simplified away for v1 (11.3, 9.7, 11.1).

---

# Part 22 — Instructions for Coding Agents

These apply to any agent (Claude Code, Codex, or otherwise) implementing this spec:

1. **Read this document in full before writing code.** It supersedes ad-hoc assumptions; where something genuinely isn't covered, prefer the simplest option consistent with "no unnecessary features, no feature creep."
2. **Follow the phased plan (Part 20) in order.** Don't build Statistics before Skills/Timer core exists — each phase depends on the previous one's data model being real.
3. **Domain and application layers must never import Flutter or Drift directly** (Part 6.1) — if you find yourself importing `package:flutter/material.dart` inside `lib/domain/` or `lib/application/`, stop and move the logic.
4. **Every schema change requires a migration + migration test in the same commit** (16.3, Part 9) — never hand-edit the live schema without a versioned `MigrationStrategy` step.
5. **Elapsed time is always `now − started_at_utc − paused_duration`, recomputed, never accumulated by a running in-memory tick loop.** This single rule is what makes crash recovery, backgrounding, and desktop sleep all work correctly for free — don't special-case them separately.
6. **When a requirement is ambiguous or missing and this document doesn't resolve it, default to the simplest solution that satisfies the stated non-goals** (no backend, no accounts, minimal dependencies) **and flag the assumption in a code comment referencing this document's Part 25**, rather than silently picking something more complex.
7. **Prefer the packages listed in Part 24.** If a materially better-maintained alternative exists at implementation time, it's fine to substitute — but document the substitution and rationale in `AGENTS.md`'s changelog section, per ABR's explicit "the implementation agent... also makes some decisions" allowance (15.1).
8. **Every feature in Part 3 needs its acceptance criterion demonstrably passing (a test, not just "it compiles") before being considered done.**
9. **Never add a network call, analytics hook, or external service dependency that isn't explicitly listed in this document** (Part 17) — this is a hard constraint, not a style preference.
10. **Keep the codebase small.** If a feature can be built by reusing an existing mechanism (the way Pomodoro breaks reuse the pause mechanism, Part 12.3) rather than adding a new one, do that.

---

# Part 23 — Suggested `AGENTS.md`

```markdown
# AGENTS.md — Ayutam

This file orients any coding agent (Claude Code, Codex, etc.) working in this repository.

## What this project is
A local-first, offline, cross-platform (Android/Windows/Linux) Flutter app for tracking
deliberate-practice time against long-horizon skill goals (default 10,000 hours). No backend,
no accounts, ever. Full specification: `/docs/ayutam-spec.md` — read it before making
non-trivial changes.

## Non-negotiable constraints
- No network calls except the explicitly-approved, opt-in, Phase-2 GitHub Releases update check.
- No analytics, telemetry, or crash reporting to any external service.
- No accounts/authentication of any kind.
- `lib/domain/` and `lib/application/` must not import `flutter` or `drift`.

## Architecture
See spec Part 6-8. Layers: UI → Riverpod state → application use-cases → domain → repositories → Drift.

## Commands
- `flutter pub get`
- `flutter test` — unit + widget + database + migration tests
- `flutter test integration_test` — full-flow tests including the backup round-trip (spec Part 19)
- `dart run build_runner build --delete-conflicting-outputs` — after any Drift table change

## Before opening a PR
1. All tests in the relevant Part-18 category pass.
2. Any schema change includes a migration + migration test.
3. Any new dependency is documented in spec Part 24 with rationale, or noted as a substitution
   per Instruction 7 in spec Part 22.
4. No new network/analytics call was added.

## Where things live
See spec Part 7 for the full folder structure and rationale.

## Decisions already made — don't re-litigate without updating the spec
See spec Part 25 for the full ADR list (merge conflict strategy, navigation model, streak
threshold, app-lock default, chart/database/state-management library choices, etc.).
```

---

# Part 24 — Recommended Flutter Packages & Dependency Rationale

| Package | Purpose | Why this one |
|---|---|---|
| `drift` + `drift_dev` + `sqlite3_flutter_libs` | Local database (Part 9) | Typed queries, built-in migration framework, reactive `.watch()` streams (feeds Riverpod directly, Part 8), first-class desktop (Windows/Linux) support — directly answers 15.3's resolved choice. |
| `flutter_riverpod` (no codegen variant) | State management (Part 8) | Explicit v1 preference; the non-codegen flavor avoids stacking a second build_runner pipeline on top of Drift's — one codegen tool is enough for a small maintainable app. |
| `fl_chart` | Cumulative progress line chart (2.5) | Pure Dart, no WebView dependency, actively maintained, MIT-licensed, sufficient interactivity (zoom/pan/tooltips) for the required chart features. The calendar heatmap is **not** built with a charting library — it's a small hand-rolled `GridView`/`CustomPainter` widget, since no chart library models a GitHub-style contribution grid any better than a bespoke ~150-line widget would, and a bespoke widget keeps full control over the fixed-bucket accessibility requirements (16, 13.2). |
| *(none — custom)* `widgets/flip_clock/` | The flip-clock stopwatch (4.2) | No actively-maintained package reproduces the specific split-flap mechanical flip closely enough (per the reference research in 4.2); this is a self-contained, dependency-free `AnimatedBuilder`/`Matrix4.rotateX` widget, which also keeps the app's single most distinctive UI element free of third-party churn risk. |
| `archive` | Building/reading the `.skilltracker` ZIP (Part 10) | Standard, pure-Dart zip read/write, no native binaries needed — matters for keeping Linux/Windows builds simple. |
| `crypto` | SHA-256 checksums (Part 10, 11) | Small, standard, Dart-team-adjacent. |
| `file_selector` (or `file_picker`) | Import file choice, export destination, drag-and-drop on desktop | Cross-platform native file dialogs; `file_selector` is the Flutter-team-maintained option and is preferred where its feature set (incl. desktop drag-and-drop hookup) suffices. |
| `share_plus` | Android/desktop share sheet for exported files | Standard, widely used, keeps export truly "hand off to whatever the OS offers" per the no-direct-cloud-integration decision (2.6). |
| `path_provider` | Locating app-local storage for the DB, snapshots, drafts | Standard. |
| `flutter_local_notifications` | Android persistent timer notification (2.2), Pomodoro phase-change notifications (2.8) | The standard, actively maintained choice for local (non-push) notifications. |
| `wakelock_plus` | Keep-screen-awake setting (2.2, 2.9) | Standard, minimal. |
| `tray_manager` + `window_manager` | Windows/Linux system tray + window control (2.2) | Together cover tray icon/menu and window minimize/restore behavior needed for the tray-timer feature. |
| `local_auth` | Optional app-lock biometric/PIN gate (2.9, 17) | OS-native prompt only — no custom credential storage, matching the security posture in Part 17. |
| `intl` + `flutter_timezone` | Locale-aware date/number formatting, week-start, and the Settings timezone selector (5.1-5.4) | `intl` is the standard formatting library; `flutter_timezone` reads the device's IANA timezone as a sensible default for the Settings picker. |
| `csv` | CSV session export (10.2) | Small, standard, avoids hand-rolling escaping logic. |
| `flutter_markdown` | Rendering notes as Markdown (2.3, 4.3.4) | Standard, actively maintained, matches the plain-CommonMark feature set notes need (no images/attachments in v1). |
| `uuid` | Entity ID generation (Part 9) | Standard v4 UUID generation for all primary keys, which is what makes the merge engine's ID-based matching (Part 11) possible in the first place. |
| `go_router` | **Not used** — see ADR-008 | Standard `Navigator`/`Router` APIs are sufficient for this app's flat, 4-destination navigation with a couple of pushed full-screen routes (Part 14); `go_router`'s main advantages (URL-based deep linking, declarative nested/shell routes for complex tab hierarchies) don't pay for their added dependency weight here, since there's no web build and no deep-linking requirement in v1. |

**Package policy** (per 15.6, applied above): prefer mature/actively-maintained packages, minimize total dependency count, avoid restrictive licenses (everything above is MIT/BSD/Apache-2.0), and document every dependency's purpose here — this table *is* that documentation, and should be kept in sync as `pubspec.yaml` changes.

---

# Part 25 — Open Questions & Architectural Decision Records

The two source interviews (Claude web, ChatGPT web) sometimes answered the same underlying question differently, or left a question with no explicit recommendation to default to. This section is the complete, traceable log of every place this document made a judgment call — review these first if anything above surprises you.

## ADR-001 — Collapse "Timer" and "Skills" into one navigation destination
**Conflict**: 7.1 proposed a 5-item nav (Timer, Learning Log, Statistics, Skills, Settings) which ABR accepted; but 6.1 and 7.4 describe the home page *as* the timer's entry point, and 7.4 explicitly says skill management and the timer experience belong on the same page.
**Decision**: 4 destinations — Skills (Home, contains the timer entry point) / Learning Log / Statistics / Settings. See Part 14.
**Override**: if you actually want a separate always-visible Timer tab distinct from Skills, say so and Part 14 changes to 5 destinations.

## ADR-002 — Import supports both Merge and Replace, not one or the other
**Conflict**: the Claude-web thread's tentative answer to the merge-vs-overwrite question was "overwrite-only is fine" if merge seemed too complex; the ChatGPT-web thread's more detailed follow-up explicitly accepted the recommended Merge-with-preview design (and "keep newest" for the two-device conflict case).
**Decision**: both exist as user-chosen options at import time (Part 2.6, 11.2–11.3) — Replace is the simple, cheap-to-implement fallback that satisfies the first answer; Merge with last-write-wins conflict resolution is the more capable option that satisfies the second, more deliberate answer. Neither answer is discarded.

## ADR-003 — Streak minimum duration: 2 minutes
**Conflict**: the Claude-web thread gave an explicit number ("minimum should be 2 minutes"); the ChatGPT-web thread's corresponding question was answered "use recommended default," whose stated default was "any non-zero session."
**Decision**: 2 minutes, per the more specific, deliberately-chosen answer — a generic "use the default" reply to a *different* agent's phrasing of the same question shouldn't override a concrete number given earlier. Made user-adjustable in Settings either way (2.9), so this is low-stakes to change later.

## ADR-004 — Skill entity includes a system-managed `status` field
**Gap**: 1.3's proposed field list (which ABR trimmed) didn't include a status/lifecycle field, but 1.5 (accepted via "recommended default") requires archive/restore functionality, which is impossible to implement without one.
**Decision**: `status` (`active`/`archived`) exists in the schema (Part 9) as a system-managed field, not a user-fillable one — it's set by the Archive/Restore actions, never typed in by the user, so it doesn't contradict the trimmed field list in spirit.

## ADR-005 — Heatmap intensity ranges: fixed by default, overridable in Settings
**Conflict**: 9.14 ("use recommended default") explicitly wants fixed ranges for comparability; Part 14's settings list separately asks to include "heatmap intensity ranges" as a configurable setting.
**Decision**: fixed buckets are the default and drive normal comparability across time (9.14's intent preserved); an advanced Settings override lets a user redefine the minute thresholds if they explicitly want to, satisfying the literal inclusion in the settings list without breaking the default comparability guarantee.

## ADR-006 — Optional app lock, off by default
**Gap**: 10.18 lists PIN/biometric/Windows Hello/no-lock as options with no bolded recommendation in the source document, and was answered "use recommended default" against a default that was never actually stated.
**Decision**: OS-native biometric/PIN via `local_auth`, available but **off by default** — consistent with this being a low-sensitivity personal tracking app where friction-free open is more valuable day-to-day than a lock screen, while still offering the option since it's explicitly listed as a desired Setting.
**Override**: easy to flip the default to "on" if you'd prefer that.

## ADR-007 — Update checks are compatible with "no backend," using GitHub's public API
**Clarification, not a conflict**: 17.3/17.4 conditioned update checks on "not requiring a backend service" — GitHub Releases exposes a free, public, read-only REST endpoint for a repository's latest release, which is not a backend ABR would run or maintain (no server, no cost, no auth). This satisfies the stated condition, so the feature is included as an opt-in Phase 2 item (F-25) rather than dropped.

## ADR-008 — `go_router` not used; standard Navigator/Router chosen
**Direct answer to a question ABR asked** (15.4: "what advantage does go_router provide?"): `go_router`'s main value is declarative, URL-addressable, deep-linkable routing and easier nested/shell-route management for complex tab hierarchies — genuinely useful for apps with a web build or many nested flows. Ayutam has neither (no web build, a flat 4-destination nav plus a couple of pushed full-screen routes, Part 14) — so standard `Navigator`/`Router` APIs are simpler and sufficient, per ABR's own stated preference for standard APIs when they suffice.

## ADR-009 — Pomodoro mode design (net-new, not detailed in either source interview)
**Gap**: Pomodoro was added to the v1-required list (Section 19 of the source document) as a one-line answer, with no further specification anywhere in either interview.
**Decision**: designed from scratch in Part 2.8 and Part 12.3, deliberately reusing the existing pause/resume and session-note mechanisms rather than introducing a parallel system, to honor "no unnecessary features/complexity." Configurable focus/break/cycle lengths default to the standard 25/5/15/4 convention.
**Open point**: this document doesn't specify what happens if the user manually pauses *during* a Pomodoro focus interval (on top of the automatic break-pause) — current design treats it identically to a stopwatch-mode pause (extends `paused_duration_seconds`, doesn't affect the phase timer's own countdown target). Confirm this matches your expectation, or say if manual pause should be disabled entirely during Pomodoro mode.

## ADR-010 — Heatmap day-tap shows a quick total, with a separate path to full detail
**Conflict**: 9.15 simplified the heatmap's day-tap detail down to just total time; 8.11 (accepted via recommended default) wants a quick preview plus an "open in Learning Log" action.
**Decision**: both — tapping a day shows a lightweight popover with just the total time (9.15's simplification honored as the *default* view), with a secondary action in that same popover to open the Learning Log filtered to that date for anyone who wants more (8.11's richer behavior preserved as an opt-in next step, not the default noise).

## ADR-011 — No Flutter Web/PWA build in v1
**Context, not really a conflict**: the ChatGPT-web interview's browser-support question (2.2) was answered by restating platform choices rather than directly confirming or denying browser support; this document treats it as settled by the earlier, more explicit conversation turn in this thread where PWA was directly evaluated and Flutter-native was chosen instead. Recorded here for traceability, not because the source answer was actually ambiguous about intent.

## Genuinely open items — not resolved by either source interview, flagged for your input rather than silently decided

- **Discard-Session affordance**: since Stop immediately persists a session record before the note panel opens (4.1), this document adds a "Discard Session" action to the Session Completion panel (4.3.3) so an accidental stop can be fully undone, including its persisted record. Neither source interview asked about this directly. Confirm you want it, or if a plain post-hoc delete (2.3) is sufficient and this extra button should be removed.
- **Crash-recovery gap threshold (30 minutes)**: Part 12.4's trigger for showing the Recovered Session dialog rather than silently resuming is a value this document chose, not one either interview specified numerically. Reasonable to leave as a fixed constant for v1, but flagging the exact number as arbitrary and easy to change.
- **Fixed skill color palette**: Part 4.1 specifies "8–10 colorblind-considerate hues, auto-assigned" but doesn't enumerate exact hex values — left as an implementation detail for whoever builds the theme, not a product decision needing your sign-off.

---

*End of specification.*
