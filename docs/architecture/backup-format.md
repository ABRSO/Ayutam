# Ayutam — Backup Format & Conflict Resolution

**Status:** Authoritative  
**Related:** [Database](database.md) · ADR-004, ADR-005, ADR-012

---

## 1. Export types

| Format | Extension | Restore? | Purpose |
|---|---|---:|---|
| Portable archive | `.skilltracker` | Yes | Canonical cross-platform backup / merge |
| Human-readable JSON | `.json` | Yes | Transparent interchange |
| SQLite snapshot | `.sqlite` | Yes (mainly replace) | Consistent DB snapshot |
| Session CSV | `.csv` | No | Spreadsheet |
| Skill notes Markdown | `.md` / `.zip` | No | Human journal |

Only the first three are restoration sources. Mark backup successful **only after** parsing/verifying the written file.

Full backup filename:

```text
ayutam-backup-YYYY-MM-DD-HHmmss.skilltracker
```

Do not embed skill names in full-backup filenames.

---

## 2. Portable archive structure

ZIP (deflate). Fixed paths; reject path traversal, duplicates, symlinks, unexpected executables, decompression bombs, excessive size.

```text
manifest.json
payload/data.json
checksums.sha256
README.txt                 # optional human note
```

Encrypted variant (format reserved from v1; implementation Phase 2 / post-core):

```text
manifest.json              # includes encryption metadata, no secrets
payload/data.enc           # AES-256-GCM ciphertext
checksums.sha256
```

### 2.1 `manifest.json` (example)

```json
{
  "format": "ayutam-portable-backup",
  "formatVersion": 1,
  "createdAtUtc": "2026-07-22T12:30:45.123Z",
  "applicationVersion": "1.0.0",
  "databaseSchemaVersion": 1,
  "sourcePlatform": "windows",
  "sourceDeviceId": "d644fe5e-646e-4d79-b6c1-4a4e4016df08",
  "timezone": "Asia/Kolkata",
  "encrypted": false,
  "compression": "zip-deflate",
  "payload": {
    "path": "payload/data.json",
    "mediaType": "application/json",
    "sha256": "...",
    "uncompressedBytes": 123456
  },
  "summary": {
    "skills": 4,
    "sessions": 1284,
    "completedActiveSeconds": 8662500,
    "tags": 17,
    "containsActiveOrPendingSession": false
  },
  "encryption": null
}
```

When encrypted, `encryption` holds algorithm (`AES-256-GCM`), KDF (`Argon2id`), salt/nonce (base64), and KDF parameters — finalize parameters after Android baseline benchmarks (ADR). Never invent a custom cipher.

### 2.2 Payload `data.json`

Top level:

```json
{
  "dataVersion": 1,
  "exportedAtUtc": "...",
  "skills": [],
  "sessions": [],
  "sessionSegments": [],
  "tags": [],
  "sessionTags": [],
  "settings": [],
  "timerRuntime": null,
  "deviceMetadata": [],
  "backupMetadata": {
    "lastSuccessfulBackupAtUtc": "..."
  }
}
```

Records mirror DB fields with camelCase JSON names. Sessions include status, mode, source, timezone id, offsets, active/paused seconds, timestamps, soft-delete. Segments are first-class for fidelity of Pomodoro and cross-midnight recovery.

Checksums hash **exact UTF-8 file bytes** of entries — not re-serialized objects.

### 2.3 `checksums.sha256`

```text
<sha256>  manifest.json
<sha256>  payload/data.json
```

Manifest payload hash must agree. Validate before parsing full data into the live DB.

---

## 3. Other exports

**Standalone JSON:** Same logical payload + format/version/app version; hash exact bytes.

**SQLite snapshot:** Use `VACUUM INTO` or Online Backup API — never copy live DB while WAL is active. Integrity-check snapshot, hash, then hand to save dialog. Schema-tied; newer app migrates after replace; forward-incompatible rejected.

**CSV:** UTF-8 header row; columns include session_id, skill_name, title, start/end, timezone, active/paused seconds, mode, source, tags, note_markdown. RFC 4180 quoting. Prefix formula-like cells (`=`, `+`, `-`, `@`) for spreadsheet safety; document behavior. Not importable in v1.

**Markdown (one skill):** Title, target/tracked summary, sessions grouped by date with duration, tags, notes. Human-only.

---

## 4. Import validation stages

1. **File:** extension/magic, size limits, readable, safe ZIP.  
2. **Manifest:** product format, supported `formatVersion`, required fields, payload path, encryption metadata.  
3. **Integrity:** checksums, decrypt auth if any, bounded JSON parse.  
4. **Semantic:** UUIDs, relationships, non-negative durations, end ≥ start, enums, no duplicate IDs in payload, totals reconcile with segments within tolerance, ≤1 active/pending, settings keys known or ignorable.  
5. **Preview:** No live mutation yet — counts, totals, versions, active timer warning.  
6. **Snapshot** then transactional Merge/Replace.  
7. **Post:** integrity + statistics recalculation + completion report.

Reject on failure **before** mutation. Never partial-commit a merge.

---

## 5. Replace

1. Import lock; snapshot current DB (`pre_replace`).  
2. Build temp DB from normalized import (migrate to current schema).  
3. Integrity + summary verify.  
4. Atomic swap or single transaction replace.  
5. Reopen + verify; keep pre-import snapshot until next healthy startup.  
6. Restoring active/paused timer requires **separate** confirmation.

---

## 6. Merge (last-write-wins)

Identity is **UUID** only — never time overlap, title, or note similarity.

| Case | Action |
|---|---|
| Incoming only | Insert |
| Same content hash | Skip |
| Incoming `updated_at` newer | Take incoming wholesale |
| Local newer | Keep local |
| Equal `updated_at`, different hash | Conflict item; default **Keep Current**; user may Prefer Imported (all or per item) |
| Soft-delete vs present | Newest state wins (including deletion) |

**Order:** devices/metadata → skills → tags → sessions → segments → session_tags → mergeable settings → timer runtime (rules below).

**Timer runtime:** The singleton `timer_runtime` row is derived state and is **not** merged by LWW. It is resolved *after* session-level conflict resolution:

- If the merged database has no `active`/`paused`/`completion_pending` session, clear `timer_runtime` to idle — even if the import payload carried a runtime row.
- If exactly one such session survives the merge, rebuild `timer_runtime` from that session's persisted segments (never import the row verbatim; it may reference a session the merge rejected).
- Restoring a runtime that resumes a live timer requires the same separate confirmation as Replace (§5.6); without confirmation the surviving session enters Recovery Review on next timer open rather than silently running.

**Settings:** Newest wins for portable prefs (theme, timezone). Never import device paths, window geometry, tray, notification permission, PIN material.

**Deletions:** v1 does not keep permanent tombstones forever — a deleted record may reappear if an older backup is merged; preview must state this. Prefer Replace for authoritative restore.

**Active session conflicts:** If both sides have active/paused/pending, do not silently pick — offer keep current / prefer imported / import other as completed with reviewed end / cancel. Maintain one-active invariant.

---

## 7. Format compatibility

- Newer app must import older `formatVersion` via in-memory migrations (do not rewrite the archive file).  
- Newer unsupported format → reject with minimum app version if present.  
- Unknown optional fields ignored; unknown required/enums fail validation.  
- Export format version independent of Drift schema version.

---

## 8. Failure recovery

Pre-commit failure → rollback, original data intact. Mid-swap / restart → detect incomplete marker, validate current DB, restore snapshot if invalid, retain diagnostics. Partial merge without error/recovery is a **release-blocking** defect.

---

## 9. Reminders and history

Weekly reminder default. Settings: last successful verified backup + sessions changed since watermark. Reminder must never imply cloud sync occurred. Record attempts in `backup_history`.
