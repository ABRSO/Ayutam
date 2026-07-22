# Ayutam — Database Schema

**Status:** Authoritative  
**Engine:** Drift over native SQLite (Android, Windows, Linux)  
**Related:** [Backup format](backup-format.md) · [Timer](timer-state-machine.md) · ADR-003, ADR-009, ADR-017

---

## 1. Choice and conventions

SQLite is the live working store. User-selected files are exports only — never point the live DB at an arbitrary user path.

| Convention | Rule |
|---|---|
| IDs | UUID strings (v4 unless ADR documents v7) |
| Timestamps | Integer **milliseconds** since Unix epoch, UTC (one precision app-wide) |
| Durations | Integer **seconds** |
| Booleans | SQLite integer via Drift |
| Enums | Stable text values |
| Mergeable rows | `created_at_utc`, `updated_at_utc`, `source_device_id` |
| Foreign keys | Enabled |
| WAL | Allowed; backups use consistent APIs (`VACUUM INTO` / Online Backup), never raw copy of live WAL |
| Statistics | Derived — not authoritative stored counters |

**Session-segments model (confirmed):** Every work / pause / Pomodoro-break interval is a row in `session_segments`. `sessions.active_seconds` and `paused_seconds` are cached totals maintained in the same transaction as segment changes and verified by integrity checks.

---

## 2. Tables

### 2.1 `skills`

| Column | Type | Rules |
|---|---|---|
| `id` | TEXT PK | UUID |
| `name` | TEXT | required, trimmed |
| `description_markdown` | TEXT NULL | optional |
| `target_seconds` | INTEGER | > 0, default 36_000_000 (10,000 h) |
| `created_local_date` | TEXT | ISO `YYYY-MM-DD` |
| `accent_argb` | INTEGER NULL | nullable colour |
| `status` | TEXT | `active` \| `archived` |
| `sort_order` | INTEGER | home ordering |
| `created_at_utc` | INTEGER | |
| `updated_at_utc` | INTEGER | |
| `source_device_id` | TEXT | |
| `deleted_at_utc` | INTEGER NULL | short-lived soft delete if used |

Indexes: `(status, sort_order)`; optional case-folded name for search.

**Completed** is derived from totals vs target — do not overwrite `archived` when reconciling completion.

### 2.2 `sessions`

| Column | Type | Rules |
|---|---|---|
| `id` | TEXT PK | UUID |
| `skill_id` | TEXT FK | → skills |
| `title` | TEXT NULL | |
| `note_markdown` | TEXT NULL | |
| `mode` | TEXT | `stopwatch` \| `pomodoro` \| `manual` |
| `status` | TEXT | `active` \| `paused` \| `completion_pending` \| `completed` |
| `source` | TEXT | `timer` \| `manual` \| `imported` |
| `start_at_utc` | INTEGER | |
| `end_at_utc` | INTEGER NULL | null until stopped |
| `active_seconds` | INTEGER | ≥ 0, cached |
| `paused_seconds` | INTEGER | ≥ 0, cached |
| `timezone_id_at_creation` | TEXT | IANA |
| `offset_minutes_at_start` | INTEGER | audit/display fallback |
| `created_at_utc` | INTEGER | |
| `updated_at_utc` | INTEGER | |
| `source_device_id` | TEXT | |
| `deleted_at_utc` | INTEGER NULL | undo / merge tombstone window |

Indexes:

- `(skill_id, status, start_at_utc DESC)`
- `(status, start_at_utc DESC)`
- `(updated_at_utc)` for merge
- `(deleted_at_utc)`

**Invariant:** At most one session is `active`, `paused`, or `completion_pending`. Enforce in application transactions; add a partial unique index if reliable on all targets.

### 2.3 `session_segments`

| Column | Type | Rules |
|---|---|---|
| `id` | TEXT PK | UUID |
| `session_id` | TEXT FK | cascade delete |
| `segment_type` | TEXT | `work` \| `pause` \| `pomodoro_break` |
| `pomodoro_phase` | TEXT NULL | `focus` \| `short_break` \| `long_break` |
| `cycle_number` | INTEGER NULL | 1-based |
| `start_at_utc` | INTEGER | |
| `end_at_utc` | INTEGER NULL | open segment null |
| `duration_seconds` | INTEGER | closed duration |
| `created_at_utc` | INTEGER | |
| `updated_at_utc` | INTEGER | |

Indexes: `(session_id, start_at_utc)`; optionally `(start_at_utc)` for range queries.

Work segments count toward active time. Pause and pomodoro_break count toward paused time.

### 2.4 `timer_runtime` (singleton)

Operational state (not historical journal):

| Column | Type | Rules |
|---|---|---|
| `singleton_id` | INTEGER PK | always `1` |
| `session_id` | TEXT FK NULL | |
| `machine_state` | TEXT | see timer doc |
| `current_segment_id` | TEXT NULL | |
| `phase_planned_seconds` | INTEGER NULL | Pomodoro |
| `phase_started_at_utc` | INTEGER NULL | |
| `phase_accumulated_seconds` | INTEGER | excludes pause |
| `current_cycle` | INTEGER | default 1 |
| `monotonic_anchor_micros` | INTEGER NULL | valid within process/boot only |
| `wall_clock_anchor_utc` | INTEGER NULL | |
| `last_heartbeat_utc` | INTEGER | recovery gap detection |
| `last_checkpoint_at_utc` | INTEGER | |
| `recovery_reason` | TEXT NULL | `restart` \| `clock_change` \| `long_gap` |
| `updated_at_utc` | INTEGER | |

All session-affecting transitions update this row in the **same transaction**.

### 2.5 `tags`

| Column | Type |
|---|---|
| `id` | TEXT PK |
| `name` | TEXT |
| `normalized_name` | TEXT UNIQUE (case-folded/trimmed) |
| `created_at_utc` | INTEGER |
| `updated_at_utc` | INTEGER |
| `source_device_id` | TEXT |

### 2.6 `session_tags`

`(session_id, tag_id)` composite PK; FKs cascade delete.

### 2.7 `app_settings`

| Column | Type |
|---|---|
| `key` | TEXT PK |
| `value_json` | TEXT |
| `updated_at_utc` | INTEGER |
| `source_device_id` | TEXT | for mergeable settings |

Central typed codecs + defaults. Device-only keys (paths, window size, tray) never imported over current device.

### 2.8 `backup_history`

Records export attempts: type, destination display, timestamps, counts, totals, sha256, status, error_code. Success rows must have verification timestamp.

### 2.9 `local_snapshots`

| Column | Notes |
|---|---|
| `id`, `file_path`, `reason`, `created_at_utc`, `schema_version`, `file_sha256`, `size_bytes`, `is_valid` | Reasons: `pre_import`, `pre_replace`, `pre_delete`, `pre_restore`, `migration` |

Retain latest **3** valid snapshots by default.

### 2.10 `device_identity` (singleton)

Random UUID `device_id` — **no** hardware identifiers. Optional `display_name`.

### 2.11 `schema_metadata`

Key/value for logical data-format version if needed independently of Drift `schemaVersion`.

---

## 3. Full-text search (FTS5)

```sql
CREATE VIRTUAL TABLE session_search USING fts5(
  session_id UNINDEXED,
  title,
  note_markdown,
  skill_name,
  tags_text,
  tokenize = 'unicode61 remove_diacritics 2'
);
```

Maintain via repository updates or triggers. Diagnostics must offer rebuild. Search joins back to non-deleted completed (and optionally pending) sessions. Required for Learning Log latency targets (ADR-017).

---

## 4. Daily allocation

For heatmap / daily stats, allocate each **work** segment across configured-timezone midnight boundaries. Do not assign an entire cross-midnight session to its start date only.

**Initial approach:** Compute from indexed segments in Dart (or SQL) for requested windows. Introduce a derived `daily_skill_totals` cache only after profiling the 100k-session fixture. Correctness over premature caching.

---

## 5. Integrity checks

Expose / run:

- `PRAGMA foreign_key_check`
- `PRAGMA integrity_check` (or quick_check in routine diagnostics)
- No negative durations; end ≥ start when both set
- Completed sessions have no open segments
- Cached session totals equal sum of closed segment durations by type
- At most one non-completed open session
- `timer_runtime` references a valid session when non-idle
- Tag associations valid; skill targets > 0
- Backup success rows verified

On startup corruption: do **not** silently create a new empty DB over unreadable data — offer repair / snapshot restore / import / diagnostics / destructive reset with confirm.

---

## 6. Migrations

Every schema bump requires:

1. Forward migration in Drift `MigrationStrategy`
2. Generated schema snapshot
3. Migration test from each supported prior release
4. Integrity assertions after migration
5. Backup import compatibility coverage
6. Pre-risky-migration local snapshot; on failure, recovery UI — no silent destructive retries

---

## 7. Scale notes

At ~100k sessions / ~300k segments / ~2 KB notes, expect well under hundreds of MB. Composite indexes above keep Learning Log and stats queries fast. Soft-deleted rows are purged after a short retention (days), not a 30-day trash UI.
