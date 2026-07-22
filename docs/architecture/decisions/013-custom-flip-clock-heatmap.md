# ADR-013 — Custom flip clock and heatmap

**Status:** Accepted  
**Date:** 2026-07-22

## Context

Product identity depends on split-flap clock and GitHub-like heatmap. Chart libraries do not model contribution grids well; flip packages are inflexible/unmaintained.

## Decision

Implement custom `FlipDigit`/`FlipClock` and custom heatmap widgets. Use `fl_chart` (behind adapter) only for cumulative line charts.

## Consequences

More UI tests; fewer brittle UI dependencies; full a11y control.
