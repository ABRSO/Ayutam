# ADR-018 — App lock and backup encryption phasing

**Status:** Accepted  
**Date:** 2026-07-22

## Context

Owner wants optional lock and optional encryption listed in settings, but core backup reliability must land first. Biometrics vary by platform.

## Decision

- **Backup encryption:** Reserve encryption fields in `formatVersion` 1 manifest from day one. Implement AES-256-GCM + Argon2id **after** unencrypted backup E2E is proven (Phase 8 / P2). Default remains unencrypted with clear UI warning about private notes.  
- **App lock:** Optional, **off by default**, implement in Phase 8. Android: OS-native via `local_auth` where available. Desktop: local PIN with salted hash / secure storage — not a substitute for full-disk encryption. Never export PIN material. Biometrics/Windows Hello as enhancements behind `AppLockService`.

## Consequences

Format need not break for encryption. v1 can ship without encryption/lock if Phase 8 slips, without blocking backup/timer.
