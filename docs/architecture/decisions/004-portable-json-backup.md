# ADR-004 — Portable JSON is the canonical interchange

**Status:** Accepted  
**Date:** 2026-07-22

## Context

Raw SQLite couples backups to live schema. JSON in a versioned archive decouples formats and enables merge.

## Decision

Canonical backup is `.skilltracker` (ZIP: manifest, JSON payload, checksums). Format version migrates independently of Drift schema.

## Consequences

Export/import mappers and format migrations are first-class. Prefer this over SQLite for multi-device merge.
