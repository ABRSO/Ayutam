# Contributing

Thanks for interest in Ayutam.

## Before you start

1. Read [`AGENTS.md`](AGENTS.md) and [`docs/README.md`](docs/README.md).
2. Follow [`docs/plan/execution-plan.md`](docs/plan/execution-plan.md) phase order.
3. Do not add backends, accounts, analytics, ads, or automatic cloud sync.

## Development

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format .
flutter analyze
flutter test
```

## Pull requests

- Keep changes focused and tested.
- Update docs/ADRs when behavior, schema, or backup format changes.
- Use the checklist in `AGENTS.md` before claiming done.

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
