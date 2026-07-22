# ADR-012 — Last-write-wins merge

**Status:** Accepted  
**Date:** 2026-07-22

## Context

Owner accepted merge with “keep newest” for two-device conflict. Field-level merge and per-field conflict UIs are out of proportion for single-user offline use.

## Decision

UUID identity; newest `updated_at` wins whole record; identical content skipped; equal timestamp + different hash → conflict UI (default keep current). Overlapping times with different UUIDs are not duplicates. Offer both Merge and Replace.

## Consequences

Simple, testable merge. Deleted records may resurrect from older backups without permanent tombstones — document in preview; Prefer Replace for authoritative restore.
