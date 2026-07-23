# Security

Ayutam is a local-first application. There is no backend and no remote crash reporting.

## Reporting a vulnerability

If you discover a security issue (for example in backup archive handling, encryption, or local lock), please open a private report via GitHub Security Advisories when available, or contact the maintainer through the repository’s listed contact.

Please do **not** file public issues that include exploit details for unpatched releases.

## Scope notes

- Unencrypted backups may contain private notes — users choose where files are stored.
- Optional backup encryption and app lock are phased features; see ADR-018.
- The app must not phone home. Optional GitHub Releases update checks (when implemented) are opt-in only.
