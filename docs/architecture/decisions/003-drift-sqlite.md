# ADR-003 — Drift with native SQLite

**Status:** Accepted  
**Date:** 2026-07-22

## Context

Need relational queries, transactions, migrations, and desktop support for a 100k-session scale.

## Decision

Use Drift over native SQLite on Android, Windows, and Linux.

## Consequences

Generated schema and migration discipline mandatory. Reactive `.watch()` feeds UI. Live DB stays in app data directory.
