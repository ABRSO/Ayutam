# ADR-009 — Session-segments timer model

**Status:** Accepted  
**Date:** 2026-07-22  
**Supersedes informal “simple paused_duration only” sketch in archived ayutam-spec.md**

## Context

Two source specs disagreed: simple session row with `paused_duration` vs persisting every work/pause/break segment. Cross-midnight heatmap splits, Pomodoro accounting, and “trim to last known point” recovery are awkward without segments.

## Decision

Adopt the **session-segments** model: `session_segments` rows for work/pause/pomodoro_break; cached `sessions.active_seconds` / `paused_seconds`; `completion_pending` status; `timer_runtime` singleton. Elapsed time reconstructed from timestamps/segments.

## Consequences

Slightly more schema and transaction code; precise stats and recovery; single timer engine for stopwatch and Pomodoro.
