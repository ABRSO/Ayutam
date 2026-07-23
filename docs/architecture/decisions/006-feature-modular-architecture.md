# ADR-006 — Feature-based modular architecture

**Status:** Accepted  
**Date:** 2026-07-22

## Context

Strict enterprise Clean Architecture is heavy for a single-developer local app; spaghetti UI-SQL is worse.

## Decision

Feature modules with domain / application / data / presentation boundaries. Domain and application must not import Flutter or Drift.

## Consequences

Clear test seams without one-class-per-trivial-use-case overhead.
