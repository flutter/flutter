# Linux GTK Variant Selection

This document covers the available mechanisms for selecting the Linux GTK
variant used by a project.

## Background

There are two separate layers:

1. The Linux engine builds two runner libraries:
   - `libflutter_linux_gtk.so` for GTK3
   - `libflutter_linux_gtk4.so` for GTK4

   That is a build-time choice in the engine, because each runner links a
   different GTK stack and compiles different source paths.

2. The Flutter framework and tooling carry both GTK3 and GTK4 code paths in
   the repo. The framework does not need a single global GTK build choice; it
   always contains both implementations, and the tool chooses which runner
   library to use for a project.

The selected engine variant determines:
- Which GDK/GTK packages are linked (`gtk+-3.0` vs `gtk4`)
- The compile-time define: `FLUTTER_LINUX_GTK3` vs `FLUTTER_LINUX_GTK4`
- Which engine source files are compiled for the runner library

## Template Model

The project template is a separate concern from the engine build.

Template choices determine how the generated Linux project is laid out:
- A unified template can carry both GTK3 and GTK4 runner wiring in one project
- A GTK3-specific template can keep the older runner shape as the default
- A GTK4-specific template can preconfigure the project to use the GTK4 runner

Those template choices affect the project structure and metadata, but they do
not change the fact that the engine still builds separate GTK3 and GTK4 runner
libraries. The template decides which runner the project points at by default;
the engine decides which runner library exists at build time.

## Current Selection Paths

The Linux GTK variant is selected at build time through the toolchain, with
`gtk3` remaining the default for compatibility.

For native popup and multi-window demos, see
[Linux Native Popup And Multi-Window API](linux-popup-windowing.md).

Supported inputs on this branch:

```yaml
flutter:
  config:
    linux-gtk-default: gtk3   # or "gtk4"
```

```bash
flutter run --linux-gtk=gtk4
flutter config --linux-gtk-default=gtk4
FLUTTER_LINUX_GTK=gtk4 flutter build linux
cmake -DLINUX_GTK_VARIANT=gtk4
```

The legacy hidden `linux/.gtk_variant.cmake` file was a workaround for older
layouts. It is no longer the preferred configuration path for this branch.

## Options

### 1. pubspec.yaml (recommended - source of truth)

Declare the GTK variant in pubspec.yaml:

```yaml
flutter:
  config:
    linux-gtk-default: gtk4   # or "gtk3"
```

**Pros:**
- Single source of truth in the project manifest where developers expect
  build configuration lives
- No hidden files in the source tree
- Self-documenting - developers read pubspec to understand project options
- Follows the existing Flutter manifest `flutter.config` namespace used by
  tooling-owned project defaults

**Cons:**
- CMake cannot read pubspec directly
- Requires the Flutter tool to read pubspec and translate to a
  CMake-compatible mechanism (env var or `-D` flag)

The key is named `linux-gtk-default` rather than `gtk_variant_default` so it
matches Flutter's existing hyphenated manifest option style and scopes the
default to the Linux GTK runner. The command-line and global config forms use
the same name:

```bash
flutter run --linux-gtk=gtk4
flutter config --linux-gtk-default=gtk4
```

### 2. Environment variable (already supported by CMakeLists.txt)

```bash
FLUTTER_LINUX_GTK=gtk4 flutter build linux
```

**Pros:**
- No file changes required — CMakeLists.txt already checks `$ENV{FLUTTER_LINUX_GTK}`
- Works in CI, shell profiles, IDE configurations
- No source tree pollution
- Overrides everything else (intended for build-time override)

**Cons:**
- Not discoverable — developers have to know to set it
- Not committed to the repo (which is fine, but means CI must also set it)

### 3. CMake cache variable (already supported by CMakeLists.txt)

```bash
cmake -DCMAKE_BUILD_TYPE=Debug -DLINUX_GTK_VARIANT=gtk4
```

Or in IDE configs / `build/linux/x64/release/linux/` CMake cache.

**Pros:**
- Standard CMake idiom
- CMakeLists.txt already handles it with the `elseif(DEFINED LINUX_GTK_VARIANT)` fallback
- Works with CMake Presets, IDEs, CI scripts
- No hidden files in source tree

**Cons:**
- Not discoverable outside the build directory
- Requires passing the flag explicitly in every build invocation
- Doesn't survive clean builds unless baked into CMake cache or presets

### 4. CMakePresets.json

```json
{
  "version": 3,
  "configurePresets": [
    {
      "name": "gtk4-debug",
      "hidden": true,
      "cacheVariables": {
        "LINUX_GTK_VARIANT": "gtk4",
        "CMAKE_BUILD_TYPE": "Debug"
      }
    }
  ]
}
```

**Pros:**
- Standard CMake mechanism, supported by all modern IDEs (VSCode, CLion,
  Qt Creator, etc.)
- Persists across clean builds
- Can coexist with multiple presets for different configurations
- No hidden files — CMakePresets.json is a first-class CMake artifact

**Cons:**
- Requires adding the file to the project (not currently present in generated
  Linux runners)
- Slightly more setup than just setting an env var

### 5. Dedicated config file (e.g., `.flutter-linux-config`)

```yaml
linux:
  gtk_variant_default: gtk4
```

**Pros:**
- Explicitly named for this purpose — not a `.cmake` file masquerading as
  project config
- Can be extended with other Linux-specific options in the future
- Tooling can read it and translate to env var / CMake flag

**Cons:**
- Still a hidden file (dot-prefixed) in the source tree
- Not a standard Flutter/Dart mechanism
- Adds another config file format to maintain

## Recommendation

Keep `pubspec.yaml` as the source of truth, with the Flutter tool translating
that choice into the build-system inputs.

The current layering should be:
1. Read `flutter.config.linux-gtk-default` from pubspec.yaml
2. Allow `--linux-gtk` to override the manifest default at run time
3. Pass the resolved variant to CMake as `-DLINUX_GTK_VARIANT=<value>`
4. Respect `FLUTTER_LINUX_GTK` as a lower-level build override when needed

This keeps:
- **Developers** - their choice lives where they expect it (pubspec)
- **CI** - can override via env var or CMake preset
- **CMake** - uses its standard input mechanisms (cache variables, env vars)
- **The repo** - no hidden build artifacts in the source tree
