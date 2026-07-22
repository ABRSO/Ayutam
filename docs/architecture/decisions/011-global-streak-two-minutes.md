# ADR-011 — Global streak with two-minute threshold

**Status:** Accepted  
**Date:** 2026-07-22

## Context

Claude Q&A specified 2 minutes; another questionnaire’s “recommended default” was any non-zero. Specific answer wins. Owner also wants streak across any skill.

## Decision

A calendar day (configured timezone) qualifies when combined completed **active** seconds across all skills ≥ **120** (default, Settings-adjustable). Consecutive calendar days; no freezes.

## Consequences

Very short sessions still appear in history/totals but may not qualify a day unless combined daily time reaches the threshold. Freeze “today grace” behavior in tests.
