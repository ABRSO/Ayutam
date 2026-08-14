# ADR-021 — GitHub Releases distribution (sideload)

**Status:** Accepted  
**Date:** 2026-08-15

## Context

Ayutam ships on Android, Windows, and Linux without Play/Microsoft Store submission in v1. Users need downloadable artifacts from the repository. Packaging was originally parked in Phase 8; waiting until then would leave Phase 4+ merges without an installable GitHub Release.

## Decision

- **Channel:** GitHub Releases is the v1 sideload channel (not Play / Microsoft Store yet).
- **Versioning:** When phase *N* lands on `main`, bump `pubspec.yaml` to `0.N.0+N` and cut a `## [0.N.0]` CHANGELOG section. A workflow on `main` creates tag `v0.N.0` when that version has no existing release; the tag-triggered Release workflow builds artifacts.
- **Android:** `flutter build apk --release --split-per-abi` (arm64-v8a / armeabi-v7a / x86_64). Compile mode is **release** (AOT). Signing may remain the debug keystore until a Play upload keystore is configured (Phase 8) — debug-signed ≠ debug-mode.
- **Windows:** Inno Setup installer is the primary artifact; a portable zip of the Flutter `Release\` folder (exe + DLLs + `data/`) is also attached. No lone naked `.exe`.
- **Linux:** amd64 `.deb` plus a `.tar.gz` of the GTK bundle. No `.rpm`, makeself `.run`, or AppImage in v1 GitHub Releases.
- **Source:** GitHub’s automatic source zip/tarball on each release — no extra job.

## Consequences

Users can install from Releases after each phase version bump. Store signing, MSIX, AAB, and the optional in-app update check (F-023) remain Phase 8 / later work. Fedora/RHEL users unpack the Linux tarball.
