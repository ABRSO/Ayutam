# ADR-015 — flutter_markdown_plus

**Status:** Accepted  
**Date:** 2026-07-22

## Context

Archived specs recommended `flutter_markdown`. Google discontinued that package (2025); `flutter_markdown_plus` is the designated maintained successor.

## Decision

Render and preview session notes with **`flutter_markdown_plus`**. No remote images; no arbitrary HTML execution; confirm external links.

## Consequences

Re-verify package version at implement time. Do not depend on discontinued `flutter_markdown`.
