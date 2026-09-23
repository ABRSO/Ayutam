# ADR-016 — Android 15 foreground service / timer notification

**Status:** Accepted  
**Date:** 2026-07-22

## Context

v1 requires a persistent Android notification with Pause/Stop. Android 14+ requires FGS types; Android 15 limits `dataSync` / `mediaProcessing` to ~6 hours per 24h while backgrounded. Long practice sessions can exceed that. Timer truth is timestamps, so the service is not required for accuracy.

## Decision

1. Implement notification behind `ForegroundTimerService` / notification interface.  
2. **Chosen FGS type (Phase 6):** `specialUse` with Play Console subtype text documenting a deliberate-practice timer with Pause/Stop controls. Session accuracy does not depend on the service (timestamps in SQLite). Not `dataSync`/`mediaProcessing` (6h limit) and not `health` (no sensor permissions).  
3. Handle `onTimeout` / exhaustion gracefully: stop the **service**, keep session running in DB, show user that notification controls may be limited until app is opened.  
4. Do not rely on boot-auto-start of FGS for correctness — recover on app open.  
5. Play Console declarations and evidence before store submission. Prototype uses `flutter_foreground_task` (MIT); retain native Kotlin escape hatch.

## Consequences

Long sessions remain accurate without continuous FGS. Store release needs explicit policy review. Sideloaded v1 can ship with best-effort notification.
