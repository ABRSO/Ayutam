# Ayutam — Timer State Machine

**Status:** Authoritative  
**Related:** [Database](database.md) · [Product](../product/product-spec.md) · ADR-009, ADR-010, ADR-014

---

## 1. Principles

1. At most one session is `active`, `paused`, or `completion_pending`.  
2. Canonical time comes from **persisted segments + timestamps**, not UI ticks.  
3. Every transition: validate → mutate session + segments + `timer_runtime` in **one transaction** → commit → then update notification/tray/UI.  
4. Commands are **idempotent** (or no-op if already in target state).  
5. Platform integrations are secondary; their failure does not roll back committed domain state.

---

## 2. States

```text
IDLE
  │ start stopwatch / Pomodoro
  ▼
RUNNING (stopwatch) ──pause──► PAUSED
  │                               │
  │ stop                          │ resume / stop
  ▼                               ▼
COMPLETION_PENDING ◄──────────────┘
  │ save / discard / resume
  ▼
IDLE (or RUNNING if resume)

Any RUNNING/PAUSED
  │ crash, long gap, clock anomaly
  ▼
RECOVERY_REVIEW
  │ continue / trim / edit-end / discard
  ▼
RUNNING | PAUSED | COMPLETION_PENDING | IDLE
```

**Pomodoro overlay** on the same session (not a parallel engine):

```text
FOCUS_RUNNING ↔ FOCUS_PAUSED
      │ phase complete (persist first)
      ▼
BREAK_READY → SHORT_BREAK / LONG_BREAK running
      │ complete or skip
      ▼
FOCUS_READY → FOCUS_RUNNING
(any) stop → COMPLETION_PENDING
```

`timer_runtime.machine_state` stores the operational label (`idle`, `running`, `paused`, `focus`, `short_break`, `long_break`, `completion_pending`, `recovery_review`, plus ready variants as needed).

---

## 3. Transition table (summary)

| Current | Event | Persist | Next |
|---|---|---|---|
| Idle | Start stopwatch | Create session `active`, open `work` segment, runtime | Running |
| Idle | Start Pomodoro | Session + focus work segment + phase fields | Focus running |
| Running | Pause | Close work; open `pause`; update totals | Paused |
| Paused | Resume | Close pause; open work | Running |
| Running/Paused | Stop | Close segment; set end/totals; status `completion_pending`; clear active runtime toward pending | Completion pending |
| Completion pending | Save | Status `completed`; clear runtime | Idle |
| Completion pending | Discard (confirmed) | Delete pending session/segments/runtime | Idle |
| Completion pending | Resume | Clear end; reopen work; active | Running |
| App startup | Recover | Recalc; maybe set recovery_reason | Active or Recovery review |
| Active | Clock anomaly / long gap | Persist reason | Recovery review |
| Focus running | Phase complete | Close work; update totals; next phase | Break ready/running |
| Break running | Phase complete | Close break | Focus ready/running |

---

## 4. Time calculation

**Within one process/boot:** Prefer monotonic clock for elapsed display and transition durations; also persist wall-clock UTC anchors.

**After restart:** Monotonic anchor invalid. Use wall UTC + closed segment sums. Detect large gaps and clock jumps.

**Canonical current active seconds:**

```text
sum(closed work segment durations)
+ elapsed since current open work segment started
  (0 if paused / on break / idle)
```

Paused and pomodoro_break segments never add to active skill time.

**Heartbeat:** Update `last_heartbeat_utc` periodically while running (~15–60 s) for recovery classification — not as the primary elapsed formula.

**Checkpoints:** Persist on every transition. Optional 1–5 minute checkpoint of recovery metadata — do not rewrite all session rows every second.

---

## 5. Recovery sub-flow

```text
App launch
  → completion_pending? → open completion panel
  → session with open work segment (timer was running)?
       → gap = now − last_heartbeat_utc
       → gap ≤ 30 min → silent resume (recompute elapsed)
       → gap > 30 min OR clock anomaly OR restart with low confidence
            → Recovery Review:
                 • Include full gap
                 • Trim to last heartbeat
                 • Edit end time
                 • Discard session
  → session with open pause / pomodoro_break segment (not accruing)?
       → active seconds are unambiguous; heartbeats are not refreshed
         while not running, so the gap threshold does NOT apply
       → silent restore to paused / break state regardless of gap
         (clock anomaly still forces Recovery Review)
  → else normal Skills / onboarding
```

The `last_heartbeat_utc` gap classification applies **only** when the interrupted session was accruing active time (open `work` segment). A session left paused or on a Pomodoro break for hours has no uncertainty in active time and must not be routed into Recovery Review for gap length alone.

**Device power loss:** Exact shutdown instant may be unknown. Review allows user to choose; never claim exact active time across unusual gaps without review.

**Timer accuracy acceptance:** Stored duration within **10 seconds** of wall reality under normal operation (excludes deliberate clock manipulation and unknowable power-off intervals).

---

## 6. Idempotency examples

- Double Stop → one `completion_pending` session.  
- Notification Pause after UI Pause → success no-op.  
- Duplicate phase-complete → one next segment only.  
- Use operation tokens / state version checks where needed.

---

## 7. Pomodoro rules

Defaults: 25 / 5 / 15 / 4 cycles. Configurable. Auto-start break/next focus default off.

- Large UI clock = phase countdown; smaller = session active + skill total.  
- Focus → `work` segments (active). Breaks → `pomodoro_break` (paused accounting).  
- Manual pause during focus freezes countdown; does not count as active.  
- Persist phase transition **before** sound/notification.  
- Stop anytime → completion with sum of completed (and partial) focus work only.  
- Recovery restores phase, cycle, remaining duration.

---

## 8. Constants (v1)

| Name | Default | Configurable |
|---|---|---|
| Recovery gap threshold | 30 minutes | No (fixed v1) |
| Long-session warning | 8 hours active | Settings may allow override later; default 8h |
| Streak minimum | 120 seconds | Yes (Settings) |
| Pomodoro focus/short/long/cycles | 25m / 5m / 15m / 4 | Yes |
| Heartbeat interval | ~15–60 s | Implementation detail |

---

## 9. Atomic pause example

1. Verify runtime is running; command not already applied.  
2. Close current work segment (`end_at_utc`, `duration_seconds`).  
3. Increment session `active_seconds`.  
4. Insert pause segment.  
5. Update `timer_runtime` (state, current segment, anchors, heartbeat).  
6. Update session `updated_at_utc`.  
7. Commit.  
8. Update notification/tray (best effort).  
9. Publish UI state.

If step 8 fails, domain remains paused; show platform warning only.
