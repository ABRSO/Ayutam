# ADR-008 — Standard Navigator initially

**Status:** Accepted  
**Date:** 2026-07-22

## Context

`go_router` helps deep links, URL routing, and complex nested shells. Ayutam has no web build and a flat 4-destination nav plus a few pushed routes.

## Decision

Use Flutter `Navigator` with typed `MaterialPageRoute` / route builders. No legacy `pushNamed`. Revisit via new ADR if deep links or nested complexity appear.

## Consequences

Simpler dependency graph. Deep linking deferred.
