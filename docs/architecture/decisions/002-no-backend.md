# ADR-002 — No backend or automatic synchronization

**Status:** Accepted (permanent unless product owner explicitly reverses)  
**Date:** 2026-07-22

## Context

Cloud sync implies accounts, servers, cost, and privacy trade-offs the owner rejected permanently.

## Decision

All core data is local. Cross-device transfer is manual export/import only. No analytics, ads, auth, or remote crash reporting.

## Consequences

User owns backup responsibility. Merge must be deterministic offline. No account-based recovery.
