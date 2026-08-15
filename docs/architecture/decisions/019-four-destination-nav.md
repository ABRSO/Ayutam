# ADR-019 — Four-destination navigation

**Status:** Accepted  
**Date:** 2026-07-22

## Context

Early questionnaire listed five tabs including Timer and Skills. Owner described Home as the skills list with Play opening the clock (“same page is enough”).

## Decision

Primary destinations: **Skills**, **Learning Log**, **Statistics**, **Settings**. Timer and completion are nested immersive routes, not tabs.

## Consequences

Matches mental model; immersive clock without nav chrome competition.

Skills is the shell **back root**:

- **Android** system back / gesture: secondary destination → Skills; Skills → system exit behavior.
- **Windows / Linux Escape:** secondary destination → Skills; Skills → no action. Application exit is only via the window close control (not Escape).

Nested routes still pop first.
