# ADR-021 — GitHub Releases distribution (sideload)

**Status:** Accepted  
**Date:** 2026-08-15

## Context

Ayutam ships on Android, Windows, and Linux without Play/Microsoft Store submission in v1. Users need downloadable artifacts from the repository. Packaging was originally parked in Phase 8; waiting until then would leave Phase 4+ merges without an installable GitHub Release.

GitHub does **not** start a second workflow from a tag push that used the default `GITHUB_TOKEN`, so auto-tag and artifact build must be orchestrated explicitly (reusable `workflow_call`), not via chained tag events.

Android sideload upgrades require a **single permanent release signing certificate** shared by local and CI builds. Debug-keystore-signed “release” APKs from different machines are not interchangeable upgrades and can force uninstall (local data loss).

## Decision

- **Channel:** GitHub Releases is the v1 sideload channel (not Play / Microsoft Store yet).
- **Versioning:** When phase *N* lands on `main`, bump `pubspec.yaml` to `0.N.0+N` and cut a `## [0.N.0]` CHANGELOG section. The **Publish release** workflow on `main` ensures tag `v0.N.0` exists, then **calls** the reusable **Release** workflow (`workflow_call`). Manual retry: `workflow_dispatch` on either workflow. Human-pushed `v*` tags still run Release directly.
- **Retry:** If the tag exists but the GitHub Release is missing **or missing platform assets**, Publish release invokes Release without recreating the tag. `workflow_dispatch` always rebuilds. Release upserts assets (`gh release upload --clobber` / `gh release create`) and fails if any expected Android/Windows/Linux file is absent.
- **Android artifacts:** `flutter build apk --release --split-per-abi` (arm64-v8a / armeabi-v7a / x86_64). Compile mode is **release** (AOT). Signing uses the permanent Ayutam release keystore (`android/key.properties` locally; repository secrets in CI). Release builds **fail closed** when `key.properties` is missing, incomplete, or the JKS is absent — no silent debug-certificate fallback and no unsigned APK. Debug/profile stay usable without it; a debug-signed release-mode build requires an explicit opt-in (`-Payutam.allowDebugReleaseSigning=true` or `AYUTAM_ALLOW_DEBUG_RELEASE_SIGNING=1`). After each CI APK build, `apksigner verify --print-certs` must match the pinned SHA-256 in [`android/release-cert.sha256`](../../../android/release-cert.sha256) (public certificate identity, not derived from the JKS under test). Never commit the keystore or passwords. Play upload keystore / AAB remain later work.
- **Windows:** Inno Setup installer is the primary artifact; a portable zip of the Flutter `Release\` folder (exe + DLLs + `data/`) is also attached. No lone naked `.exe`.
- Linux `.deb` / `.tar.gz`. The `.deb` installs `/usr/share/icons/hicolor/256x256/apps/ayutam.png` so `Icon=ayutam` in the desktop entry resolves; package description covers shipped Phases 0–4 only (no `.skilltracker` backups until Phase 5).
- **Source:** GitHub’s automatic source zip/tarball on each release — no extra job.

## Consequences

Users can install from Releases after each phase version bump. Phase 8 still owns Play/Microsoft store packaging, MSIX, AAB, and the optional in-app update check (F-023). The packaging exit criterion stays unchecked until a real Release run proves clean install + Android upgrade with data preserved. Fedora/RHEL users unpack the Linux tarball.
