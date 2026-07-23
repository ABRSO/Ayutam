> **SUPERSEDED — do not use as implementation source of truth.**
>
> This document is retained for historical traceability only. The authoritative specification lives under `docs/` (see [docs/README.md](../README.md)). An implementing agent must follow `AGENTS.md` and the current docs, not this archive file.
>
> Archived: 2026-07-22

---
# Ayutam

I saw these two applications in the google playstore and I really like some aspects of them. Like in the `SHPAVDA's 10000 Hours: Skill Tracker` application, the homepage has the created skills in panels and there is a button to create a new skills. If you click on a skill, you can see History(previous sessions in tabs) below the skill panel.

I want my homepage to be the skills page, and if I want to resume/start a session, I can click on a play button on that skill's panel and it will ask the user to start the session? When he presses, then the Clock/stop watch with the accumulated time will show up and it will run. The clock should look like this: ![ ](image-1.png) , https://play.google.com/store/apps/details?id=flip.clock.pomodoro.studytimer.studyclock.desktopclock.fliqlo.flipclock&hl=nl . When I stop the session clock, then it will ask me the stuff we discussed and then it'll be saved.

## Claude web

### A. Platform

1. ~~Flutter vs PWA~~ → **Flutter, decided.**

2. Do you want this on **app stores** (Play Store, Microsoft Store) eventually, or is sideloaded APK / installed EXE for your own use the actual end goal? (Store distribution adds signing, review, and update-mechanism overhead — real maintenance cost you may not want.)
 - A: I eventually want to release it there, but that is a very much later. So structure the codebase and development documentation and stuff to enable that sort of development in the future.

3. Desktop targets: **Windows only**, or Windows + Mac + Linux?
 - A: Windows, Android and Linux.

### B. Data storage and import/export
4. Confirm: **zero automatic sync** — manual export/import is the only mechanism to move data between devices?
 - A: Yes.

5. If you use the app on two devices before syncing — should import **merge** two divergent files, or is **overwrite-only** acceptable (you're responsible for exporting/importing in the right order)?
 = A: Will merging not introduce conflicts if both have some data in a timeframe? If its too much without any backend, then Overwrite-only is fine.

6. Storage format: **SQLite** as the live app database, with JSON as an optional secondary export format — or JSON as primary storage too?
A: SQLite as the primary db and JSON export.

### C. Timer behavior
7. If the app is force-closed or the device restarts mid-session, should the timer **resume automatically** on reopen (computed from a saved start-timestamp), or is losing an unsaved in-progress session on a hard crash acceptable for v1?
 - A: The timer should **resume automatically** on reopen.

8. Can only **one timer run at a time** across all skills, or should simultaneous timers for different skills be possible?
 - A: Good question. **one timer run at a time** is enough, I will be doing one skill at a time if that is what you are suggesting.

9. Should users be able to **manually edit** a session's start/end time after saving (e.g., forgot to stop it overnight)?
 - A: Yes.

10. Confirming pause/resume is *within* one session (freezes the clock, session stays open), not a way to split one session into multiple pieces?
 - A: Yes not a way to split one session into multiple pieces.

### D. Skills and targets
11. Multiple skills tracked independently and unbounded in number — confirmed?
 - A: Yes confirmed.

12. Is the **10,000-hour target configurable per skill**, or always hardcoded to 10,000?
 - A: Default should be 10,000 hour but configurable

### E. Stats page
13. Cumulative chart — one skill at a time, or overlay multiple skills for comparison?
 - A: Default and primary should be one skill at a time, with option to overlay multiple skills for comparision.

14. Streak definition: does *any* session that day count regardless of length, or is there a minimum duration?
 - A: Minimum should be 2 minutes.

15. Confirm: no accounts, no auth, no multi-user, no cloud — ever, not just for v1?
 - A: yes ever

### G. New from our storage discussion
16. Want the **export reminder** ("last backed up: N days ago") and/or **auto-export on a schedule** as an actual v1 feature, or keep v1 to manual export-on-demand only and revisit this later?
 - Good idea, include the **export reminder**

---

## ChatGPT web

## Current understanding

The product is a **local-first, offline 10,000-hour skill tracker** built primarily with Flutter. It should:

* Track practice through a stopwatch-style timer.
* Display cumulative progress using a flip-clock interface.
* Save each completed session with optional learning notes.
* Provide a dedicated **Learning Log** rather than an overwhelming chronological text list.
* Provide statistics through:

  * Cumulative progress chart
  * Calendar heatmap
  * Summary metrics and a summary table
* Store all information locally.
* Require no account, authentication, server, backend, subscription, or proprietary cloud.
* Allow the complete application state to be exported as a portable backup file and restored on another supported device.
* Potentially run on Android and Windows from one Flutter codebase.

Before producing the complete specification, the following decisions need to be resolved.

---

# Product requirements questionnaire

You can answer by copying the question numbers and placing your answers beside them. For questions where the proposed default is acceptable, write **“Use recommended default.”**

## 1. Product scope and skill model

### 1.1 Number of skills

Should the application support:

* **A. One skill only**, such as AI Learning
* **B. Multiple independent skills**, such as AI Learning, Guitar and Fitness

**Recommended:** Multiple skills. Each skill should maintain its own timer, goal, sessions, notes and statistics.
 - A: **“Use recommended default.”**

### 1.2 Goal duration

Should every skill always target exactly 10,000 hours, or should users be allowed to configure the goal?

Examples:

* 10,000 hours for AI Learning
* 500 hours for Python
* 100 hours for Public Speaking

**Recommended:** Default to 10,000 hours but allow a custom goal.
 - **“Use recommended default.”**

### 1.3 Skill information

Which fields should a skill contain?

Proposed fields:

* Name
* Optional description
* Target hours
* Creation date
* Optional icon
* Optional colour
* Status: active, completed or archived

Should all these fields be included?
 - A: Only Name, Optional description, Target hours, Creation date(take default as today's date), Optional colour

### 1.4 Subskills or categories

Should a skill support subcategories?

Example:

```text
AI Learning
├── Mathematics
├── Machine Learning
├── Deep Learning
└── LLM Engineering
```

A completed session could optionally be associated with one category.

**Recommended for the first version:** Do not include nested subskills. Optionally support simple session tags later.
 - A: **“Use recommended default.”**

### 1.5 Skill lifecycle

Should users be able to:

* Rename a skill
* Change its target
* Archive it
* Restore it
* Delete it permanently

Should permanent deletion require typing the skill name or confirming twice?
 - **“Use recommended default.”**

### 1.6 Completed goal behaviour

When a skill reaches its target, should the application:

* Continue tracking beyond the target
* Mark it as completed but allow additional sessions
* Stop users from adding time

**Recommended:** Mark it completed but permit continued tracking.
 - **“Use recommended default.”**

---

## 2. Supported platforms

### 2.1 Initial release platforms

Which platforms must be supported in version 1?

* Android APK
* Windows desktop
* Linux desktop
* macOS desktop
* iOS
* Browser/web
* Progressive Web App

You originally described both Android and Windows. You also described opening the application from a café computer through a browser. These are different distribution models, so their priority needs to be established.
 - Android APK, Windows desktop, Linux desktop

### 2.2 Browser requirement

Is browser access an actual version-1 requirement, or was it an example of portability?

A Flutter web version is possible, but it introduces differences:

* Browser storage can be cleared.
* File access is restricted by browser security.
* Import and export must use browser download and file-picker mechanisms.
* Timers may be throttled when the tab is inactive.
* Installing or launching an executable may be impossible on a public computer.

**Recommended:** Android and Windows first. Flutter web can be added as a secondary portable client that relies on explicit import and export.
 - Android and Windows and Linux.

### 2.3 Cross-platform feature parity

Should all platforms contain the same features and layouts, or may desktop have enhanced features such as:

* Keyboard shortcuts
* Drag-and-drop backup import
* Larger charts
* Side-by-side Learning Log detail panel
* System-tray timer controls
 - Except Side-by-side Learning Log detail panel, the rest provided we do not need to maintain two seperate codebases for desktop and mobile just for these features.

### 2.4 Minimum operating-system versions

Do you have minimum versions in mind?

Examples:

* Android 10+
* Windows 10 and 11

**Recommended:** Android 10+ and 64-bit Windows 10/11 unless compatibility with older devices matters.
 - **“Use recommended default.”**

### 2.5 Application distribution

How do you intend to install or distribute it?

* Android APK sideloading
* Google Play Store
* Windows ZIP or installer
* Microsoft Store
* GitHub Releases
* Personal use only
 - A: I eventually want to release it in play and microsoft store, but that is a very much later. So structure the codebase and development documentation and stuff to enable that sort of development in the future. For now it is just sideloading, windows and linux installer as well as github releases.

### 2.6 Open-source status

Will the repository be:

* Private
* Public and open source
* Public source code but not formally licensed yet
 - A: MIT license FOSS

---

## 3. Timer and clock behaviour

### 3.1 Primary clock value

When a session starts after 220 accumulated hours, what should the primary flip clock show?

* **A. Current session duration:** `00:00:01`, `00:00:02`
* **B. Total accumulated duration:** `220:00:01`, `220:00:02`
* **C. Both:** large cumulative clock with a smaller current-session timer
* **D. User-selectable toggle**

Your description currently suggests option B.

**Recommended:** Show total accumulated time prominently and current-session duration underneath.
 - **“Use recommended default.”** , the accumulated clock should be bigger.


### 3.2 Time format

How should long durations be displayed?

* `220h 35m 42s`
* `0220:35:42`
* `220 HOURS / 35 MIN / 42 SEC`
* Separate flip-clock cards for hours, minutes and seconds
 - A: Separate flip-clock cards for hours, minutes and seconds

### 3.3 Timer precision

Should sessions be stored to the nearest:

* Second
* Minute
* Millisecond

**Recommended:** Store whole seconds and display hours, minutes and seconds.
 - **“Use recommended default.”**

### 3.4 Pause behaviour

When the user pauses:

* The current session remains active.
* Paused time is excluded.
* The user can resume or stop.
* Closing the app must not discard the paused session.

Is that correct?
 - A: Yes, **“Use recommended default.”**

### 3.5 Background operation

Should the timer continue correctly when:

* The Android app is minimized
* The phone screen is locked
* The Windows application is minimized
* The computer sleeps
* The application is closed accidentally
* The phone restarts

**Recommended:** Persist timer timestamps and reconstruct elapsed time instead of relying only on a continuously running in-memory counter.
 - A: **“Use recommended default.”**

### 3.6 Application termination

When the user force-closes the app during an active session, should reopening it:

* Automatically continue the session
* Ask whether the session should be resumed or stopped
* Automatically stop at the time the app was closed

**Recommended:** Treat the timer as active until explicitly stopped, then ask the user to confirm the recovered session after unusually long interruptions.
 - A: **“Use recommended default.”**

### 3.7 Device restart

Should an active timer survive a phone or computer restart?

This is technically possible through persisted timestamps, but the product behaviour must be defined.
 - A: Yes this is required or atleast it should count the time till device restarted/crashed.

### 3.8 One active timer

Should only one skill be timed at a time?

**Recommended:** Yes. Starting another skill should require pausing or stopping the current timer.
 - A: **“Use recommended default.”**

### 3.9 Accidental starting or stopping

Should the application provide:

* Undo after stopping
* Confirmation before discarding an active session
* Confirmation when stopping a session shorter than one minute
* Protection against double-clicking the Start or Stop button
 - A: **“Use recommended default.”** .

### 3.10 Maximum session length

Should the app flag unusually long sessions, such as:

* More than 12 hours
* More than 24 hours
* More than a user-configurable duration

This can prevent accidentally leaving a timer running for several days.

**Recommended:** Show a warning after 8 hours but do not stop automatically.
 - A: **“Use recommended default.”**

### 3.11 Idle detection

Should the application attempt to detect inactivity and ask whether idle time should be removed?

This would add complexity and platform-specific behaviour.

**Recommended for version 1:** No automatic idle detection.
 - A: **“Use recommended default.”**

### 3.12 Android timer notification

Should an active Android timer show a persistent notification with:

* Skill name
* Elapsed time
* Pause button
* Stop button

This improves reliability and makes an active timer visible outside the application.
 - A: Yes, **“Use recommended default.”**

### 3.13 Desktop system tray

Should Windows support minimizing the timer to the system tray?
 - A: yes

### 3.14 Keyboard shortcuts

Should Windows support shortcuts such as:

* Space: pause/resume
* Ctrl+Enter: start
* Ctrl+Shift+Enter: stop
 - A: Yes, **“Use recommended default.”**

---

## 4. Session completion and notes

### 4.1 Stop-session workflow

After Stop is selected, should the application:

1. Freeze the timer.
2. Open the session-completion panel.
3. Display calculated session details.
4. Allow an optional note.
5. Save when the user selects **Save Session**.

Or should the session be saved immediately before the note panel opens?

**Recommended:** Save a temporary completed session immediately so it is not lost, then finalize it when the user saves or skips the note.
 - A: **“Use recommended default.”**

### 4.2 Completion-panel actions

Should the panel have:

* Save Session
* Save Without Note
* Resume Session
* Discard Session
 - A: The note is an optional box, session can be saved without it

### 4.3 Note format

Should notes be:

* Plain text
* Markdown
* Rich text

**Recommended:** Plain text with line breaks in version 1.
 - Markdown. It looks just like plaintext for a normal sentence, but if the user wants to add a heading or formatting, markdown will be better.

### 4.4 Note length

Should there be a character limit?

**Recommended:** No restrictive limit; optionally show a soft counter after 2,000 characters.
 - A: **“Use recommended default.”**

### 4.5 Session fields

Proposed session fields:

```text
Session ID
Skill ID
Start timestamp
End timestamp
Active duration
Paused duration
Note
Creation timestamp
Last modified timestamp
Source device ID
Optional tags
```

Should tags be included in version 1?
 - A: Yes include tags in version 1 and **“Use recommended default.”**

### 4.6 Session title

Should users be allowed to assign a short title?

Example:

```text
Title: Transformer Attention Study
Note: Reviewed query, key and value matrices...
```

**Recommended:** Optional session title. It makes the Learning Log easier to scan.
 - A: **“Use recommended default.”**

### 4.7 Editing completed sessions

Should users be able to edit:

* Note
* Title
* Skill
* Start time
* End time
* Duration
* Tags

Changing time information affects totals and statistics, so the permitted fields need to be explicit.

**Recommended:** Allow all fields to be edited with a warning when duration changes.
 - A: **“Use recommended default.”**

### 4.8 Manual session entry

Should users be able to add a session without using the timer?

Example:

> Add a two-hour session completed yesterday.

**Recommended:** Yes. Manual entry is important when the timer is forgotten.
 - A: **“Use recommended default.”**

### 4.9 Deleting sessions

Should deleted sessions:

* Be permanently deleted immediately
* Move to a recoverable trash section
* Remain recoverable for 30 days

**Recommended:** Provide a simple undo immediately after deletion. A full trash system may be unnecessary for version 1.
 - A: **“Use recommended default.”**

### 4.10 Duplicate sessions

Should overlapping sessions be allowed?

Example:

```text
Session A: 7:00 PM–9:00 PM
Session B: 8:00 PM–10:00 PM
```

**Recommended:** Warn about overlap but allow the user to save it.
 - A: **“Use recommended default.”**

### 4.11 Sessions crossing midnight

A session from 11:00 PM to 1:00 AM crosses two dates. For the heatmap, should its duration be:

* Assigned entirely to the start date
* Assigned entirely to the end date
* Split accurately across both dates

**Recommended:** Split across dates for daily statistics, while retaining one session record.
 - A: **“Use recommended default.”**

---

## 5. Date, time and travel behaviour

### 5.1 Timestamp storage

Should timestamps be stored in UTC with the original local timezone offset?

**Recommended:** Yes. This prevents ambiguity when travelling or when daylight-saving rules apply.
 - A: Yes you can store it as UTC with timezone and offset in the db but in the app show the time in timezone they select in user settings, for example if I live in India,  it'll be IST

### 5.2 Travel between timezones

When opening the application in another timezone, should older sessions display:

* In the timezone where they occurred
* Converted into the current device timezone
* According to a user setting

**Recommended:** Preserve and display the local time at which the session originally occurred.
 - A: Hmmm, well in the user settings of the app add an option to add timezone, use that timezone to display in the whole app. No need of any conversions, they can change it if required.


### 5.3 Week start

Should a week begin on:

* Monday
* Sunday
* Based on device locale
* Configurable by the user
 - A: Based on device locale or if that is not possible then Monday

### 5.4 Time display

Should the application use:

* 12-hour clock
* 24-hour clock
* Device preference
 - A: Device preference

### 5.5 Changing device clock

Should the app detect when the system clock moves backward or forward during an active session?

**Recommended:** Use monotonic elapsed-time measurement during an active process and persisted UTC timestamps for recovery, with validation when discrepancies occur.
 - A: **“Use recommended default.”**

---

## 6. Home and timer page

### 6.1 Home-page structure

Should the timer page contain:

* Skill selector
* Skill name and target
* Flip clock
* Current-session duration
* Start, Pause and Stop controls
* Progress percentage
* Remaining hours
* Recent-session preview
* Link to Learning Log8

Which of these should remain visible on the primary screen?
 - A: Let me explain how the home page should be structured. The home page should be minimal and not cluttered. 

    - I saw this applications in the google playstore: https://play.google.com/store/apps/details?id=com.shpavda.tenthousandhours.skill.habit.goal.mastery.progress.tracker and I really like some aspects of them. Like in the `SHPAVDA's 10000 Hours: Skill Tracker` application, the homepage has the created skills in panels and there is a button to create a new skills. If you click on a skill, you can see History(previous sessions in tabs) below the skill panel.

    - It should contain and show: the skills which are already created(they shuold be shown one after the other below the other) selector, create When I start a session and clock starts flipping, that is the only thing which should be visible, with Start, Pause and Stop controls(these should not occupy the screen, the clock should be the major look)

    - I want my homepage to be the skills page, and if I want to resume/start a session, I can click on a play button on that skill's panel and it will ask the user to start the session? When he presses, then the Clock/stop watch with the accumulated time will show up and it will run. The clock should look like this: ![ ](image-1.png) , https://play.google.com/store/apps/details?id=flip.clock.pomodoro.studytimer.studyclock.desktopclock.fliqlo.flipclock&hl=nl . When I stop the session clock, then it will ask me the stuff we discussed and then it'll be saved.

    - Basically:
      * Skills listed in panels there, skill selector
      * Skill name and target
      * Current-session duration
      * Start, Pause and Stop controls
      * Progress percentage
      * Remaining hours
      * Link to Learning Log

### 6.2 Skill selection

A: For multiple skills,switching occur through:
* Home page is kind of the Skills page
* Horizontal skill cards
* Searchable picker

### 6.3 Application start screen

When the application opens, should it display:

* Last-used skill
* Skill dashboard
* Currently active timer
* An onboarding page when no skill exists

**Recommended:** Active timer when present; otherwise the last-used skill, An onboarding page when no skill exists
 - A: **“Use recommended default.”**

### 6.4 Flip animation

Should the flip clock animate every:

* Second
* Minute
* Only when the displayed value changes

Should users be able to disable the animation through a **Reduce Motion** setting?
 - A: Yes to save battery.

### 6.5 Screen-awake option

Should the user be able to prevent the screen from sleeping while the timer page is open?
 - A: Yes

---

## 7. Navigation and pages

### 7.1 Primary navigation

Proposed navigation:

1. **Timer**
2. **Learning Log**
3. **Statistics**
4. **Skills**
5. **Settings**

Is this the intended structure?
 - A: Yes, but the default screen is Skills

### 7.2 Mobile navigation

Should Android use a bottom navigation bar with three to five items?
 - A: **“Use recommended default.”**

### 7.3 Desktop navigation

Should Windows use:

* Left navigation rail
* Left sidebar
* Top navigation
* Same bottom navigation as mobile

**Recommended:** Bottom navigation on mobile and left navigation rail on desktop.
 - A: **“Use recommended default.”**

### 7.4 Separate skills page

Should users manage skills from a dedicated page, or should skill creation and editing exist inside the Timer page?
 - A: Same page is enough, just reminding you that this is primarily a skill tracker app with cool flip clock timer clock, as stated before.

---

## 8. Learning Log

### 8.1 Preferred primary layout

Which visual structure should be the default?

* **A. Timeline grouped by day, week or month**
* **B. Calendar with entries for the selected date**
* **C. Two-pane layout: date/session list on the left and full note on the right**
* **D. Card grid grouped by month**
* **E. Hybrid calendar and timeline**

**Recommended:** Hybrid layout:

* Desktop: date navigation and grouped session cards on the left, selected session detail on the right.
* Mobile: grouped timeline with expandable cards and a calendar/filter drawer.
 - A: **“Use recommended default.”**

### 8.2 Grouping

Should logs be grouped by:

* Day
* Week
* Month
* User-selectable grouping
 - A: User-selectable grouping

### 8.3 Session-card content

Which information should appear before opening a session?

Proposed:

* Session title or first line of note
* Skill
* Date
* Start and end times
* Duration
* Tag chips
* Note preview
* Edit button
* More-actions menu

### 8.4 Sessions without notes

Should sessions without notes appear in the Learning Log?

**Recommended:** Yes, with a subtle **No note added** state.
 - A: **“Use recommended default.”**


### 8.5 Search

Should Learning Log search cover:

* Notes
* Session titles
* Skill names
* Tags
* Dates
 - A: **“Use recommended default.”**

### 8.6 Filters

Proposed filters:

* Skill
* Date range
* Minimum or maximum duration
* With notes / without notes
* Tags
* Manual sessions / timed sessions

Which filters are required for version 1?
 - A: Skill, Date range, Minimum or maximum duration, With notes / without notes, Tags, Manual sessions / timed sessions

### 8.7 Sorting

Should users sort by:

* Newest first
* Oldest first
* Longest duration
* Shortest duration
 - A: **“Use recommended default.”**

### 8.8 Calendar navigation

Should the Learning Log include a compact calendar where selecting a day displays all sessions from that day?
 - A: **“Use recommended default.”**

### 8.9 Pagination

For years of records, should the page use:

* Infinite scrolling
* Load-more button
* Month-by-month navigation
* Virtualized list

**Recommended:** Month-based grouping with lazy loading.
 - A: **“Use recommended default.”**

### 8.10 Note detail

Should a selected note show:

* Complete note
* Session metadata
* Previous and next session navigation
* Edit and delete actions
* Copy note action
 - A: **“Use recommended default.”**

### 8.11 Linking from statistics

When a heatmap date is selected, should the app:

* Show the sessions inside the Statistics page
* Open the Learning Log filtered to that day
* Show a quick preview with an **Open in Learning Log** action

**Recommended:** Quick preview followed by an option to open the filtered Learning Log.
 - A: **“Use recommended default.”**

---

## 9. Statistics

### 9.1 Statistics scope

Should statistics be available for:

* Selected skill only
* All skills combined
* Both selected skill and all-skills views
 - A: Both selected skill and all-skills views, user selectable

### 9.2 Statistics navigation

You described three buttons:

1. Cumulative chart
2. Calendar heatmap
3. Summary table

Should these be:

* Tabs
* Segmented control
* Buttons
* Desktop tabs and mobile segmented control
 - A: Desktop tabs and mobile segmented control

### 9.3 Top summary card visibility

Should the top summary metrics remain visible above all three statistics views, or appear only on the summary view?

**Recommended:** Keep a compact summary visible above every view.
 - A: **“Use recommended default.”**

### 9.4 Average per week definition

How should **Average per week** be calculated?

* Total time divided by all calendar weeks since skill creation
* Average of weeks containing at least one session
* Rolling previous 4 weeks
* Rolling previous 12 weeks
* User-selectable

**Recommended:** Show the rolling 4-week average and label it explicitly.
 - A: **“Use recommended default.”**

### 9.5 Current streak definition

What counts as a successful streak day?

* Any non-zero session
* At least 15 minutes
* At least 30 minutes
* User-configurable minimum
* A skill-specific daily goal

**Recommended:** Any completed time greater than zero, unless daily targets are introduced.
 - A: **“Use recommended default.”**

### 9.6 Streak scope

Should streaks be calculated:

* Per skill
* Across all skills
* Both
 - A: Across all skills, if any skill was done then it should be counted

### 9.7 Missed-day tolerance

Should users have freeze days, rest days or configurable weekly schedules?

Example: The user plans to study only Monday through Saturday.

**Recommended for version 1:** No streak freezes. Clearly define a streak as consecutive calendar days.
 - A: **“Use recommended default.”**

### 9.8 Cumulative chart time ranges

Which ranges should be supported?

* 7 days
* 30 days
* 3 months
* 6 months
* 1 year
* All time
* Custom range
 - A: All of these things with a custom range. If this clutters in mobile, then you simplify it there

### 9.9 Cumulative chart aggregation

For longer periods, should the line represent:

* Daily cumulative totals
* Weekly cumulative totals
* Monthly cumulative totals
* Automatically selected granularity

**Recommended:** Automatic aggregation based on selected range.
 - A: **“Use recommended default.”**

### 9.10 Chart interactions

Proposed interactions:

* Hover on desktop
* Tap on mobile
* Tooltip showing date, cumulative total and time added that day
* Zoom and pan
* Date-range selector
* Milestone lines
* Goal line at 10,000 hours
* Full-screen chart mode
* Export chart as image

Which are required?
 - A: All of these are good

### 9.11 Milestones

Should the chart mark milestones such as:

* 10 hours
* 100 hours
* 500 hours
* 1,000 hours
* 5,000 hours
* Goal completion

Should milestones be fixed or user-configurable?
 - A: Fixed

### 9.12 Projection

Should the statistics page estimate a completion date based on the current weekly average?

Example:

> At 14.5 hours per week, estimated completion is in 13 years.

This can be motivating for some users and discouraging for others.
 - A: Yes this is a really good feature. **“Use recommended default.”**

### 9.13 Calendar heatmap period

Should the heatmap show:

* Current calendar year
* Previous 12 months
* A selected year
* Multiple years

**Recommended:** Previous 12 months by default with a year selector.
 - A: **“Use recommended default.”**

### 9.14 Heatmap intensity

Should colour intensity be based on:

* Fixed hour ranges
* Relative intensity compared with the user’s most active day
* Configurable daily goal completion

**Recommended:** Fixed ranges so colours remain comparable over time.
 - A: **“Use recommended default.”**

Proposed ranges:

```text
No activity
1–30 minutes
31–60 minutes
1–2 hours
2–4 hours
More than 4 hours
```

### 9.15 Heatmap details

When selecting a day, should the app show:

* Total time
* Number of sessions
* Start and end times
* Session titles
* Notes
* Link to full Learning Log
 - A: Total time for that day

### 9.16 Summary table definition

What exactly should the third statistics view contain?

Possible table:

| Period     | Total time | Sessions | Average session | Active days | Change |
| ---------- | ---------: | -------: | --------------: | ----------: | -----: |
| This week  |    14h 30m |        6 |          2h 25m |           5 |   +12% |
| Last week  |    12h 56m |        5 |          2h 35m |           4 |      — |
| This month |    48h 10m |       20 |          2h 24m |          16 |    +8% |

Should the summary table be daily, weekly, monthly, yearly or switchable?
 - A: **“Use recommended default.”** with switchable option.

---

## 10. Import, export and backup

### 10.1 Internal storage choice

For the live application, should the specification choose one canonical storage method?

Recommended architecture:

* **SQLite** as the internal database.
* **Versioned JSON backup** as the primary portable interchange format.
* Optional compressed backup archive for large datasets.
* Raw SQLite export only as an advanced or diagnostic option.

Is this acceptable?
 - A: **“Use recommended default.”**

### 10.2 Required export formats

Should the application support:

* Human-readable JSON
* Compressed JSON, such as `.json.gz`
* Application-specific ZIP archive
* Raw SQLite database
* CSV session export
* All of the above

Supporting every format increases testing and compatibility work.
 - A: What we agreed upon before is enough, SQLite and JSON, csv

### 10.3 Backup file contents

Should a full backup include:

* Skills
* Sessions
* Notes
* Targets
* Settings
* Tags
* Streak preferences
* Theme
* Active or paused timer
* Application schema version
* Backup creation date
* Source application version
* Source device identifier

**Recommended:** Include everything except temporary UI state. Include an active timer only after requiring explicit confirmation during restore.
 - A: **“Use recommended default.”**

### 10.4 Backup extension

Should the app use a recognizable custom extension such as:

```text
ai-learning-2026-07-10.skilltracker
```

Internally, the file could be a ZIP archive containing:

```text
manifest.json
data.json
checksum.sha256
```

This is safer and easier to version than treating an arbitrary JSON or database file as a complete backup.
 - A: **“Use recommended default.”**

### 10.5 Export naming

Should filenames follow:

```text
skill-tracker-backup-2026-07-10-183000.skilltracker
```

Or should the skill name be included?
 - A: Do not include the skill name.

### 10.6 Export scope

Should users export:

* Entire application
* One selected skill
* A selected date range
* Sessions only as CSV
* Notes only as Markdown
 - A: Entire application, but also an option to export any selected skill and its notes as markdown.

### 10.7 Import strategy

When importing into an application that already has data, should users choose between:

* Replace all existing data
* Merge with existing data
* Preview before choosing
* Import as a separate profile

**Recommended:** Show a preview and provide **Merge** or **Replace**.
 - A: **“Use recommended default”** with preview if feasible.

### 10.8 Duplicate detection

Each skill and session should use a globally unique identifier. During merge, should matching IDs be:

* Skipped
* Replaced by the newer modified version
* Presented as conflicts
* Duplicated as separate records

**Recommended:** Automatically use the latest modification timestamp when only one side changed; show a conflict choice when both differ.
 - A: **“Use recommended default.”**

### 10.9 Two-device conflict scenario

Suppose the same backup is imported on Android and Windows. Both are edited independently and later merged. How should conflicts be resolved?

* Keep newest
* Keep both
* Ask for every conflict
* Use device priority
 - A: Keep newest

### 10.10 Import validation

Should import display a preview such as:

```text
Backup created: 10 July 2026
Application version: 1.2.0
Skills: 4
Sessions: 1,284
Total recorded time: 2,406h 15m
Format version: 3
Checksum: Valid
```

**Recommended:** Yes.
 - A: **“Use recommended default.”**

### 10.11 Corrupted backups

Should the import process:

* Reject the entire backup when validation fails
* Import valid records and report invalid ones
* Attempt recovery only through an advanced option

**Recommended:** Reject by default and never modify existing data until full validation succeeds.
 - A: **“Use recommended default.”**

### 10.12 Transactional restore

Should all imports occur inside a database transaction so that failure cannot leave the application partially imported?

**Recommended:** Yes.
 - A: **“Use recommended default.”**

### 10.13 Automatic safety backup

Before replacing or merging data, should the application automatically create a local recovery backup?

**Recommended:** Yes.
 - A: **“Use recommended default.”**

### 10.14 Backup reminders

Should the app remind the user to export a backup:

* Weekly
* Monthly
* After a configurable number of sessions
* When no backup has been created recently
* Never

This remains local and does not require cloud access.
 - A: Weekly

### 10.15 Last-backup indicator

Should Settings show:

```text
Last backup: 18 days ago
Sessions added since backup: 24
```
 - A: Yes

### 10.16 Automatic cloud integration

Should the application intentionally avoid direct Google Drive, OneDrive, Dropbox or GitHub integration in version 1?

The user can still save the exported file into those services through the operating system’s file picker or share sheet.

**Recommended:** Avoid direct provider integrations.
 - A: **“Use recommended default.”**

### 10.17 Encryption

Should backup files support optional password-based encryption?

* No encryption
* Optional encryption
* Always encrypted

**Recommended for personal notes:** Optional passphrase encryption, possibly after the core version is stable.
 - A: **“Use recommended default.”**

### 10.18 Local application lock

Should the app support:

* PIN lock
* Biometric unlock
* Windows Hello
* No lock
 - A: **“Use recommended default.”**

### 10.19 Data reset

Should Settings contain **Delete All Local Data** with a recommendation to export first?
 - A: **“Use recommended default.”**

### 10.20 Backup compatibility

Should newer versions of the app import old backup versions through migrations?

**Recommended:** Yes. Backward compatibility should be mandatory; forward compatibility may be rejected with a clear message.
 - A: **“Use recommended default.”**

---

## 11. Data ownership and profiles

### 11.1 Multiple local profiles

Should one installation support multiple independent profiles?

Example:

```text
Personal
Work
Exam Preparation
```

**Recommended:** No profiles in version 1. Skills already provide separation.
 - A: **“Use recommended default.”**

### 11.2 Device identifier

Should the application generate a random local device ID used only for merge history and conflict detection?

No account or personally identifiable information would be required.
 - A: **“Use recommended default.”**

### 11.3 Audit history

Should the app record actions such as:

* Session created
* Session duration edited
* Skill deleted
* Backup imported

This improves recoverability but adds complexity.

**Recommended:** Store `createdAt` and `updatedAt`, but do not create a complete audit log initially.
 - A: **“Use recommended default.”**

---

## 12. Design and visual direction

### 12.1 Overall visual style

Which direction best matches the product?

* Minimal monochrome
* Dark productivity dashboard
* Warm notebook/journal aesthetic
* GitHub-inspired developer aesthetic
* Custom light and dark themes
 - A: Dark productivity with GitHub-inspired developer aesthetic wherever applicable(like heatmaps and stuff). Use Material UI for a standard.

### 12.2 Theme support

Should version 1 support:

* Light only
* Dark only
* Light and dark
* Follow system theme
 - A: Light and dark, but Follow system theme.

### 12.3 Accent colour

Should each skill have its own colour, or should the application use one global accent colour?
 - A: each skill have its own accent colour.

### 12.4 Flip-clock references

Should the final design follow the references closely, or merely use their mechanical flip-card concept?
 - A: As close as possible, research across the internet for proper references(usually in aesthetic videos people run these clocks as aesthetics)

### 12.5 Responsive design

Should the specification define separate responsive layouts for:

* Compact phone
* Large phone
* Tablet
* Desktop
* Wide desktop
 - A: If this helps the agentic LLM model to understand and create the application better, then yes.

### 12.6 Orientation

Should Android support both portrait and landscape, or portrait only?
 - A: The application can be both portrait and landscape, but when the session starts and the clock/stopwatch starts, then it should be shifted to landscape mode. 

### 12.7 Empty states

Should the application include guided empty states such as:

> Create your first skill to begin tracking.

> Your completed sessions and notes will appear here.

 - A: yes

### 12.8 Onboarding

Should first launch include a short onboarding sequence explaining:

* Local-only storage
* Manual backup responsibility
* Creating a skill
* Starting a timer
* Exporting data

**Recommended:** A brief three-step onboarding with a prominent backup explanation.
 - A: **“Use recommended default.”**

---

## 13. Accessibility and usability

### 13.1 Accessibility requirements

Should the specification explicitly require:

* Screen-reader labels
* Keyboard navigation
* Sufficient colour contrast
* Text scaling
* Reduced-motion support
* Non-colour heatmap indicators
* Minimum touch-target sizes

**Recommended:** Include all.
 - A: **“Use recommended default.”**

### 13.2 Heatmap accessibility

Since colour alone should not communicate meaning, should selecting or focusing a cell expose its exact duration and session count?
 - A: Yes

### 13.3 Timer controls

Should Start, Pause and Stop use both icons and text labels rather than icons alone?
 - A: No

### 13.4 Confirmation behaviour

Do you prefer:

* More confirmations to prevent mistakes
* Minimal confirmations with Undo actions
* A combination based on action severity

**Recommended:** Undo for common reversible actions and confirmations only for destructive actions.
 - A: **“Use recommended default.”**

---

## 14. Settings

Which of these settings should exist?

* Theme
* Week-start day
* 12/24-hour format
* Default statistics period
* Heatmap intensity ranges
* Backup reminders
* Reduced motion
* Keep screen awake
* Streak minimum duration
* Date and number format
* Export location
* Optional backup encryption
* Application lock
* Diagnostic information
 - A: Include all of these

---

## 15. Technical architecture preferences

### 15.1 Architecture depth

Should the final specification prescribe a complete architecture, including:

* Presentation layer
* Application/use-case layer
* Domain models
* Repository interfaces
* SQLite data source
* Import/export service
* Platform services
* State-management approach
* Dependency injection
* Testing strategy

Or should it remain flexible so the implementation agent chooses libraries?

**Recommended:** Prescribe boundaries and behaviours, but allow equivalent maintained libraries.
 - A: The final specification prescribe a complete architecture. The implementation agent chooses libraries and also makes some decisions 

### 15.2 Flutter state management

Do you have a preference?

* Riverpod
* Bloc/Cubit
* Provider
* No preference

**Recommended for this application:** Riverpod or Bloc. Riverpod may be simpler for a small local-first application.
 - A: **“Use recommended default.”**

### 15.3 Database library

Do you prefer:

* Drift over SQLite
* Direct SQLite through `sqflite`
* Isar
* Hive
* No preference

**Recommended:** Drift backed by SQLite because it provides typed queries, migrations, transactions and desktop support.
 - A: **“Use recommended default.”**

### 15.4 Navigation library

Should the implementation use declarative navigation such as `go_router`, or keep navigation simple with Flutter’s standard APIs?
 - A: What advantage does declarative navigation such as `go_router` provide? If things can be achieved with standard APIs, that should be preferred for simplicity and 

### 15.5 Chart library

Should the technical specification select a chart library, or define an abstraction so it can be changed?
 - A: Select a chart library but also explicitly state that if the agent found a better way to implement this, then go with that

### 15.6 Package policy

Should the coding agent:

* Prefer mature, actively maintained packages
* Minimize dependencies
* Avoid packages with restrictive licences
* Document every third-party dependency and its purpose

**Recommended:** All of these.
 - A: **“Use recommended default.”**

### 15.7 Clean Architecture

Do you want strict Clean Architecture, or a lighter feature-based architecture?

**Recommended:** Feature-based modular architecture with clear repository and service boundaries. Full enterprise Clean Architecture would likely be excessive.
 - A: **“Use recommended default.”**

---

## 16. Reliability and data integrity

### 16.1 Data-loss standard

Should every state-changing action be persisted immediately?

Example:

* Timer started
* Timer paused
* Note typed
* Session saved
* Import initiated
 - A: Yes these are important

### 16.2 Note autosave

Should unsaved notes in the completion panel be autosaved as a draft?
 - A: Yes

### 16.3 Database migrations

Should each schema change include:

* Migration code
* Migration tests
* Backup compatibility tests
* Rollback or recovery behaviour
 - A: Yes

### 16.4 Database corruption

Should the app provide:

* Integrity check
* Recovery attempt
* Export diagnostic information
* Restore from latest local safety backup
 - A: Yes

### 16.5 Local safety snapshots

Should the application maintain a small number of automatic local snapshots, such as the last three database states before imports or destructive operations?
 - A: Yes

### 16.6 Storage size expectation

Approximately how many years and sessions should the app comfortably support?

Example target:

* 20 years
* 100 skills
* 100,000 sessions
* Notes averaging 2 KB each
 - A: 20 years and 100,000 sessions, this is a very large case, the reality will be far shorter but it is good to be prepared.
---

## 17. Privacy and diagnostics

### 17.1 Analytics

Should the application include any analytics or telemetry?

**Recommended:** None.
 - A: **“Use recommended default.”**

### 17.2 Crash reporting

Should it use an external crash-reporting service?

This would technically communicate with a backend and may conflict with the fully private design.

**Recommended:** No external crash reporting. Provide local diagnostic logs that users can export manually.
 - A: **“Use recommended default.”**

### 17.3 Network access

Should the application be designed to function with no network permission at all?

On Android, this could mean omitting internet permissions unless future update checks are introduced.
 - A: Future update checks are a good feature to have, but if this requires a backend service to be present then I do not need this.

### 17.4 Update checks

Should the app check GitHub Releases or another source for newer versions, or should updates be completely manual?
 - A: Future update checks from GitHub Releases are a good feature to have, but if this requires a backend service to be present then I do not need this.
---

## 18. Testing and acceptance criteria

### 18.1 Required test levels

Should the final plan require:

* Unit tests
* Database tests
* Migration tests
* Widget tests
* Integration tests
* Import/export round-trip tests
* Cross-platform compatibility tests
* Long-running timer tests
* Crash-recovery tests
* Accessibility tests

**Recommended:** Include all except extensive visual golden tests unless stable designs are available.
 - A: **“Use recommended default.”**

### 18.2 Critical end-to-end scenario

The primary acceptance test could be:

1. Create a skill on Android.
2. Record several timed and manual sessions.
3. Add notes.
4. Export the backup.
5. Transfer it to Windows.
6. Import it.
7. Verify exact totals, notes, timestamps, statistics and settings.
8. Add a session on Windows.
9. Export and restore it on Android.
10. Confirm no duplicates or lost data.

Should this be treated as the product’s principal end-to-end test?
 - A: Yes

### 18.3 Timer accuracy tolerance

What timer error is acceptable?

**Recommended:** Stored duration should deviate by no more than 10 seconds for normal operation, excluding deliberate system-clock manipulation.
 - A: **“Use recommended default.”**

### 18.4 Import guarantees

Should import be considered successful only when:

* Record counts match
* Total duration matches
* Checksums pass
* Referential integrity passes
* Statistics recalculate correctly
 - A: Yes

---

## 19. Version-1 boundaries

To prevent the project from expanding indefinitely, confirm which features must be excluded from version 1.

Proposed exclusions:

* Accounts and authentication
* Backend server
* Automatic cloud synchronization
* Social features
* Leaderboards
* Shared skills
* AI-generated learning summaries
* Attachments and images in notes
* Nested projects
* Multiple simultaneous timers
* Calendar integrations
* Pomodoro mode
* Complex recurring goals
* Public profiles
* Browser extension
* Wearable applications

Are any of these required for the first version?
 - A: Out of these, I need the following in v1:
    - Pomodoro mode

---

## 20. Final specification deliverables

After these decisions are answered, should the final documentation include all of the following?

1. Product requirements document
2. Functional specification
3. Feature specification
4. UI/UX specification
5. Responsive mobile and desktop layout specification
6. Technical architecture
7. Flutter project structure
8. State-management design
9. Database schema
10. Import/export file schema
11. Backup migration and conflict-resolution specification
12. Timer state machine
13. User flows
14. Navigation model
15. Error and empty states
16. Accessibility requirements
17. Security and privacy requirements
18. Testing strategy
19. End-to-end acceptance criteria
20. Phased implementation plan
21. Version-1 versus future-feature boundaries
22. Instructions suitable for Codex, Claude Code or another coding agent
23. Suggested `AGENTS.md`
24. Recommended Flutter packages and dependency rationale
25. Open questions and architectural decision records

Also confirm whether you want the result as:

* One consolidated document
* Several repository-ready Markdown documents
* Both a consolidated master specification and separate implementation documents

 - A: Yes I need all 25 in the final documentation and I want all of them in a single, One consolidated document