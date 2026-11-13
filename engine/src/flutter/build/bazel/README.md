# The Bazel build of the engine

GN is the engine's build system. This directory holds an experimental Bazel
build of the same engine, generated from the GN build files: the converter
in `tools/gn_to_bazel` reads each `BUILD.gn` and writes the `BUILD.bazel`
beside it. The rules those files load are in `//build_defs/` at the
repository root; the toolchains, the wrapped GN builds and the third-party
overlays are here.

Start with this page. The design of each part is in the reference documents
listed at the end.

## Status

- Hosts: Linux x64 and macOS. Targets: the host, Android, iOS and the web.
  There is no Bazel build for Windows, Fuchsia or riscv64 Linux.
- GN stays the source of truth. A `BUILD.bazel` whose header says
  "Generated ... do not edit" is the converter's output; change the
  `BUILD.gn` and rerun the converter (see "After you change the build").
- `et` builds with GN unless asked for Bazel.
- The builder files under `ci/builders` that carry `--bazel` build through
  Bazel on CI without a recipe change; `ci.md` describes how.
- "Known gaps" below lists what the Bazel build does not do yet.

## Prerequisites

- An engine checkout synced with `gclient sync`. Bazel reads the synced
  trees in place and never runs gclient.
- `bazelisk` on `PATH`. It downloads the Bazel release `.bazelversion`
  names. On CI the gclient variable `download_bazelisk` syncs a copy to
  `engine/src/flutter/third_party/bazelisk`, which `tools/gn --bazel` uses;
  `et` uses the one on `PATH`.
- On Linux: `Xvfb` for the suites that open a window; `dbus` and
  `at-spi2-core` for the GTK shell's suite.
- On a Mac: Xcode.
- For the web targets: the gclient variable `download_emsdk`.
- Disk and memory: see "How long it takes, and how much room".

## Quick start for an engine developer

Run Bazel from the repository root.

```sh
# Everything GN's default target builds, for the unoptimized debug host build.
bazelisk build --config=host_debug_unopt //engine/src/flutter:flutter

# One suite.
bazelisk test --config=host_debug_unopt //engine/src/flutter/fml:fml_unittests
```

A `--config` names a build as `et` and the builder files name it:
`host_debug_unopt`, `host_release`, `android_debug_unopt`, and
`ci_<name>` for a CI build `ci/<name>`. `grep '^build:'
engine/src/flutter/ci/builders/configs.bazelrc` lists them all. A build
without a `--config` is a configuration no builder builds.

A GN label `//flutter/fml:fml_unittests` is the Bazel label
`//engine/src/flutter/fml:fml_unittests`.

Through `et`:

```sh
et build --backend bazel --config host_debug_unopt
et test --backend bazel --config host_debug_unopt //flutter/fml:fml_unittests
```

`ET_BACKEND=bazel` in the environment has the same effect as the option.
`et build` prints the directory to give the flutter tool as `--local-engine`;
`docs/artifacts.md` describes how the tool reads it.

## Quick start for a framework or tool contributor

These tests run against the prebuilt engine the flutter tool downloads, so
they need no engine checkout and build no engine.

```sh
bin/flutter precache

# One test file: the label is the file's name without ".dart".
bazelisk test --config=prebuilt_engine //packages/flutter/test/widgets:text_test

# A directory's tests.
bazelisk test --config=prebuilt_engine //packages/flutter/test/widgets:widgets
```

On Linux and macOS `dart dev/bots/test.dart` runs the framework and tool
shards this way by default; `--no-bazel` runs them through `flutter test`
and `dart test` as before. `docs/framework_tests.md` has the details,
including which `flutter precache` options the tool's shards need.

## Everyday tasks

| To | Run |
|---|---|
| Build or test one target | `bazelisk build --config=<cfg> <label>` or `bazelisk test --config=<cfg> <label>` |
| List the tests under a directory | `bazelisk query 'tests(//engine/src/flutter/fml/...)'` |
| Run some of a suite's cases | `bazelisk test --config=<cfg> --test_filter='Base32*' //engine/src/flutter/fml:fml_unittests` |
| Run a suite's binary directly, for example under a debugger | `bazelisk build --config=<cfg> <label>_binary`, then from the repository root `engine/src/out/bazel-bin/engine/src/flutter/fml/fml_unittests_binary --gtest_filter='Base32*'`. Debug information names sources relative to the repository root, so start the debugger there |
| Write `compile_commands.json` | `python3 engine/src/flutter/tools/gn_to_bazel/tool/compile_commands.py --out=engine/src/out/<dir> --config=<cfg>` |
| Free the build's outputs | `bazelisk clean` |
| Stop the Bazel server | `bazelisk shutdown` |

## After you change the build

| You changed | Run | To check without writing |
|---|---|---|
| A `BUILD.gn` or `.gni`, a builder file under `ci/builders`, or `lib/web_ui/test/felt_config.yaml` | In `engine/src/flutter/tools/gn_to_bazel`: `../../prebuilts/<host>/dart-sdk/bin/dart bin/gn_to_bazel.dart --buildifier=none` | Add `--check` |
| `DEPS` | In `engine/src/flutter/tools/bazel_tools`: `../../prebuilts/<host>/dart-sdk/bin/dart bin/gen_deps.dart` | Add `--check` |
| `pubspec.lock` | `dart pub get` at the repository root and in `engine/src/flutter/lib/web_ui`, then in `tools/bazel_tools`: `dart bin/gen_pub_lock.dart` | Add `--check` |

CI fails until these are current: `ci/check_generated_bazel_files.sh` runs
the converter's check, and the `bazel_tools` tests check the two lock files.
`tools/gn_to_bazel/README.md` explains the converter, including what to do
when it reports a GN construct it does not know.

## Where Bazel keeps its state

| What | Where |
|---|---|
| Build outputs | Bazel's output root, `~/.cache/bazel` by default; `engine/src/out/bazel-bin` and its siblings are links into it |
| The disk cache of action results, shared by every checkout | `~/.cache/flutter_engine_bazel`, collected to 20 GB by an idle server |
| Outputs and cache of `tools/gn --bazel` builds and of `dev/bots/test.dart` | `.bazel_ci/` in the checkout, ignored by git |

## How long it takes, and how much room

Measured in November 2026 on a 24-core Linux workstation with 94 GB of RAM,
for `host_debug_unopt` without remote execution:

| | Bazel | GN + ninja |
|---|---|---|
| First full build | 32 to 36 minutes | 20 to 21 minutes |
| Build with nothing changed | about 1 s | about 1 s |
| Rebuild after changing one `.cc` | 4 to 17 s | 2 to 13 s |
| Clean rebuild from the disk cache | about 2 minutes | not available |
| Peak process memory | about 15 GB | about 10.5 GB |
| Disk | about 48 GB of output, plus up to 20 GB of disk cache | about 27 GB |

`docs/performance.md` has the measurements and what the cache and the
sandbox contribute.

## Known gaps

- No Windows, Fuchsia or riscv64 Linux build.
- Tests run with the network blocked, so golden images are neither compared
  nor uploaded under Bazel.
- The Dart SDK and the GPU test backends (ANGLE, SwiftShader, the Vulkan
  loader) are GN builds wrapped as single Bazel actions. An edit inside
  them reruns the whole wrapped build.
- The wrapped Dart SDK build compiles the VM without LTO in every build.
  GN compiles it with the engine's LTO: full in the Android AOT and iOS
  device builds, thin in the Linux profile and release builds.
- Of GN's sanitizer builds only ASan has a Bazel counterpart, and there is
  no coverage build.
- No IDE project is generated; the compile database is written on request.
- After a roll of `DEPS` or of the pub packages, the generated lock files
  must be regenerated by hand (see the table above).
- Debugging is documented only as far as the row in "Everyday tasks";
  `docs/engine/Debugging-the-engine.md` describes GN's layout.

## Reference

| Document | Subject |
|---|---|
| `docs/dependencies.md` | How dependencies reach Bazel; adding one |
| `docs/toolchains.md` | The C/C++ toolchains: Linux, Android, macOS and iOS, Emscripten |
| `docs/wrapped_gn_builds.md` | The Dart SDK and the GPU test backends as wrapped GN builds |
| `docs/engine_tests.md` | The engine's C++, Dart and Java tests |
| `docs/framework_tests.md` | The framework's and the tool's tests; the prebuilt engine; `dev/bots/test.dart` |
| `docs/web_tests.md` | The web engine's unit tests |
| `docs/artifacts.md` | Archives, the build directory, local engines |
| `docs/builders.md` | Builder configurations and `et` |
| `docs/shaders.md` | Impeller's shader pipeline |
| `docs/performance.md` | Build speed: measurements, the cache, the sandbox |
| `docs/verification.md` | What to run before landing a change to the Bazel build |
| `ci.md` | CI through the unchanged recipes |
| `//build_defs/README.md` | Index of the build rules |
| `tools/gn_to_bazel/README.md` | The converter |
