# Platform build & launch smoke testing

**Status:** Authoritative verification procedure
**Audience:** Coding agents and humans verifying a phase on real platforms
**Related:** [`testing-strategy.md`](testing-strategy.md), [`../plan/execution-plan.md`](../plan/execution-plan.md)

## Purpose and policy

After completing **each phase** of the execution plan, verify the app on all three
supported platforms before checking the phase's exit criteria:

1. `flutter analyze` — zero issues.
2. `flutter test` — all tests pass.
3. **Build & launch smoke** on each platform: Android (emulator), Windows, Linux (WSL).
   A smoke passes when the app builds, launches, and the process is **still alive
   after ~5–8 seconds**, then is stopped cleanly. No UI automation is required.
4. Record the evidence (date + per-platform marker) in the phase's notes block in
   [`../plan/execution-plan.md`](../plan/execution-plan.md), using the evidence-table
   style established in the Phase 0 notes.

The paths below are the exact ones used on the reference development machine
(Windows 11 host). On another machine, substitute your own SDK locations — the
structure of the procedure is identical.

## Prerequisites per platform

### Common

- Flutter SDK (stable channel) on the Windows host: `C:\flutter` (`C:\flutter\bin` on `PATH`).
- Repository at `C:\Project\Ayutam`.
- Run `flutter pub get` before the first build.

### Windows desktop

- Visual Studio 2022 (Community is fine) with the **Desktop development with C++**
  workload; `vcvars64.bat` must exist under
  `C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\`.
- **Windows Developer Mode enabled** (Settings → System → For developers).
  Flutter creates symlinks for plugins; without Developer Mode the build fails
  asking for elevation.
- Use the helper `tool\win_build.bat` instead of calling `flutter build windows`
  directly — see [Troubleshooting](#troubleshooting) for why (`__COMPAT_LAYER=RunAsInvoker`).

### Android (emulator)

- Android SDK at `%LOCALAPPDATA%\Android\Sdk` (cmdline-tools installed; `sdkmanager`
  and `avdmanager` under `cmdline-tools\latest\bin`).
- Portable JDK 17 at `%LOCALAPPDATA%\Java\jdk-17.0.19+10`. `sdkmanager` and Gradle
  need `JAVA_HOME` pointing at it and its `bin` on `PATH`.
- An x86_64 API 34 AVD named `ayutam_api34`. One-time creation:

  ```powershell
  $sdk = "$env:LOCALAPPDATA\Android\Sdk"
  $env:JAVA_HOME = "$env:LOCALAPPDATA\Java\jdk-17.0.19+10"
  $env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
  & "$sdk\cmdline-tools\latest\bin\sdkmanager.bat" "system-images;android-34;google_apis;x86_64" "platforms;android-34" "platform-tools" "emulator"
  & "$sdk\cmdline-tools\latest\bin\avdmanager.bat" create avd -n ayutam_api34 -k "system-images;android-34;google_apis;x86_64" -d pixel_7
  ```

### Linux (WSL2 Ubuntu + WSLg)

- WSL2 distro `Ubuntu` with a sudo-capable user (reference machine: `abr`) and WSLg
  (GUI support — default on Windows 11).
- Linux-native Flutter at `~/flutter` inside WSL plus GTK build dependencies.
  One-time setup is scripted — run [`tool/wsl_setup_flutter.sh`](../../tool/wsl_setup_flutter.sh)
  inside WSL; it installs apt packages (clang, cmake, ninja, GTK3 headers, …),
  clones Flutter stable into `~/flutter`, and prints `WSL_FLUTTER_SETUP_DONE`.
- The Linux build reuses the Windows checkout via `/mnt/c/Project/Ayutam`
  (no separate clone needed).

## Step-by-step smoke procedure

All commands assume PowerShell on the Windows host, repo root `C:\Project\Ayutam`.

### 0. Static checks (once, before any platform build)

```powershell
flutter analyze   # expect: "No issues found!"
flutter test      # expect: "All tests passed!"
```

### 1. Windows

```powershell
# Build (wraps vcvars64 + __COMPAT_LAYER=RunAsInvoker + flutter build windows)
cmd /c tool\win_build.bat --debug
# expect: "√ Built build\windows\x64\runner\Debug\ayutam.exe"

# Launch smoke: start, wait ~7 s, verify alive, stop
$exe = "build\windows\x64\runner\Debug\ayutam.exe"
$p = Start-Process -FilePath $exe -PassThru
Start-Sleep -Seconds 7
if (Get-Process -Id $p.Id -ErrorAction SilentlyContinue) {
  "WIN_SMOKE_OK"; Stop-Process -Id $p.Id -Force
} else { "WIN_SMOKE_FAIL" }
```

**Success marker:** `WIN_SMOKE_OK` (process alive after 7 s).

### 2. Android (emulator)

```powershell
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$adb = "$sdk\platform-tools\adb.exe"
$env:JAVA_HOME = "$env:LOCALAPPDATA\Java\jdk-17.0.19+10"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"

# 2a. Start the emulator (background; boot takes 2–5 min cold)
Start-Process "$sdk\emulator\emulator.exe" -ArgumentList `
  "-avd","ayutam_api34","-no-snapshot-save","-no-boot-anim","-gpu","swiftshader_indirect"

# 2b. Poll until booted: `adb devices` shows "device" (not "offline"), then
#     `adb shell getprop sys.boot_completed` prints 1
& $adb devices
& $adb shell getprop sys.boot_completed   # repeat until it prints: 1

# 2c. Build, install, launch (Gradle assembleDebug: ~9 min cold, ~1–2 min warm)
flutter build apk --debug
& $adb install -r build\app\outputs\flutter-apk\app-debug.apk
& $adb shell am start -n com.ayutam.ayutam/.MainActivity
Start-Sleep -Seconds 5
& $adb shell pidof com.ayutam.ayutam   # a PID printed = ANDROID_SMOKE_OK

# 2d. Cleanup
& $adb shell am force-stop com.ayutam.ayutam
& $adb emu kill
```

**Success marker:** `pidof com.ayutam.ayutam` returns a PID ~5 s after launch
(`ANDROID_SMOKE_OK`).

### 3. Linux (WSL)

The whole build + smoke is scripted in
[`tool/wsl_build_linux.sh`](../../tool/wsl_build_linux.sh) (pub get, `flutter build
linux --debug`, 5-second GUI launch under WSLg, kill). Copy it into the WSL home
first and strip CRLF line endings (see Troubleshooting):

```powershell
wsl -d Ubuntu -u abr -- bash -lc "cp /mnt/c/Project/Ayutam/tool/wsl_build_linux.sh ~/b.sh && chmod +x ~/b.sh && sed -i 's/\r$//' ~/b.sh && ~/b.sh"
```

**Success marker:** the script prints `LINUX_SMOKE_RUNNING pid=<n>` followed by
`LINUX_SMOKE_OK`. Failure markers: `LINUX_SMOKE_EXITED_EARLY` (with the app log)
or `LINUX_BINARY_MISSING`.

> **Note:** the script runs the Linux Flutter's `flutter pub get` against the shared
> checkout, which rewrites `.dart_tool/package_config.json` with Linux paths. After
> the Linux smoke, run `flutter pub get` **on the Windows host** to restore the tree
> for subsequent Windows/Android work.

## Troubleshooting (real pitfalls hit on the reference machine)

| Symptom | Cause | Fix |
|---|---|---|
| Windows build fails: MSVC `cl.exe` "requires elevation" / `The requested operation requires elevation` | A bogus `RUNASADMIN` AppCompat shim on `cl.exe` under `HKLM\...\AppCompatFlags\Layers` forced every compiler invocation to demand admin | Remove the registry shim, and belt-and-braces set `__COMPAT_LAYER=RunAsInvoker` in the build shell. `tool\win_build.bat` sets it automatically — always build Windows through it |
| Windows build fails creating plugin symlinks ("requires elevation" on `flutter build windows` itself) | Flutter symlinks plugins into `windows\flutter\ephemeral`; symlink creation needs privilege | Enable **Windows Developer Mode** (Settings → System → For developers) |
| `sdkmanager` fails immediately (`Could not determine java version` / JAVA_HOME errors) | cmdline-tools need JDK 17 | Set `JAVA_HOME` to the JDK 17 install and put `%JAVA_HOME%\bin` first on `PATH` before running `sdkmanager`/Gradle |
| `adb install` fails / device `offline` right after emulator start | Emulator not finished booting | Poll: wait for `adb devices` to report `device`, then for `adb shell getprop sys.boot_completed` to print `1` (2–5 min cold boot) |
| WSL script fails with `$'\r': command not found` or `bad interpreter` | Shell script picked up CRLF line endings from the Windows checkout | After copying into WSL, run `sed -i 's/\r$//' script.sh` before executing (the one-liner above does this) |
| Windows `flutter` commands fail after a WSL Linux build (package resolution errors) | Linux `flutter pub get` rewrote `.dart_tool` with Linux paths | Re-run `flutter pub get` on the Windows host |
| Gradle first build extremely slow (~9 min) | Cold Gradle/AGP caches | Expected once; warm builds take ~1–2 min. Don't kill it prematurely |

## Phase-notes checklist template

Paste into the phase notes block of `docs/plan/execution-plan.md` and fill in:

```markdown
Platform smoke (<YYYY-MM-DD>, see docs/testing/platform-smoke.md):

| Check | Result |
|---|---|
| `flutter analyze` | ☐ No issues |
| `flutter test` | ☐ All N tests passed |
| **Windows** build + launch | ☐ `WIN_SMOKE_OK` |
| **Android** build + launch (emulator `ayutam_api34`) | ☐ `pidof` returned PID (`ANDROID_SMOKE_OK`) |
| **Linux** build + launch (WSL) | ☐ `LINUX_SMOKE_OK` |

Defects found / fixes applied: <none | list>
```
