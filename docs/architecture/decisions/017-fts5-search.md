# ADR-017 — SQLite FTS5 for Learning Log search

**Status:** Accepted  
**Date:** 2026-07-22

## Context

Acceptance targets require search over notes/titles/tags at 10k–100k sessions within hundreds of milliseconds. LIKE scans will not scale.

## Decision

Maintain an FTS5 virtual table (`session_search`) for title, note, skill name, tags text. Rebuild available in diagnostics.

## Consequences

Extra write path to keep FTS in sync. Fallback graceful if FTS unavailable during repair.
