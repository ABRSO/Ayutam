# Ayutam

**Ayutam (अयुतम्)** is a minimal, local-first skill tracker for logging deliberate practice toward long-horizon goals (default **10,000 hours**).

- **Platforms (v1):** Android, Windows, Linux — one Flutter codebase  
- **Data:** On-device SQLite; portable `.skilltracker` backups; **no** accounts, backend, or cloud sync  
- **License:** [MIT](LICENSE)

## Status

Documentation and execution plan are ready. **Application code is not started yet** — begin at [Phase 0](docs/plan/execution-plan.md).

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
| [docs/plan/execution-plan.md](docs/plan/execution-plan.md) | Phased implementation plan (0–8) |

Historical brainstorming specs (superseded): [`docs/archive/`](docs/archive/).

## Product in one paragraph

Create skills → start a stopwatch or Pomodoro from a skill card → immersive flip-clock timer → optional Markdown note/tags on stop → Learning Log and statistics (cumulative chart, heatmap, summary). Export a verified backup file and import (merge or replace) on another device. You own the file.

## For coding agents

1. Read [AGENTS.md](AGENTS.md).  
2. Follow [docs/plan/execution-plan.md](docs/plan/execution-plan.md) in order.  
3. Treat `docs/` as source of truth; do not implement from `docs/archive/`.  
4. Keep documentation updated as features land.

## Development (after Phase 0)

```bash
flutter pub get
flutter run
flutter test
```

Exact package pins and CI land in Phase 0.

## Contributing / security

See `CONTRIBUTING.md` and `SECURITY.md` once created in Phase 0. Until then: open issues for proposals; never add telemetry or backends.
