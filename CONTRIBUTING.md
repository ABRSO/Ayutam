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
