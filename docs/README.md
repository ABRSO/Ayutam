# Ayutam documentation

This folder is the **single source of truth** for building and maintaining Ayutam. Coding agents and humans must follow these documents — not the archived brainstorming specs in [`archive/`](archive/).

## How to use this documentation

1. Read [`../AGENTS.md`](../AGENTS.md) first (invariants, prohibited behavior, commands).
2. Read the product and UX specs before changing user-visible behavior.
3. Read the architecture docs before changing persistence, timer logic, or backups.
4. Follow [`plan/execution-plan.md`](plan/execution-plan.md) phase order when implementing from scratch.
5. Update the matching doc (and an ADR when a decision changes) in the **same change** as the code.

## Document map

| Document | Purpose |
|---|---|
| [`product/product-spec.md`](product/product-spec.md) | Product requirements, functional behavior, feature inventory and acceptance criteria |
| [`product/ux-spec.md`](product/ux-spec.md) | Visual direction, design tokens, screens, flows, responsive layouts, empty/error states, accessibility |
| [`architecture/architecture.md`](architecture/architecture.md) | Layers, project structure, Riverpod 3 state design, platform services, error model |
| [`architecture/database.md`](architecture/database.md) | Drift/SQLite schema (session-segments model), FTS5, indexes, integrity, migrations |
| [`architecture/backup-format.md`](architecture/backup-format.md) | `.skilltracker` archive, validation, merge/replace, CSV/Markdown/SQLite exports |
| [`architecture/timer-state-machine.md`](architecture/timer-state-machine.md) | Timer states, transitions, recovery, Pomodoro overlay, clock model |
| [`architecture/decisions/`](architecture/decisions/) | Architectural Decision Records (ADRs) |
| [`testing/testing-strategy.md`](testing/testing-strategy.md) | Test pyramid, matrices, performance fixture, CI gates |
| [`testing/platform-smoke.md`](testing/platform-smoke.md) | Per-phase Android/Windows/Linux build + launch smoke procedure, troubleshooting, checklist |
| [`plan/execution-plan.md`](plan/execution-plan.md) | Phased agent-executable implementation plan (Phases 0–8) |
| [`archive/`](archive/) | Superseded brainstorming specs (historical only) |

## Maintenance rules

- **Behavior change** → update `product/product-spec.md` and/or `product/ux-spec.md`.
- **Schema change** → update `architecture/database.md`, add migration + migration test, bump schema version.
- **Backup format change** → update `architecture/backup-format.md`, bump `formatVersion`, keep backward import support.
- **Timer / recovery change** → update `architecture/timer-state-machine.md` and related tests.
- **Material decision** (package choice, model change, platform policy) → add or update an ADR under `architecture/decisions/`.
- **Phase completion** → check off exit criteria in `plan/execution-plan.md`.
- Do **not** edit archived files in `archive/` except to correct archive metadata.

## Status

| Area | Status |
|---|---|
| Product / UX / architecture docs | Authoritative baseline |
| Flutter application code | Phase 1 stopwatch vertical slice in progress |
| Package versions cited in docs | Re-verify on pub.dev when adding/upgrading deps |

## Related root files

- [`../AGENTS.md`](../AGENTS.md) — agent operating rules
- [`../README.md`](../README.md) — project overview and quick start
- [`../LICENSE`](../LICENSE) — MIT
