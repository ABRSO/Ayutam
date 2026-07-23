# Changelog

All notable changes to Ayutam are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Phase 1 vertical slice: skill create/edit/archive, stopwatch start/pause/resume/stop, completion save/discard, crash recovery + Recovery Review, startup routing.
- Phase 0 foundation: Flutter multi-platform shell (Android, Windows, Linux).
- Drift schema v1 with session-segments tables and device identity seeding.
- Riverpod 3 bootstrap, Material 3 light/dark/system theme, four-destination nav.
- Unit, database, and widget smoke tests.
- GitHub Actions validate workflow.

### Changed

- Agent/human phase workflow: README status must update each phase; Android/Windows/Linux platform smokes are mandatory before claiming a phase done; phase branches PR into `main` before starting the next phase.
