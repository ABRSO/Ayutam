# Build, install, and run Ayutam

**Audience:** Humans who want to try the app locally (manual UI checks, day-to-day development).  
**Related:** Agents verifying a phase should also follow [`../testing/platform-smoke.md`](../testing/platform-smoke.md).

Ayutam is a Flutter app for **Windows**, **Android**, and **Linux**. There is no store build yet for casual “download and install” — you build from source (or use a [GitHub Release](https://github.com/ABRSO/Ayutam/releases) artifact when one exists).

Paths below use the **reference Windows 11 machine** (`C:\flutter`, repo `C:\Project\Ayutam`). On another PC, substitute your locations.

---

## 1. Common prerequisites (all platforms)

### 1.1 Flutter stable

1. Install [Flutter](https://docs.flutter.dev/get-started/install) **stable** (reference: unzipped to `C:\flutter`).
2. Add Flutter’s `bin` directory to your user `PATH` (e.g. `C:\flutter\bin`).
3. Open a **new** terminal and check:

   ```powershell
   flutter --version
   flutter doctor
   ```

4. Enable desktop targets you need:

   ```powershell
   flutter config --enable-windows-desktop
   flutter config --enable-linux-desktop
   ```

### 1.2 Clone and fetch packages

```powershell
cd C:\Project\Ayutam   # or your clone path
git checkout main
git pull
flutter pub get
```

After Drift schema changes (or if generated files are missing):

```powershell
dart run build_runner build --delete-conflicting-outputs
```

Sanity checks:

```powershell
flutter analyze
flutter test
```

---

## 2. Windows desktop

### 2.1 Prerequisites

| Requirement | Notes |
|---|---|
| **Windows 10/11** | 64-bit |
| **[Developer Mode](ms-settings:developers)** | **Required.** Flutter creates plugin symlinks; without Developer Mode, Windows builds fail or ask for elevation. |
| **Visual Studio 2022** | Community is fine. Install workload **Desktop development with C++** (MSVC, Windows SDK, CMake). |
| Flutter | §1.1 |

Confirm:

```powershell
flutter doctor
# “Windows” toolchain should be OK (or only minor warnings).
```

### 2.2 Run (best for manual UI checks)

From the repo root:

```powershell
flutter run -d windows
```

Hot reload works in this mode. Stop with `q` in the terminal or close the window.

### 2.3 Build a standalone `.exe`

Prefer the helper (sets MSVC env + avoids a known elevation shim issue):

```powershell
cmd /c tool\win_build.bat --debug
```

Or release:

```powershell
cmd /c tool\win_build.bat --release
```

| Build | Output |
|---|---|
| Debug | `build\windows\x64\runner\Debug\ayutam.exe` |
| Release | `build\windows\x64\runner\Release\ayutam.exe` |

Double-click the exe, or:

```powershell
Start-Process .\build\windows\x64\runner\Debug\ayutam.exe
```

No separate installer is required for local testing; keep the whole `runner\Debug` / `Release` folder if you move the binary (Flutter assets live beside the exe).

### 2.4 Windows troubleshooting

- **Symlink / elevation errors:** turn on Developer Mode and retry.
- **`cl.exe` “requires elevation”:** use `tool\win_build.bat` (sets `__COMPAT_LAYER=RunAsInvoker`). Details in [`platform-smoke.md`](../testing/platform-smoke.md#troubleshooting).

---

## 3. Android (emulator or phone)

### 3.1 Prerequisites

| Requirement | Notes |
|---|---|
| **JDK 17** | Temurin/OpenJDK 17. Reference: `%LOCALAPPDATA%\Java\jdk-17.0.19+10`. Set `JAVA_HOME` and put `%JAVA_HOME%\bin` on `PATH`. |
| **Android SDK** | Reference: `%LOCALAPPDATA%\Android\Sdk`. Install **Android SDK Platform-Tools**, **Emulator**, a **platform** (e.g. API 34), and a **system image**. |
| **cmdline-tools** | So `sdkmanager` / `avdmanager` exist under `cmdline-tools\latest\bin`. |
| Flutter | §1.1; accept Android licenses when `flutter doctor` asks. |

Accept licenses (once):

```powershell
flutter doctor --android-licenses
```

### 3.2 One-time: create the reference emulator (optional)

```powershell
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$env:JAVA_HOME = "$env:LOCALAPPDATA\Java\jdk-17.0.19+10"   # adjust
$env:PATH = "$env:JAVA_HOME\bin;$sdk\platform-tools;$sdk\emulator;$env:PATH"

& "$sdk\cmdline-tools\latest\bin\sdkmanager.bat" `
  "system-images;android-34;google_apis;x86_64" `
  "platforms;android-34" "platform-tools" "emulator"

& "$sdk\cmdline-tools\latest\bin\avdmanager.bat" create avd `
  -n ayutam_api34 `
  -k "system-images;android-34;google_apis;x86_64" `
  -d pixel_7
```

Or create an AVD from **Android Studio → Device Manager**.

### 3.3 Run on emulator (interactive)

```powershell
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$env:PATH = "$sdk\platform-tools;$sdk\emulator;$env:PATH"

# Start emulator (wait until adb shows "device")
& "$sdk\emulator\emulator.exe" -avd ayutam_api34 -gpu swiftshader_indirect

# In another terminal, from repo root:
flutter devices
flutter run -d emulator-5554   # use the id from `flutter devices`
```

### 3.4 Build APK and install

```powershell
flutter build apk --debug
# → build\app\outputs\flutter-apk\app-debug.apk

adb install -r build\app\outputs\flutter-apk\app-debug.apk
adb shell am start -n com.ayutam.ayutam/.MainActivity
```

Release APK (still debug-signed until a release keystore is configured):

```powershell
flutter build apk --release
```

### 3.5 Physical phone

1. Enable **Developer options** → **USB debugging**.
2. Plug in USB; allow debugging prompt.
3. `flutter devices` should list the phone.
4. `flutter run` (or install the APK with `adb install -r …`).

### 3.6 Android troubleshooting

- **`sdkmanager` / Gradle fail:** `JAVA_HOME` must be JDK **17**.
- Emulator stuck **offline:** wait for boot, or `adb kill-server` / `adb start-server`, then retry.
- After WSL Linux builds against this checkout, run `flutter pub get` again on Windows (`.dart_tool` can be rewritten with Linux paths).

---

## 4. Linux (via WSL2 + WSLg on Windows)

Native Linux desktop from a Windows host is done through **WSL2 Ubuntu** with **WSLg** (GUI on Windows 11).

### 4.1 Prerequisites

1. Install WSL2 + Ubuntu (`wsl --install` or Microsoft Store).
2. Ensure WSLg works (GUI apps from Ubuntu appear on the Windows desktop).
3. One-time Flutter + apt deps inside WSL:

   ```powershell
   wsl -d Ubuntu -u <your-linux-user> -- bash -lc "sed -i 's/\r$//' /mnt/c/Project/Ayutam/tool/wsl_setup_flutter.sh && bash /mnt/c/Project/Ayutam/tool/wsl_setup_flutter.sh"
   ```

   Expect `WSL_FLUTTER_SETUP_DONE`. Adjust the `/mnt/c/...` path to your Windows clone.

### 4.2 Build and run (helper script)

```powershell
wsl -d Ubuntu -u <your-linux-user> -- bash -lc "cp /mnt/c/Project/Ayutam/tool/wsl_build_linux.sh ~/b.sh && chmod +x ~/b.sh && sed -i 's/\r$//' ~/b.sh && ~/b.sh"
```

That builds Linux debug, launches the GUI briefly for a smoke, then exits. For a longer manual session inside WSL:

```bash
export PATH="$HOME/flutter/bin:$PATH"
cd /mnt/c/Project/Ayutam
flutter pub get
flutter run -d linux
```

Binary path after `flutter build linux --debug`:

`build/linux/x64/debug/bundle/ayutam`

### 4.3 After WSL builds

Back on Windows:

```powershell
flutter pub get
```

---

## 5. Suggested manual UI checklist (current app)

**Important:** use a build from current `main` after Phase 2 (flip clock). If the timer
shows plain large text like `00:09` with no digit cards and no “Current session …”
line underneath, you are on an **old binary** — pull and rebuild (§1.2 + §2.2 / §3.3).

What Phase 2 **should** look like on the timer:

- App bar: skill name (or “Stopwatch” if skill metadata is still loading).
- **Large flip clock:** separate digit **cards** with a horizontal hinge line through
  each digit, colons between groups, format at least `HH:MM:SS` (e.g. `00:00:09`,
  not `00:09`). Digits flip when the second changes.
- Below that: a smaller monospace line `Current session  …`.
- Status: `Running` / `Paused`.
- Bottom: Pause and Stop icon buttons.

Checklist:

1. **Home:** create a skill → accent colour strip appears on the card.
2. **Play → Start:** immersive timer opens; confirm the **flip-card** clock above
   (not plain text); smaller mono line shows **current session**.
3. **Pause / Resume / Stop:** controls work; hover shows tooltips (desktop).
4. **Reduced motion (OS, not in-app yet):** there is **no** “Reduced motion” toggle
   in Ayutam Settings today (Appearance still says theme follows system). Use the
   **operating system** accessibility setting instead:

   - **Windows 11:** Settings → Accessibility → Visual effects → turn **Animation
     effects** **Off** (or Settings → Accessibility → Contrast themes / related
     motion options on your build). Restart or re-open the app, then run a session —
     digits should **change instantly** without a 3D flip.
   - **Android:** Settings → Accessibility → Remove animations (wording varies by OEM).
   - An in-app Settings toggle is planned with the fuller Appearance settings later;
     until then the flip widgets honour the platform “disable animations” flag.

5. **Save session:** return Home; skill total increases.
6. Create a second skill → accents differ when possible.

---

## 6. Quick command cheat sheet

| Goal | Command |
|---|---|
| Windows interactive | `flutter run -d windows` |
| Windows debug exe | `cmd /c tool\win_build.bat --debug` |
| Android interactive | start emulator → `flutter run` |
| Android APK | `flutter build apk --debug` then `adb install -r …` |
| Linux (WSL) interactive | `flutter run -d linux` (inside WSL) |
| Linux smoke helper | `tool/wsl_build_linux.sh` via `wsl …` |
| Analyze / unit tests | `flutter analyze` / `flutter test` |

Per-phase agent smoke markers (`WIN_SMOKE_OK`, etc.): [`platform-smoke.md`](../testing/platform-smoke.md).
