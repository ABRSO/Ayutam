# Build, install, and run Ayutam

**Audience:** Humans setting up a machine from scratch and running the app for development or manual UI checks.  
**Related:** Agents verifying a phase should also follow [`../testing/platform-smoke.md`](../testing/platform-smoke.md).

Ayutam is a Flutter app for **Windows**, **Android**, and **Linux**. There is no store “download and install” flow yet — you build from source (or use a [GitHub Release](https://github.com/ABRSO/Ayutam/releases) artifact when one exists).

This guide is written so someone who has never installed Flutter/Android/Linux desktop toolchains can follow it end-to-end. Paths marked **(reference)** are from the project’s Windows 11 development machine; on your PC, substitute your own locations but keep the same structure.

| Platform | Section |
|---|---|
| Flutter + clone (all hosts) | [§1](#1-common-prerequisites-all-hosts) |
| Windows desktop | [§2](#2-windows-desktop) |
| Android (JDK, SDK, emulator, phone) | [§3](#3-android-emulator-or-phone) |
| Linux via WSL2 + WSLg (on Windows) | [§4](#4-linux-via-wsl2--wslg-on-windows) |
| Native Linux (Ubuntu/Debian-style host) | [§5](#5-native-linux-ubuntu--debian-style) |
| Manual UI checklist | [§6](#6-suggested-manual-ui-checklist) |
| Cheat sheet | [§7](#7-quick-command-cheat-sheet) |

---

## 1. Common prerequisites (all hosts)

### 1.1 Install Git

- **Windows:** [Git for Windows](https://git-scm.com/download/win) (includes Git Bash).
- **Linux:** `sudo apt install git` (Debian/Ubuntu) or your distro’s equivalent.

Confirm:

```bash
git --version
```

### 1.2 Install Flutter (stable)

Official docs: [Install Flutter](https://docs.flutter.dev/get-started/install).

**Windows (reference):**

1. Download the **stable** Flutter SDK zip from the Flutter site.
2. Extract to a short path **without spaces**, e.g. `C:\flutter` (not under `Program Files`).
3. Add `C:\flutter\bin` to your **user** `PATH`:
   - Settings → System → About → Advanced system settings → Environment Variables → User `Path` → New → `C:\flutter\bin`
4. Close and reopen all terminals (PATH changes only apply to new sessions).

**Linux (native or inside WSL):**

```bash
cd ~
git clone https://github.com/flutter/flutter.git -b stable --depth 1
# Persist on PATH (bash):
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Confirm on every host:

```bash
flutter --version          # should say "stable" channel
flutter doctor
```

Enable desktop targets you will use:

```bash
flutter config --enable-windows-desktop   # Windows host only
flutter config --enable-linux-desktop     # Linux host or WSL
```

`flutter doctor` will show missing pieces (Android toolchain, VS, Linux GTK, etc.). Use the platform sections below to clear those.

### 1.3 Clone the repository and fetch packages

```bash
# Windows example:
cd C:\Project
git clone https://github.com/ABRSO/Ayutam.git
cd Ayutam

# Linux example:
# cd ~/src && git clone https://github.com/ABRSO/Ayutam.git && cd Ayutam

git checkout main
git pull
flutter pub get
```

After Drift schema / code-generation changes (or if `*.g.dart` files are missing):

```bash
dart run build_runner build --delete-conflicting-outputs
```

Sanity checks (run on the host that owns this checkout):

```bash
flutter analyze
flutter test
```

---

## 2. Windows desktop

### 2.1 Prerequisites

| Requirement | How to install / verify |
|---|---|
| Windows 10/11 64-bit | — |
| **Developer Mode** | Settings → System → For developers → **Developer Mode** **On**. Required so Flutter can create plugin symlinks. |
| **Visual Studio 2022** | [Download VS 2022](https://visualstudio.microsoft.com/downloads/) Community is fine. In the installer, select workload **Desktop development with C++** (MSVC, Windows 10/11 SDK, CMake tools). |
| Flutter | [§1.2](#12-install-flutter-stable) |

Confirm MSVC helper exists (Community path; Enterprise/Professional differ only by edition folder):

```text
C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat
```

```powershell
flutter doctor
# Windows toolchain should be OK (warnings about Android/Chrome are fine if you are only building Windows).
```

### 2.2 Run interactively (best for UI checks)

```powershell
cd C:\Project\Ayutam
flutter run -d windows
```

Hot reload: press `r` in the terminal. Quit: `q` or close the window.

### 2.3 Build a standalone `.exe`

Prefer the helper (loads `vcvars64` and sets `__COMPAT_LAYER=RunAsInvoker` to avoid a known MSVC elevation shim issue):

```powershell
cmd /c tool\win_build.bat --debug
# or: cmd /c tool\win_build.bat --release
```

| Build | Output |
|---|---|
| Debug | `build\windows\x64\runner\Debug\ayutam.exe` |
| Release | `build\windows\x64\runner\Release\ayutam.exe` |

```powershell
Start-Process .\build\windows\x64\runner\Debug\ayutam.exe
```

If you copy the binary elsewhere, copy the **whole** `runner\Debug` or `runner\Release` folder (Flutter assets sit beside the exe).

### 2.4 Windows troubleshooting

- Symlink / “cannot create link” / elevation prompts → enable **Developer Mode**, new terminal, retry.
- `cl.exe` “requires elevation” → use `tool\win_build.bat`. See [`platform-smoke.md` troubleshooting](../testing/platform-smoke.md#troubleshooting).
- Build fails because `ayutam.exe` is locked → close every running Ayutam window, then rebuild.

---

## 3. Android (emulator or phone)

Goal: install **JDK 17**, the **Android SDK** (command-line tools + platform-tools + emulator + a system image), create an **AVD**, set **environment variables**, then `flutter run` or install an APK.

You can do this with **Android Studio** (easier UI) or **command-line tools only**. Both are covered. Examples below are for **Windows**; Linux hosts use the same package names with `.sh` scripts and `$HOME` paths.

### 3.1 Install JDK 17

Flutter’s Android Gradle builds and `sdkmanager` expect **JDK 17** (not 21 as the only JDK unless you know it works with your Android Gradle Plugin; 17 is the safe choice).

**Option A — Eclipse Temurin (recommended)**

1. Download **Temurin 17 (JDK)** for your OS from [Adoptium](https://adoptium.net/).
2. Windows: run the MSI **or** unzip a portable build under e.g.  
   `%LOCALAPPDATA%\Java\jdk-17.0.x+y`  
   **(reference)** `%LOCALAPPDATA%\Java\jdk-17.0.19+10`
3. Linux:

   ```bash
   sudo apt install openjdk-17-jdk
   # or install a Temurin .deb / tarball under $HOME/Java/...
   ```

Confirm:

```powershell
# Windows (after JAVA_HOME is set — see §3.3)
& "$env:JAVA_HOME\bin\java.exe" -version
# Expect: openjdk version "17.…"
```

```bash
# Linux
java -version
# Expect 17.x
```

### 3.2 Install the Android SDK

#### Option A — Android Studio (easiest)

1. Install [Android Studio](https://developer.android.com/studio).
2. First-run wizard: install **Android SDK**, **Android SDK Platform**, **Android Virtual Device**.
3. **Settings → Languages & Frameworks → Android SDK**:
   - **SDK Platforms** tab: check **Android 14.0 (API 34)** (or newer; API 34 matches the reference AVD).
   - **SDK Tools** tab: check  
     - Android SDK Build-Tools  
     - Android SDK Command-line Tools (latest)  
     - Android Emulator  
     - Android SDK Platform-Tools  
     - (optional) Intel x86 Emulator Accelerator / Android Emulator Hypervisor Driver on Windows
4. Note **Android SDK Location** (Windows default: `%LOCALAPPDATA%\Android\Sdk`).

#### Option B — Command-line tools only (no full Android Studio IDE)

1. Download **Command line tools only** from [Android Studio download extras](https://developer.android.com/studio#command-line-tools-only).
2. Create the SDK root and unpack so that `sdkmanager` lives under `cmdline-tools\latest\bin`:

   **Windows:**

   ```powershell
   $sdk = "$env:LOCALAPPDATA\Android\Sdk"
   New-Item -ItemType Directory -Force -Path "$sdk\cmdline-tools" | Out-Null
   # Unzip the Google zip so you have a folder like cmdline-tools\cmdline-tools\...
   # Then rename/move that inner folder to:
   #   $sdk\cmdline-tools\latest
   # Final path must be:
   #   $sdk\cmdline-tools\latest\bin\sdkmanager.bat
   ```

   **Linux:**

   ```bash
   mkdir -p "$HOME/Android/Sdk/cmdline-tools"
   # unzip → move contents to $HOME/Android/Sdk/cmdline-tools/latest
   # Final: $HOME/Android/Sdk/cmdline-tools/latest/bin/sdkmanager
   ```

3. Install packages with `sdkmanager` (after `JAVA_HOME` is set — §3.3):

   ```powershell
   # Windows
   $sdk = "$env:LOCALAPPDATA\Android\Sdk"
   & "$sdk\cmdline-tools\latest\bin\sdkmanager.bat" --sdk_root=$sdk `
     "platform-tools" `
     "emulator" `
     "platforms;android-34" `
     "build-tools;34.0.0" `
     "system-images;android-34;google_apis;x86_64"
   ```

   ```bash
   # Linux
   sdk="$HOME/Android/Sdk"
   yes | "$sdk/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$sdk" \
     platform-tools emulator \
     "platforms;android-34" \
     "build-tools;34.0.0" \
     "system-images;android-34;google_apis;x86_64"
   ```

### 3.3 Environment variables (required)

Set these as **user** environment variables so every new terminal sees them.

| Variable | Windows example (reference) | Linux example |
|---|---|---|
| `JAVA_HOME` | `C:\Users\<you>\AppData\Local\Java\jdk-17.0.19+10` | `/usr/lib/jvm/java-17-openjdk-amd64` or `$HOME/Java/jdk-17…` |
| `ANDROID_HOME` | `C:\Users\<you>\AppData\Local\Android\Sdk` | `$HOME/Android/Sdk` |
| `ANDROID_SDK_ROOT` | same as `ANDROID_HOME` | same as `ANDROID_HOME` |

Also append to **user `Path` / `PATH`:**

- `%JAVA_HOME%\bin` / `$JAVA_HOME/bin`
- `%ANDROID_HOME%\platform-tools` / `$ANDROID_HOME/platform-tools`
- `%ANDROID_HOME%\emulator` / `$ANDROID_HOME/emulator`
- `%ANDROID_HOME%\cmdline-tools\latest\bin` / `$ANDROID_HOME/cmdline-tools/latest/bin`

**Windows UI:** Settings → System → About → Advanced system settings → Environment Variables → User variables.

**Windows PowerShell (current session only, for a quick test):**

```powershell
$env:JAVA_HOME = "$env:LOCALAPPDATA\Java\jdk-17.0.19+10"   # adjust version folder
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:PATH = "$env:JAVA_HOME\bin;$env:ANDROID_HOME\platform-tools;$env:ANDROID_HOME\emulator;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:PATH"
```

**Linux (`~/.bashrc`):**

```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64   # adjust
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
```

Open a **new** terminal and verify:

```powershell
java -version
sdkmanager --version
adb version
flutter doctor
```

Accept Android licenses once:

```bash
flutter doctor --android-licenses
# Press y for each prompt
```

`flutter doctor` should show the Android toolchain as installed (or only minor notes).

### 3.4 Create an emulator (AVD)

**Reference AVD name:** `ayutam_api34` — API 34, `google_apis`, x86_64, Pixel 7 profile.

#### Via Android Studio

1. **Device Manager** (phone icon) → **Create Device**.
2. Pick **Pixel 7** (or similar) → Next.
3. Select a **system image** with API **34** and **Google APIs** (x86_64 or x86_64 Google Play). Download if needed → Finish.
4. You may rename the AVD to `ayutam_api34` in the AVD’s edit dialog for consistency with this doc.

#### Via command line

```powershell
# Windows — JAVA_HOME / ANDROID_HOME already set
$sdk = $env:ANDROID_HOME
& "$sdk\cmdline-tools\latest\bin\sdkmanager.bat" --sdk_root=$sdk `
  "system-images;android-34;google_apis;x86_64" `
  "platforms;android-34" "platform-tools" "emulator"

echo no | & "$sdk\cmdline-tools\latest\bin\avdmanager.bat" create avd `
  -n ayutam_api34 `
  -k "system-images;android-34;google_apis;x86_64" `
  -d pixel_7
```

```bash
# Linux
yes | sdkmanager --sdk_root="$ANDROID_HOME" \
  "system-images;android-34;google_apis;x86_64" \
  "platforms;android-34" platform-tools emulator
echo no | avdmanager create avd \
  -n ayutam_api34 \
  -k "system-images;android-34;google_apis;x86_64" \
  -d pixel_7
```

List AVDs:

```bash
emulator -list-avds
# expect: ayutam_api34
```

### 3.5 Start the emulator and wait until it is ready

```powershell
# Windows
$sdk = $env:ANDROID_HOME
# Start in a separate window; keep it running
Start-Process -FilePath "$sdk\emulator\emulator.exe" `
  -ArgumentList "-avd","ayutam_api34","-gpu","swiftshader_indirect"

# Wait until adb reports "device" and boot completed
adb wait-for-device
do {
  Start-Sleep -Seconds 3
  $boot = (adb shell getprop sys.boot_completed).Trim()
  Write-Host "boot_completed=$boot"
} while ($boot -ne "1")
adb devices
# expect a line like: emulator-5554    device
```

```bash
# Linux
emulator -avd ayutam_api34 -gpu swiftshader_indirect &
adb wait-for-device
until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
  sleep 3
  echo "waiting for boot..."
done
adb devices
```

Notes:

- First boot can take several minutes.
- If the device stays **`offline`**, wait longer, or run `adb kill-server` then `adb start-server`, then `adb devices` again.
- `-gpu swiftshader_indirect` is a reliable software renderer; if you have a working host GPU acceleration you can omit it or use `-gpu auto`.

### 3.6 Run Ayutam on the emulator

From the repo root (Flutter on this same machine):

```bash
cd /path/to/Ayutam
flutter pub get
flutter devices
# Note the emulator id, often emulator-5554
flutter run -d emulator-5554
```

### 3.7 Build an APK and install with adb

```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk   (Windows: build\app\outputs\...)

adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.ayutam.ayutam/.MainActivity
```

Confirm the process:

```bash
adb shell pidof com.ayutam.ayutam
# prints a PID if running
```

Stop the app / emulator when finished:

```bash
adb shell am force-stop com.ayutam.ayutam
adb emu kill          # if using the emulator
```

Release APK (still debug-signed until a release keystore is configured for store builds):

```bash
flutter build apk --release
```

### 3.8 Physical phone

1. On the phone: **Settings → About phone** → tap **Build number** seven times to enable Developer options.
2. **Settings → Developer options** → enable **USB debugging** (and **Install via USB** on some OEMs).
3. Connect USB; accept the “Allow USB debugging?” prompt.
4. `adb devices` should list the phone as `device`.
5. `flutter devices` then `flutter run`, or `adb install -r` the APK as above.

Wireless debugging is optional (Android 11+); use Android Studio’s Device Manager docs if you prefer Wi‑Fi.

#### Xiaomi / Redmi / POCO (HyperOS / MIUI)

`adb install` often fails with **`INSTALL_FAILED_USER_RESTRICTED`** even when USB debugging is on. In **Developer options** also enable:

- **Install via USB**
- **USB debugging (Security settings)** (wording varies)

These toggles may require a **Mi / Xiaomi account** and sometimes a **SIM** inserted. If `adb` still refuses installs, copy the APK to the phone (USB file transfer, Drive, etc.) and open it with the system package installer as a fallback.

### 3.9 Debug vs release APK size and performance

| Build | Typical size | Feel |
|---|---|---|
| `flutter build apk --debug` / `flutter run` | **~150+ MB** (all ABIs + JIT/debug symbols) | Visibly janky; New Skill sheet lag is expected |
| `flutter build apk --release --split-per-abi` | **~10–25 MB per ABI** | Use this for real-device evaluation (e.g. POCO F5) |

```bash
flutter build apk --release --split-per-abi
# → build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
# → build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# → build/app/outputs/flutter-apk/app-x86_64-release.apk
```

Install the ABI that matches the device (`arm64-v8a` for most modern phones):

```bash
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Notes:

- Android Settings “App info → User data / cache” on a **debug** install is mostly **JIT cache**, not SQLite content. Real practice data stays small.
- Profile performance only with **`--profile`** or **`--release`** builds — never judge lag from a debug APK alone.

### 3.10 Android troubleshooting

| Symptom | Likely fix |
|---|---|
| `sdkmanager` / Gradle “invalid or corrupt jdk” / class version errors | `JAVA_HOME` must point at **JDK 17**, not 8/11/21-only installs without config |
| `cmdline-tools` not found | Unpack so path ends in `cmdline-tools/latest/bin/sdkmanager` |
| `flutter doctor` cannot find Android SDK | Set `ANDROID_HOME` / `ANDROID_SDK_ROOT` and restart the terminal |
| Emulator `offline` forever | Wait for boot; `adb kill-server` / `adb start-server`; cold boot AVD from Device Manager |
| Emulator won’t start (hypervisor) | Enable virtualization in BIOS; on Windows install “Windows Hypervisor Platform” / WHPX, or use a software GPU flag |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | `adb uninstall com.ayutam.ayutam` then reinstall |
| `INSTALL_FAILED_USER_RESTRICTED` (Xiaomi / HyperOS) | Enable **Install via USB** + **USB debugging (Security settings)**; see [§3.8](#38-physical-phone); or sideload the APK manually |
| After building Linux in WSL against a Windows checkout | Run `flutter pub get` again on Windows (`.dart_tool` may have Linux paths) |

---

## 4. Linux via WSL2 + WSLg (on Windows)

Use this when your daily driver is **Windows** but you want a **Linux desktop** build. GUI windows appear on the Windows desktop via **WSLg** (Windows 11).

### 4.1 Install WSL2 and Ubuntu

In an elevated PowerShell:

```powershell
wsl --install
# Or explicitly:
# wsl --install -d Ubuntu
```

Reboot if prompted. Create your Linux username/password on first launch.

Confirm:

```powershell
wsl -l -v
# Ubuntu should show VERSION 2
```

WSLg: on Windows 11, Linux GUI apps should open as normal windows. Test inside Ubuntu:

```bash
sudo apt update
sudo apt install -y x11-apps
xclock    # should open a small clock window on the Windows desktop
```

### 4.2 One-time Flutter + build dependencies inside WSL

From **Windows PowerShell** (adjust user and repo path):

```powershell
wsl -d Ubuntu -u <your-linux-user> -- bash -lc "sed -i 's/\r$//' /mnt/c/Project/Ayutam/tool/wsl_setup_flutter.sh && bash /mnt/c/Project/Ayutam/tool/wsl_setup_flutter.sh"
```

Or open an Ubuntu shell and run:

```bash
# Strip Windows CRLF if you copy scripts from the NTFS mount
sed -i 's/\r$//' /mnt/c/Project/Ayutam/tool/wsl_setup_flutter.sh
bash /mnt/c/Project/Ayutam/tool/wsl_setup_flutter.sh
```

What the script does ([`tool/wsl_setup_flutter.sh`](../../tool/wsl_setup_flutter.sh)):

- `apt install` clang, cmake, ninja, pkg-config, GTK3 headers, mesa utils, curl, git, unzip, …
- Clones Flutter stable into `~/flutter` if missing
- Enables Linux desktop and prints `WSL_FLUTTER_SETUP_DONE`

Persist Flutter on PATH in WSL:

```bash
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
flutter doctor
```

### 4.3 Build and run (shared Windows checkout)

The Windows clone is visible in WSL as `/mnt/c/Project/Ayutam` (adjust drive/path).

**Quick smoke (from Windows PowerShell):**

```powershell
wsl -d Ubuntu -u <your-linux-user> -- bash -lc "cp /mnt/c/Project/Ayutam/tool/wsl_build_linux.sh ~/b.sh && chmod +x ~/b.sh && sed -i 's/\r$//' ~/b.sh && ~/b.sh"
```

Expect `LINUX_SMOKE_OK`. The helper builds debug Linux and launches the GUI for ~5 seconds.

**Interactive session (inside Ubuntu):**

```bash
export PATH="$HOME/flutter/bin:$PATH"
export DISPLAY="${DISPLAY:-:0}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/mnt/wslg/runtime-dir}"

cd /mnt/c/Project/Ayutam
flutter pub get
flutter run -d linux
```

Debug binary:

`build/linux/x64/debug/bundle/ayutam`

### 4.4 After WSL builds — important for Windows Flutter

Linux `flutter pub get` against the shared checkout rewrites `.dart_tool` with **Linux** paths. Back on Windows:

```powershell
cd C:\Project\Ayutam
flutter pub get
```

### 4.5 WSL troubleshooting

| Symptom | Fix |
|---|---|
| No GUI / `cannot open display` | Confirm Windows 11 WSLg; update WSL (`wsl --update`); set `DISPLAY` / `WAYLAND_DISPLAY` as above |
| `libgtk-3-dev` missing | Re-run `wsl_setup_flutter.sh` or `sudo apt install libgtk-3-dev` |
| Script fails with `$'\r': command not found` | `sed -i 's/\r$//' script.sh` before running |
| Extremely slow I/O on `/mnt/c` | Prefer cloning the repo into the Linux filesystem (`~/src/Ayutam`) for day-to-day Linux work |

---

## 5. Native Linux (Ubuntu / Debian-style)

Use this when the machine **is** Linux (dual-boot, VM, or dedicated box) — not WSL.

### 5.1 System packages

```bash
sudo apt update
sudo apt install -y \
  curl git unzip xz-utils zip \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev \
  libstdc++-12-dev \
  mesa-utils
```

(On newer Ubuntu, if `libstdc++-12-dev` is unavailable, install the `libstdc++-*-dev` package your release provides.)

Optional but useful: `build-essential`.

### 5.2 Flutter on Linux

```bash
cd ~
git clone https://github.com/flutter/flutter.git -b stable --depth 1
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

flutter config --enable-linux-desktop
flutter doctor
```

Resolve any doctor issues (often “cmdline-tools” only if you also want Android on this Linux box — follow [§3](#3-android-emulator-or-phone) with Linux paths).

### 5.3 Clone and run Ayutam

```bash
mkdir -p ~/src && cd ~/src
git clone https://github.com/ABRSO/Ayutam.git
cd Ayutam
git checkout main
git pull

flutter pub get
flutter analyze
flutter test

flutter devices
# should list a linux desktop device
flutter run -d linux
```

### 5.4 Build a Linux bundle

```bash
flutter build linux --debug
# → build/linux/x64/debug/bundle/ayutam

flutter build linux --release
# → build/linux/x64/release/bundle/ayutam
```

Run without `flutter run`:

```bash
./build/linux/x64/debug/bundle/ayutam
```

Ship the **entire** `bundle/` directory (not only the binary); it contains `lib/` and `data/`.

### 5.5 Native Linux troubleshooting

| Symptom | Fix |
|---|---|
| `PKG_CONFIG_PATH` / GTK errors | `sudo apt install libgtk-3-dev pkg-config` |
| Black window / GL issues | Update GPU drivers; try under X11 vs Wayland |
| `clang` not found | `sudo apt install clang` |
| Snap Flutter conflicts | Prefer the official git SDK under `~/flutter` as above, not a broken snap channel |

---

## 6. Suggested manual UI checklist

Use a build from current `main` (Phase 2+). If the timer shows plain large text like `00:09` with no digit cards and no “Current session …” line, you are on an **old binary** — pull and rebuild.

What the timer should look like:

- App bar: skill name (or “Stopwatch” briefly while loading).
- **Large flip clock:** separate digit cards, hinge through each digit, at least `HH:MM:SS`.
- Smaller monospace **Current session** line.
- **Skill total** vs session: the flip clock is cumulative skill practice; the mono line is this session only.
- Pause / Stop icon buttons at the bottom.

Checklist:

1. Home: create a skill → accent strip on the card.
2. Play → Start → flip cards tick; session line updates.
3. Pause / Resume / Stop work; desktop tooltips on hover.
4. **Reduced motion** is **OS-level** for now (no in-app Settings toggle yet):
   - Windows 11: Settings → Accessibility → Visual effects → **Animation effects** Off.
   - Android: Settings → Accessibility → Remove animations (wording varies).
   - Linux: reduce/disable animations in your desktop’s Accessibility settings when available.
5. Save session → Home total increases.
6. Second skill gets a different accent when possible.

---

## 7. Quick command cheat sheet

| Goal | Command |
|---|---|
| Windows interactive | `flutter run -d windows` |
| Windows debug exe | `cmd /c tool\win_build.bat --debug` |
| Android licenses | `flutter doctor --android-licenses` |
| Start Android emulator | `emulator -avd ayutam_api34` (then wait for `adb` `device`) |
| Android interactive | `flutter run -d emulator-5554` |
| Android APK (debug) | `flutter build apk --debug` then `adb install -r …` |
| Android APK (device eval) | `flutter build apk --release --split-per-abi` then install matching ABI |
| Linux interactive (native or WSL) | `flutter run -d linux` |
| Linux WSL smoke helper | `tool/wsl_build_linux.sh` via `wsl …` |
| Linux bundle | `flutter build linux --debug` |
| Analyze / tests | `flutter analyze` / `flutter test` |

Per-phase agent smoke markers (`WIN_SMOKE_OK`, etc.): [`platform-smoke.md`](../testing/platform-smoke.md).
