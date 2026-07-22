# ADR-007 — Riverpod 3 and Notifier API

**Status:** Accepted  
**Date:** 2026-07-22

## Context

Source specs assumed Riverpod 2 idioms (`StateNotifierProvider`). Riverpod 3.x is stable (since 2025-09); legacy providers moved to `legacy.dart`.

## Decision

Use **flutter_riverpod 3.x** with `Notifier` / `AsyncNotifier` / `StreamNotifier` (manual or codegen). Do not write new legacy StateNotifier code. SQLite remains source of truth.

## Consequences

Agents must follow Riverpod 3 migration rules (`==` update filtering, unified `Ref`, optional auto-retry). Re-pin exact version at implement time.
