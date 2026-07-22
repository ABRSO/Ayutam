# Ayutam — UI/UX Specification

**Status:** Authoritative  
**Related:** [Product spec](product-spec.md) · [Architecture](../architecture/architecture.md)

---

## 1. Visual direction

**Style:** Dark-productivity-first with Material 3 structure and restrained GitHub-inspired touches for data-dense UI (heatmaps, tags, activity summaries). Flat cards, subtle borders over heavy shadows, monospace/tabular numerals for durations.

**Themes:** Light and Dark; default **Follow system**.

**Typography:** Material 3 UI sans for body/labels. **Tabular / monospace numerals** for all duration and timer figures (flip clock, cards, summary, tooltips) — e.g. Roboto Mono or JetBrains Mono, redistributable, with system monospace fallback.

**Colour:** Neutral base theme. Each skill has an accent from a fixed colourblind-considerate palette (8–10 hues) or custom pick. Accent used on Home card edge, chart lines/legend, per-skill heatmap tint. All-skills heatmap uses a single neutral green scale (GitHub convention). Colour never sole state indicator.

**Motion:** Animation only for flip-clock identity and clear state change. Reduced Motion disables 3D flips and chart entrance animations.

---

## 2. Design tokens

### Spacing (4px grid)

`4 / 8 / 12 / 16 / 24 / 32 / 48 / 64`

### Shape

- Skill cards: 16 radius  
- Dialogs/sheets: 20–28  
- Chips: 8 or fully rounded  
- Flip cards: 8–16 with visible center split  
- Focus outline: ≥ 2 logical px  

### Touch

Minimum interactive target **48×48** logical pixels.

---

## 3. Information architecture

**Primary navigation (4 destinations):**

1. Skills (Home)  
2. Learning Log  
3. Statistics  
4. Settings  

**Nested (not tabs):** Create/Edit Skill, Pre-session sheet, Immersive Timer, Session Completion, Session Detail/Edit, Manual Session, Backup Preview, Conflict Review, Snapshots, Diagnostics, Onboarding, Recovery Review, App lock overlay.

Timer is nested because it only exists after choosing a skill.

---

## 4. Screens

### 4.1 Skills (Home)

**Mobile:** App bar (name, search, overflow), optional backup-due banner, filter chips Active/Completed/Archived, single-column panels, Create Skill FAB/prominent button, bottom nav visible unless sheet open.

**Desktop:** Left rail; centered skill list max width ~900–1100; Create in toolbar; optional persistent search. Do not turn Home into a multi-column dashboard.

**Skill panel:**

1. Accent strip  
2. Name + overflow  
3. Accumulated / target  
4. Progress bar + %  
5. Remaining  
6. Large Play control  
7. Expand affordance  
8. Expanded: recent sessions + View all  

Play is dominant but cards must not become control panels. Expanding one card need not collapse others unless height is constrained.

### 4.2 Pre-session sheet

Mobile bottom sheet / desktop dialog:

```text
{Skill name}
{accumulated} of {target}

[ Stopwatch ] [ Pomodoro ]
Pomodoro: 25m focus · 5m break · 4 cycles   (if Pomodoro)

Optional session title

[Cancel]                         [Start]
```

Remember last mode per skill. Never auto-start. If another session is active: Open active timer / Stop active and start this / Cancel.

### 4.3 Immersive timer

Hide primary nav chrome.

**Stopwatch:**

```text
{Skill}

[large flip] HHH : MM : SS     ← accumulated skill total (dominant)

Current session  HH:MM:SS      ← smaller mono, no flip competition

          [ Pause/Resume ]  [ Stop ]
```

Hours: as many digits as needed (unpadded beyond 2); left-pad hours to at least 2 digits.

**Pomodoro:**

```text
{Skill} · Focus N of M

[large flip] MM : SS           ← phase countdown

Session active …
Skill total …

          [ Pause ]  [ Stop ]
```

**Orientation:** Android phones request landscape when timer opens if setting enabled; restore prior orientation on leave. Usable in portrait if OS refuses rotation. No forced orientation on desktop/large tablets.

**Keep screen awake:** Only while timer visible and setting on.

### 4.4 Flip-clock motion

Each digit: top/bottom panels, hinge seam, subtle shadow. On change, ~350–550 ms 3D rotateX of top flap (fast-out-slow-in). Only changed digits animate. Reduced Motion → instant/fade. Pause frame updates when app not visible; timestamps remain authoritative. Custom widget — no novelty package.

### 4.5 Session completion

Mobile: full-height sheet or page. Desktop: modal.

1. Summary card (read-only)  
2. Optional title  
3. Markdown editor with Edit/Preview  
4. Tags  
5. Edit Time  
6. Save / Resume / Discard  

Primary label: **Save Session**. Autosave status: Saving… / Saved locally / Save failed — Retry.

### 4.6 Learning Log

**Mobile:** Search, grouping Day/Week/Month, filter button with count, calendar in toolbar, sticky group headers, cards → full-screen detail (preserve scroll on back).

**Desktop (≥ ~1000 dp):** Left — calendar, filters, grouped list; right — detail + rendered Markdown. Selected card highlighted.

**Card (collapsed):** title or first note line or “Untitled session”; skill + accent; date and start–end; duration; tag chips; note preview; source icon (manual/Pomodoro/stopwatch); overflow. Prefer overflow over permanent Edit/Delete on every mobile card.

### 4.7 Statistics

Skill scope control + compact summary above views. Mobile: horizontally scrollable summary or 2-col grid; segmented Progress / Activity / Summary. Desktop: tabs Cumulative / Heatmap / Summary Table.

Chart min height ~280 mobile / ~420 desktop. Range controls collapse on narrow layouts. Comparison: colour **and** dash/marker differences. Heatmap: weekly columns, weekday rows, legend, focus/tap shows exact duration. Summary table: desktop table; mobile cards or horizontal scroll; change uses icon + text.

### 4.8 Settings

Grouped list: Appearance, Timer & Pomodoro, Statistics, Backup & Data, Privacy & Security, About. Desktop may use category list + panel.

**Backup status card:**

```text
Last successful backup: 18 days ago
27 sessions changed since backup
[Export now]
```

States: recent / due / never / last export failed.

### 4.9 Import preview

Show file name, created date, app version, format version, shortened device ID, skills/sessions/total duration, active/pending timer presence, checksum result, encryption status. Then Merge vs Replace with consequences.

### 4.10 Onboarding

Three concise screens (see product spec). Primary CTA ends on create skill or empty Skills.

---

## 5. Responsive layout

| Width (dp) | Class | Navigation |
|---:|---|---|
| < 600 | Compact phone | Bottom nav |
| 600–839 | Large phone / small tablet | Bottom nav (rail if landscape tablet) |
| 840–1199 | Tablet / compact desktop | Navigation rail |
| 1200–1599 | Desktop | Rail |
| ≥ 1600 | Wide desktop | Extended rail / compact sidebar |

Immersive timer: navigation hidden.

**Skills:** Single column everywhere for v1; wide desktop may optionally show a narrow backup/activity side panel only if it preserves minimal character.

**Learning Log:** Compact = list + separate detail; desktop = two-pane. Three-pane on ultra-wide only after usability review; two-pane is baseline.

**Statistics:** Stacked on compact; fuller hover/tooltips on desktop.

**Input:** Touch 48×48; mouse hover/tooltips/context menus; keyboard tab order, Enter/Space, Escape closes modals; desktop drag-drop import with file picker fallback.

---

## 6. User flows (summary)

1. **First launch:** Onboarding → create skill → Play → Start → timer → Stop → completion → Save → Home updates; first-export education.  
2. **Normal stopwatch:** Play → Start → Pause → leave app → reopen paused → Resume → Stop → Save without note.  
3. **Crash recovery:** Kill → relaunch → silent resume or Recovery Review.  
4. **Pomodoro:** Select mode → focus/break cycles → Stop → Save (work-only active).  
5. **Manual entry:** Learning Log / skill overflow → form → overlap warn → Save.  
6. **Heatmap → Log:** Day popover → Open in Learning Log (filtered).  
7. **Backup round-trip:** Export verified → other device Replace/Merge → verify totals.  
8. **Delete all data:** Typed confirm → optional export first → snapshot → empty/onboarding.

Full state detail: [timer-state-machine.md](../architecture/timer-state-machine.md).

---

## 7. Empty states

| Context | Copy | Primary action |
|---|---|---|
| No skills | Create your first skill to begin tracking deliberate practice. | Create Skill |
| No sessions (Log) | Your completed sessions and learning notes will appear here. | Start a Session |
| Sessions but no notes | You have logged sessions, but no notes yet. | — |
| Search no results | No sessions match the current search and filters. | Clear Filters |
| Stats empty | Complete a session to begin building your progress chart. | — |
| Never backed up | Your progress currently exists only on this device. | Create Backup |
| Archived empty | No archived skills. | — |

No blame language; one primary next action; illustrations optional.

---

## 8. Confirmation vs Undo

**Undo (~5 s snackbar):** individual session delete, tag association removal, easy archive reverse.

**Confirm:** discard active/completion-pending session; permanent skill delete (type name); Replace import; Delete All Local Data; restore snapshot; Exit while timer would be affected; short session (< 1 min) save/discard prompt; overlapping session save-anyway.

---

## 9. Error presentation (user-facing)

| Situation | Message essence | Recovery |
|---|---|---|
| Checksum mismatch | Backup corrupted/incomplete; no data changed | Choose another file |
| Newer format | Update app before importing | Dismiss |
| Import mid-failure | No changes; data untouched | Retry / export diagnostics |
| DB integrity on launch | Problem with local data | Repair / restore snapshot / diagnostics |
| Overlap | Overlaps another session | Save anyway / edit |
| Short stop | Very short session | Save / Discard |
| Skill delete | Type name to confirm | Type-to-confirm |
| Uncaught | Something unexpected happened | Export diagnostic log |

Never show stack traces in normal UI. Typed error codes for logs: `VAL-*`, `DB-*`, `TIMER-*`, `FILE-*`, `BACKUP-*`, `IMPORT-*`, `PLATFORM-*`, `SEC-*`, `UPDATE-*`.

---

## 10. Accessibility

Target WCAG 2.2 AA principles where applicable to native Flutter.

- Semantics on every icon-only control (Start/Pause/Stop session).  
- Flip clock: one combined duration announcement, not per digit.  
- Heatmap/chart cells: text alternatives; focus exposes date + duration (+ session count where relevant).  
- Keyboard: full desktop operability; shortcuts discoverable; text focus suppresses conflicting globals.  
- Contrast AA in light and dark.  
- Text scale ≥ 200% without clipping critical content; flip digits may constrain but combined duration remains available.  
- Reduced Motion from Settings and platform preference when exposed.  
- Colour-independent comparison (dash/markers) and heatmap selection states.

Manual passes: TalkBack, Narrator + keyboard-only, Orca where feasible.
