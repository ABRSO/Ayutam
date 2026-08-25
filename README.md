# Ayutam

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/ABRSO/Ayutam)

**Ayutam (अयुतम्)** is a minimal, local-first skill tracker for logging deliberate practice toward long-horizon goals (default **10,000 hours**).

- **Platforms (v1):** Android, Windows, Linux — one Flutter codebase  
- **Data:** On-device SQLite; portable `.skilltracker` backups; **no** accounts, backend, or cloud sync  
- **License:** [MIT](LICENSE)

## Status

| Area | Status |
|---|---|
| Docs (product / UX / architecture) | Authoritative baseline |
| Application code | **Phase 5 complete** — portable `.skilltracker` backup/restore, merge/replace, safety snapshots |
| Distribution | GitHub Releases (ADR-021): split Android APKs, Windows installer + zip, Linux `.deb` + tarball |
| Next | Phase 6 — Platform integrations ([execution plan](docs/plan/execution-plan.md)) |
| Platforms verified | Android emulator, Windows, Linux (WSLg) — see [platform smoke](docs/testing/platform-smoke.md) |

## Documentation map

| Doc | Purpose |
|---|---|
| [AGENTS.md](AGENTS.md) | Rules for coding agents (read first) |
| [docs/README.md](docs/README.md) | Documentation index and maintenance rules |
| [docs/product/product-spec.md](docs/product/product-spec.md) | Product & functional requirements |
| [docs/product/ux-spec.md](docs/product/ux-spec.md) | UI/UX, layouts, accessibility |
| [docs/architecture/architecture.md](docs/architecture/architecture.md) | Technical architecture |
| [docs/architecture/database.md](docs/architecture/database.md) | Drift schema (session-segments) |
| [docs/architecture/backup-format.md](docs/architecture/backup-format.md) | Backup / import format |
| [docs/architecture/timer-state-machine.md](docs/architecture/timer-state-machine.md) | Timer & recovery |
| [docs/architecture/decisions/](docs/architecture/decisions/) | ADRs |
| [docs/testing/testing-strategy.md](docs/testing/testing-strategy.md) | Testing strategy |
| [docs/dev/build-and-run.md](docs/dev/build-and-run.md) | **Install prerequisites, build, run, and try the app** (Windows / Android / Linux) |
| [docs/testing/platform-smoke.md](docs/testing/platform-smoke.md) | Per-phase platform smoke checklist (agents + CI-style verify) |
| [docs/plan/execution-plan.md](docs/plan/execution-plan.md) | Phased implementation plan (0–8) |

Historical brainstorming specs (superseded): [`docs/archive/`](docs/archive/).

## Product in one paragraph

Create skills → start a stopwatch or Pomodoro from a skill card → immersive flip-clock timer → optional Markdown note/tags on stop → Learning Log and statistics (cumulative chart, heatmap, summary). Export a verified backup file and import (merge or replace) on another device. You own the file.

## For coding agents

1. Read [AGENTS.md](AGENTS.md).  
2. Follow [docs/plan/execution-plan.md](docs/plan/execution-plan.md) in order.  
3. Treat `docs/` as source of truth; do not implement from `docs/archive/`.  
4. After each phase: update this README status table, check off exit criteria, run [platform smokes](docs/testing/platform-smoke.md), open a PR into `main`.

## Development

Full **prerequisites, build, install, and run** instructions for Windows, Android (JDK/SDK/emulator), Linux via WSL, and **native Linux**:

→ **[`docs/dev/build-and-run.md`](docs/dev/build-and-run.md)**

Quick start (once Flutter + platform toolchains are installed):

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows   # or an Android emulator / device
flutter analyze
flutter test
```

On **Windows**, enable [Developer Mode](ms-settings:developers) before desktop builds. Prefer `tool\win_build.bat` for Windows release/debug binaries.

Per-phase automated-style platform smokes: [`docs/testing/platform-smoke.md`](docs/testing/platform-smoke.md).

## Contributing / security

See [`CONTRIBUTING.md`](CONTRIBUTING.md) (branching / PR merge strategy) and [`SECURITY.md`](SECURITY.md). Never add telemetry or backends.
