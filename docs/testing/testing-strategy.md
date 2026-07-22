# Ayutam — Testing Strategy

**Status:** Authoritative  
**Related:** [Execution plan](../plan/execution-plan.md) · [Timer](../architecture/timer-state-machine.md) · [Backup](../architecture/backup-format.md)

---

## 1. Principles

- Prefer fast unit and database tests for domain invariants.  
- Every Drift schema bump ships with a migration test in the same change.  
- Timer and backup changes require failure-injection, idempotency, and recovery coverage.  
- Limited golden tests only for stable visuals (flip digit, skill card, heatmap legend).  
- No analytics — metrics below are acceptance/self-evaluation, not telemetry.

---

## 2. Test pyramid

### Unit

Duration formatting; progress/remaining; streak; cross-midnight allocation; rolling 4-week average; projection; state-machine transitions; LWW merge table; validation/value objects; backup codecs; timezone grouping.

### Database

Temp native/in-memory Drift DB: CRUD, one-active invariant, segment totals vs cache, FTS maintenance, pagination, transaction rollback, integrity checks, 100k-session fixture smoke.

### Migration

For each schema version: open old fixture → migrate → assert schema + data + totals → export/re-import when relevant.

### Widget

Skill card states; flip clock + reduced motion; timer control semantics; completion autosave indicators; Learning Log filters; import preview; empty/error states; breakpoints.

### Integration

Full timer lifecycle; restart simulation; portable backup round trip; replace and merge; conflict ties; active-session import; primary user journey (onboarding → first session).

### Accessibility

Semantics; focus traversal; large text; reduced motion; colour-independent state. Manual: TalkBack, Narrator+keyboard, Orca where feasible.

### Platform (manual / harness)

Android: lock screen, swipe-away, kill, restart, battery saver, orientation lock, notification permission denied.  
Windows: tray, sleep/wake, shortcuts, Unicode paths, multi-monitor.  
Linux: tray unavailable, Wayland/X11 smoke, package install/upgrade.

---

## 3. Clock testing

Injectable fake wall + monotonic clocks.

Scenarios: normal elapsed; pause/resume; closed 30 min (silent resume); restart invalidates monotonic; clock backward/forward; DST; timezone setting change; midnight cross; duplicate notification/UI commands; Pomodoro phase boundary while backgrounded; gap > 30 min → Recovery Review.

---

## 4. Backup test matrix

| Case | Expected |
|---|---|
| Empty DB export/import | Valid empty restore |
| 100k sessions | Completes within resource budget |
| Unicode / emoji notes | Exact round trip |
| Multiline Markdown / code | Exact round trip |
| Corrupted payload byte | Checksum reject, no mutation |
| Missing skill reference | Semantic reject |
| Newer format | Safe reject |
| Old format | Migration success |
| Wrong passphrase (when encryption exists) | No mutation |
| Cancel preview | No mutation |
| Failure mid-merge | Full rollback |
| SQLite snapshot with WAL | Consistent |
| Same backup twice | No duplicates |
| Divergent same UUID | Newest wins |
| Overlap different UUID | Both retained |
| Segments + Pomodoro | Active totals match focus only |

---

## 5. Performance fixture

Target: 100 skills, 100,000 sessions, ~300,000 segments, ~1,000 tags, 20 years of dates, ~2 KB notes.

Measure: DB open; Skills list; current-month Learning Log; FTS search; 12-month heatmap; all-time cumulative; export/import duration and memory; migration duration.

Document baseline hardware in repo before enforcing hard CI thresholds. Soft targets from product: Skills list < 500 ms after init (100 skills); Learning Log month query < 300 ms desktop / < 500 ms mid Android at scale; search < 300 ms at 10k sessions on mid Android.

---

## 6. Principal E2E acceptance

1. Android: onboarding, 3 skills, stopwatch (incl. pause + cross-midnight), Pomodoro (≥2 focus), Markdown notes/tags, manual session.  
2. Verify Skills, Log, chart, heatmap, table, streak.  
3. Export verified `.skilltracker`.  
4. Windows fresh install → Replace → exact parity.  
5. Edit/add session on Windows; export.  
6. Android divergent new UUID session; Merge Windows backup.  
7. No duplicates; LWW for shared UUIDs; both divergent rows present.  
8. Export → Linux restore → verify again.

**Import success only if:** checksums pass; counts match; referential integrity; total active matches summary; segment totals reconcile; DB integrity OK; stats recalculate; one-active invariant holds.

**Timer recovery:** force-close within 10 s tolerance; paused does not grow; restart discovers session; clock backward → no negative duration + review; double stop → one pending.

**Data-loss:** induced failure during export, validation, merge, swap, migration → original **or** fully committed new data only.

---

## 7. CI gates

**Every PR:**

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Plus: migration tests when schema touched; generated-code consistency; dependency licence report when tooling available; build smoke on available runners.

**Release candidate:** full integration suite; cross-platform fixture; packaged artifacts; a11y checklist; migrate from previous release; real backup/restore disaster drill.

---

## 8. Definition of done (feature)

Acceptance criteria pass; empty/error states; a11y semantics; persistence/recovery defined; appropriate tests; no new analyzer warnings; docs/ADRs updated; no feature creep outside product boundaries.
