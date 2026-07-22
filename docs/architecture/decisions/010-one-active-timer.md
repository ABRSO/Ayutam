# ADR-010 — One active timer

**Status:** Accepted  
**Date:** 2026-07-22

## Context

Owner confirmed one skill at a time.

## Decision

At most one session may be `active`, `paused`, or `completion_pending`. Starting another skill requires resolving the current session.

## Consequences

Simpler invariants and notifications. Enforce in transactions (+ partial unique index when feasible).
