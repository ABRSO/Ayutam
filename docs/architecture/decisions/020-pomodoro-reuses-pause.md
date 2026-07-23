# ADR-020 — Pomodoro reuses pause accounting

**Status:** Accepted  
**Date:** 2026-07-22

## Context

Pomodoro was added to v1 with little detail. A parallel timer engine would duplicate crash recovery and totals.

## Decision

Pomodoro is an overlay on the session-segments state machine. Focus intervals are `work` segments; breaks are `pomodoro_break` segments counted like pauses (not active skill time). Defaults 25/5/15/4. Manual pause during focus freezes countdown and does not count as active.

## Consequences

One recovery path, one completion panel, shared tests. UI shows countdown as dominant clock in Pomodoro mode.
