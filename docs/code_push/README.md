# Flutter OTA Code Push — Engine setup & builds

Code push for Dart isolate snapshots requires a **custom Flutter engine** built from this repository. Stock release engines ignore isolate snapshot override flags in release AOT mode.

| Topic | Document |
|-------|----------|
| **Line-by-line explanation of every code file** | [CODE_README.md](./CODE_README.md) |
|-------|----------|
| App plugin, patches, server API, troubleshooting | [packages/flutter_code_push/README.md](../../packages/flutter_code_push/README.md) |
| Engine contributing (deps, `gclient`) | [Setting up the Engine development environment](../engine/contributing/Setting-up-the-Engine-development-environment.md) |
| Full `gn` / `ninja` reference | [Compiling the engine](../engine/contributing/Compiling-the-engine.md) |
| Engine tool (`et`) | [engine/src/flutter/tools/engine_tool/README.md](../../engine/src/flutter/tools/engine_tool/README.md) |

**Supported OTA targets:** Android and iOS only (not desktop or web).

All commands below run from **`engine/src`** unless noted otherwise.

```bash
cd engine/src
```

---

## What the custom engine adds

| Layer | Role |
|-------|------|
| `engine/src/flutter/shell/common/switches.cc` | Honors `--isolate-snapshot-data` / `--isolate-snapshot-instr` when using bundled `libapp.so` |
| `engine/src/flutter/shell/common/code_push_config.h` | Shared directory and blob names (`code_push/active/`, etc.) |
| `engine/.../CodePushSnapshotResolver.java` + `FlutterLoader.java` | Android: resolve `active/` and pass shell flags |
| `engine/.../FlutterDartProject.mm` | iOS: set isolate snapshot paths from `Documents/code_push/active/` |

The VM and bundled `libapp.so` / `App.framework` stay in the store build; only the **application isolate** can be loaded from on-disk OTA blobs.

---

## Prerequisites

1. **This repo** checked out (engine is under `engine/`).
2. **[depot_tools](https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up)** on the front of your `PATH`.
3. **gclient** at the Flutter repo root:

   ```bash
   # From the flutter repo root (once)
   cp engine/scripts/standard.gclient .gclient
   gclient sync
   ```

4. **Platform tooling**
   - **Android:** NDK/SDK from `gclient sync`; build from macOS, Linux, or Windows.
   - **iOS:** macOS + Xcode only.
   - **Windows:** Android engine only, not iOS.

---

## Host vs target builds

You need **both** a **host** build (`gen_snapshot`, tools) and a **target** build (`libflutter.so` or iOS framework).

| | Host (`out/host_*`) | Android target | iOS target |
|---|---------------------|----------------|------------|
| **Debug / iteration** | `host_debug_unopt` | `android_debug_unopt_arm64` | `ios_debug_unopt` |
| **Store / OTA (release)** | `host_release` | `android_release_arm64` | `ios_release` |

Rules:

- Always pair host and target from the **same** mode (debug vs release).
- After `gclient sync`, **rebuild the host** before rebuilding Android/iOS.
- Store binaries and OTA patches must use the **same** `out/` directories you ship with.

On **Apple Silicon Macs**, add `--mac-cpu arm64` to **host** `gn` lines so the output is `host_debug_unopt_arm64` / `host_release_arm64` instead of x64-under-Rosetta.

---

## Building with `gn` and `ninja`

`gn` generates Ninja files under `engine/src/out/<name>/`. `ninja -C out/<name>` compiles.

### Host (required for every platform)

**Debug (fast iteration):**

```bash
# Intel Mac / Linux
./flutter/tools/gn --unoptimized
ninja -C out/host_debug_unopt

# Apple Silicon Mac
./flutter/tools/gn --unoptimized --mac-cpu arm64
ninja -C out/host_debug_unopt_arm64
```

**Release (store builds & code push):**

```bash
# Intel Mac / Linux
./flutter/tools/gn --runtime-mode=release
ninja -C out/host_release

# Apple Silicon Mac
./flutter/tools/gn --runtime-mode=release --mac-cpu arm64
ninja -C out/host_release_arm64
```

Optional: add `--no-lto` to release `gn` for faster links (slightly larger binaries).

---

### Android

Build the **host** steps above first, then the Android target.

**Debug — arm64 device (typical):**

```bash
./flutter/tools/gn --android --android-cpu arm64 --unoptimized
ninja -C out/android_debug_unopt_arm64
```

**Debug — other ABIs:**

```bash
# 32-bit ARM devices
./flutter/tools/gn --android --unoptimized
ninja -C out/android_debug_unopt

# x86 emulator
./flutter/tools/gn --android --android-cpu x86 --unoptimized
ninja -C out/android_debug_unopt_x86

# x64 emulator
./flutter/tools/gn --android --android-cpu x64 --unoptimized
ninja -C out/android_debug_unopt_x64
```

**Release — arm64 (Play Store / code push):**

```bash
./flutter/tools/gn --android --android-cpu arm64 --runtime-mode=release
ninja -C out/android_release_arm64
```

**Release — 32-bit ARM:**

```bash
./flutter/tools/gn --android --runtime-mode=release
ninja -C out/android_release
```

**One-shot debug build (host + Android arm64):**

```bash
./flutter/tools/gn --unoptimized --mac-cpu arm64          # omit --mac-cpu on Intel
./flutter/tools/gn --android --android-cpu arm64 --unoptimized
ninja -C out/host_debug_unopt_arm64 && ninja -C out/android_debug_unopt_arm64
```

Use Flutter with matching directory names:

```bash
flutter run --release \
  --local-engine=android_release_arm64 \
  --local-engine-host=host_release
# On Apple Silicon host release build, use:
#   --local-engine-host=host_release_arm64
```

---

### iOS (macOS only)

Build the **host** steps above first, then iOS.

**Debug — physical device:**

```bash
./flutter/tools/gn --ios --unoptimized
ninja -C out/ios_debug_unopt
```

**Debug — simulator:**

```bash
./flutter/tools/gn --ios --simulator --unoptimized
ninja -C out/ios_debug_sim_unopt

# Apple Silicon Mac, arm64 simulator
./flutter/tools/gn --ios --simulator --simulator-cpu arm64 --unoptimized
ninja -C out/ios_debug_sim_unopt_arm64
```

**Release — physical device (App Store / code push):**

```bash
./flutter/tools/gn --ios --runtime-mode=release
ninja -C out/ios_release
```

**One-shot debug build (host + iOS device):**

```bash
./flutter/tools/gn --unoptimized --mac-cpu arm64          # omit --mac-cpu on Intel
./flutter/tools/gn --ios --unoptimized
ninja -C out/host_debug_unopt_arm64 && ninja -C out/ios_debug_unopt
```

Flutter:

```bash
flutter run --release \
  --local-engine=ios_release \
  --local-engine-host=host_release
# Apple Silicon host: --local-engine-host=host_release_arm64
```

---

## Building with `et` (alternative)

Same `out/<config>` names as `gn`/`ninja`. From `engine/src`:

```bash
# Release (code push / store)
et build -c host_release
et build -c android_release_arm64
et build -c ios_release          # macOS only

# Debug iteration
et build -c host_debug_unopt_arm64
et build -c android_debug_unopt_arm64
et build -c ios_debug_unopt
```

List configs: `et query configs`

---

## Run your app with the custom engine

`--local-engine` is the **`out/` folder name** (not a full path).

```bash
cd /path/to/your/app

# Android release
flutter run --release \
  --local-engine=android_release_arm64 \
  --local-engine-host=host_release

# iOS release
flutter run --release \
  --local-engine=ios_release \
  --local-engine-host=host_release

# Store artifacts
flutter build apk --release \
  --local-engine=android_release_arm64 \
  --local-engine-host=host_release

flutter build ipa --release \
  --local-engine=ios_release \
  --local-engine-host=host_release
```

Use the same flags in CI and when [extracting patch blobs](../../packages/flutter_code_push/README.md#create-and-publish-a-patch).

---

## Verify the custom engine

1. Install a **release** build with `--local-engine` (not a stock engine).
2. Stage a test patch ([flutter_code_push README](../../packages/flutter_code_push/README.md)).
3. **Kill the process** and cold-start.
4. **Android:** logcat — `FlutterLoader` with `--isolate-snapshot-data=`.
5. **iOS:** `Documents/code_push/active/` contains both blob files.

---

## Keeping the engine up to date

```bash
git fetch upstream master
git rebase upstream/master
gclient sync -D
cd engine/src

# Rebuild host, then targets
./flutter/tools/gn --runtime-mode=release --mac-cpu arm64   # adjust host flags
ninja -C out/host_release_arm64

./flutter/tools/gn --android --android-cpu arm64 --runtime-mode=release
ninja -C out/android_release_arm64
```

---

## Next steps

1. Add [flutter_code_push](../../packages/flutter_code_push/) to your app.
2. Ship a store build with the **same** `--local-engine` / `out/` configs.
3. Publish patches — [packages/flutter_code_push/README.md](../../packages/flutter_code_push/README.md#create-and-publish-a-patch).
