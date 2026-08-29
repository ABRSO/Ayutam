# Vendored `desktop_drop` 0.8.2

Upstream: https://github.com/MixinNetwork/flutter-plugins/tree/main/packages/desktop_drop (MIT)

**Why vendored:** Host uses AGP 9 with `android.builtInKotlin=false` (Flutter template). Upstream `android/build.gradle` skips `kotlin-android` when AGP ≥ 9 but still evaluates a `kotlin { }` block, which fails Android builds. This copy applies KGP when built-in Kotlin is disabled and guards the `kotlin { }` DSL.

Remove this path dependency once upstream publishes an AGP 9-compatible release.
