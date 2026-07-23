# Contributing

Thanks for interest in Ayutam.

## Before you start

1. Read [`AGENTS.md`](AGENTS.md) and [`docs/README.md`](docs/README.md).
2. Follow [`docs/plan/execution-plan.md`](docs/plan/execution-plan.md) phase order.
3. Do not add backends, accounts, analytics, ads, or automatic cloud sync.

## Development

To install toolchains and run the app locally (manual UI checks), follow
[`docs/dev/build-and-run.md`](docs/dev/build-and-run.md).

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format .
flutter analyze
flutter test
```

After completing an execution-plan phase, also run the per-platform build + launch
smoke on Android, Windows, and Linux — see
[`docs/testing/platform-smoke.md`](docs/testing/platform-smoke.md).

## Pull requests and phase branches

Phase work uses short-lived branches off `main` (e.g. `cursor/phase-1-stopwatch-slice`):

1. Finish the phase (tests + [platform smokes](docs/testing/platform-smoke.md) + docs/`README.md` status).
2. Open a PR **into `main`**, wait for CI, merge.
3. Delete the phase branch; start the next phase from updated `main`.

Do not leave completed phases only on feature branches. Keep PRs focused and tested; update docs/ADRs when behavior, schema, or backup format changes. Use the checklist in `AGENTS.md` before claiming done.

### Dependabot PRs

Weekly version bumps target `main`. Review before merging:

- **GitHub Actions** major bumps are usually fine if CI is green; prefer merging upload-artifact and download-artifact updates close together because `release.yml` uses both.
- **Pub** bumps that look like `+eol`, remove native code, or fail `analyze`/`test` — **close** (or migrate properly in a dedicated change). Do not merge EOL stubs.

## CI/CD

| Workflow | Trigger | What it does |
|---|---|---|
| `validate.yml` | every push / PR | format, analyze, tests with coverage (summary + `coverage-lcov` artifact) |
| `security.yml` | PRs, main pushes, weekly | OSV-Scanner dependency CVE scan (`pubspec.lock`), gitleaks secret scan |
| `release.yml` | tag `v*` | verifies tag ↔ `pubspec.yaml` ↔ `CHANGELOG.md`, runs tests, builds Android APK + Windows zip + Linux tar.gz, publishes a GitHub Release |

Dependabot (`.github/dependabot.yml`) opens weekly PRs for pub packages and GitHub Actions versions.

### Cutting a release

1. Bump `version:` in `pubspec.yaml` (e.g. `0.2.0+2`).
2. In `CHANGELOG.md`, rename `## [Unreleased]` to `## [0.2.0]` (add a fresh `## [Unreleased]` above it).
3. Commit, then tag and push:

   ```bash
   git tag v0.2.0
   git push origin v0.2.0
   ```

The release workflow fails fast if the tag, pubspec version, and changelog section disagree. Android artifacts are **debug-signed** for now — set up a release keystore before any store distribution.
