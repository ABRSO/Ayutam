# ADR-001 — Flutter native application

**Status:** Accepted  
**Date:** 2026-07-22

## Context

Portability via browser/PWA was discussed. Browser storage, file access, and timer throttling conflict with crash-safe local-first tracking.

## Decision

Build Ayutam as a Flutter native app for Android, Windows, and Linux. No PWA/web in v1.

## Consequences

Native packaging and signing required. Public-computer browser use unsupported. One shared domain layer across platforms.
