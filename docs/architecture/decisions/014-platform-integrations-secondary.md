# ADR-014 — Platform integrations are secondary

**Status:** Accepted  
**Date:** 2026-07-22

## Context

Android notifications and desktop tray improve UX but must not own timer truth.

## Decision

Notification, tray, and shortcuts invoke the same application commands after DB commit. Timer remains correct if plugins fail. Interfaces must allow replacing plugins with native code.

## Consequences

Core timer works without FGS/tray. Play policy and Linux tray quirks are packaging concerns, not domain blockers.
