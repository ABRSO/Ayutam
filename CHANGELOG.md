# Changelog

All notable changes to Ayutam are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Phase 2: custom flip clock (unbounded hours, reduced-motion path), skill accent palette auto-assign, timer icon controls with semantics/tooltips.
- Phase 1 vertical slice: skill create/edit/archive, stopwatch start/pause/resume/stop, completion save/discard, crash recovery + Recovery Review, startup routing.
- Phase 0 foundation: Flutter multi-platform shell (Android, Windows, Linux).
- Drift schema v1 with session-segments tables and device identity seeding.
- Riverpod 3 bootstrap, Material 3 light/dark/system theme, four-destination nav.
- Unit, database, and widget smoke tests.
- GitHub Actions validate workflow.

### Changed

- Agent/human phase workflow: README status must update each phase; Android/Windows/Linux platform smokes are mandatory before claiming a phase done; phase branches PR into `main` before starting the next phase.
- Timer screen shows skill-total flip clock plus monospace current-session duration; Home skill cards use accent strip and polished card theme.
- Expanded [`docs/dev/build-and-run.md`](docs/dev/build-and-run.md): step-by-step JDK 17 / Android SDK / AVD / env vars; WSL Linux; **native Linux** (Ubuntu/Debian) setup, build, and run; Xiaomi/`INSTALL_FAILED_USER_RESTRICTED` install notes; debug vs release APK size and performance guidance.
- Flip clock visuals: true two-stage mechanical flip (rotateX upper 0→90°, then lower 90°→0°), clipped full-face halves, individual digit cards, no permanent hinge overlay / slot-machine slide.
- Skill cards show progress percent and remaining time; progress may exceed 100% when past target (bar still fills at 100%).
- Archive uses a 5-second Undo snackbar (with restore) instead of a confirm dialog.
- Completion primary action label is **Save Session**.
- Skill card corner radius is 16 dp per UX tokens.

### Fixed

- Pre-session sheet now resolves an in-progress session with **Open active timer** / **Stop active and start this** / **Cancel** instead of a dead-end "another session is already in progress" message, so a running session can be reopened without restarting the app. It also shows accumulated/target time and an explicit Cancel action.
- Session heartbeat runs app-level while a session is running instead of only while the timer screen is visible, so leaving the timer no longer stalls it and startup recovery cannot mistake active practice for a gap.
- Leaving a running timer shows a reminder that the session is still running and can be reopened from the skill's Play button.
- Cold start with an active/paused session pushes the timer above Skills (instead of replacing home), so the back control works the same as after Play → Start.
- Archiving a skill is blocked while that skill has an active, paused, or completion-pending session.
- Skill editor rejects non-positive / non-numeric target hours instead of silently saving 10,000 h; description and creation date are editable.
- Starting a stopwatch always rejects when any in-progress session exists, even if `timer_runtime` was left idle; startup re-binds idle runtime to stray sessions.
- Android edge-to-edge: transparent system bars (no white nav-bar strip / contrast scrim); predictive-back callback enabled in the manifest.
- Completion screen keeps Save / Resume / Discard on-screen without scrolling on normal viewports (padding no longer forces a 48px scroll); still scroll-safe on very short landscape heights.
- Skill editor sheet owns its text controllers for the sheet lifetime so Android IME/focus teardown cannot use a disposed controller (red-screen crash on New Skill).
