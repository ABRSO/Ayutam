# ADR-005 — Raw SQLite is an advanced snapshot

**Status:** Accepted  
**Date:** 2026-07-22

## Context

Exact byte-level DB copies are useful for diagnostics but poor long-term interchange.

## Decision

Offer consistent SQLite snapshots (`VACUUM INTO` / Online Backup API) as advanced export/replace. Never copy a live WAL database directly.

## Consequences

SQLite restore is primarily replace + migrate. Portable archive remains the merge path.
