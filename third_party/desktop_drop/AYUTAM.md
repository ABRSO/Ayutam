# Vendored `desktop_drop` 0.8.2

Upstream: https://github.com/MixinNetwork/flutter-plugins/tree/main/packages/desktop_drop (MIT)

**Why vendored:** Host uses AGP 9 with `android.builtInKotlin=false` (Flutter template). Upstream `android/build.gradle` skips `kotlin-android` when AGP ≥ 9 but still evaluates a `kotlin { }` block, which fails Android builds. This copy applies KGP when built-in Kotlin is disabled and guards the `kotlin { }` DSL.

**Windows patch (`windows/desktop_drop_plugin.cpp`):** Upstream `DragEnter` / `DragOver` / `Drop` return `S_OK` without writing `*pdwEffect`, so the drag source's full effect mask (copy | move | link) is echoed back and Explorer may treat the drop as a move. Ayutam only reads dropped backups, so the target reports `DROPEFFECT_COPY` for file (`CF_HDROP`) drags and `DROPEFFECT_NONE` for anything else.

Remove this path dependency once upstream publishes an AGP 9-compatible release that also sets the drop effect.
