# Testing a Channel Migration

## Tests to add

One test per layer at minimum. Copy the shape of the existing test next to it.

| Layer | File | What to test |
|---|---|---|
| Embedder API | `$ENGINE/shell/platform/embedder/tests/embedder_unittests.cc` + a Dart entrypoint in `$ENGINE/shell/platform/embedder/fixtures/main.dart` | The value reaches dart:ui (fixture signals it back with `signalNativeMessage`); invalid arguments and a null engine return `kInvalidArguments`. Outbound: the `FlutterProjectArgs` callback fires with the right value. |
| Shell (inbound state) | `$ENGINE/shell/common/shell_unittests.cc` + `$ENGINE/shell/common/fixtures/shell_test.dart` | State set before the isolate starts is delivered: call `shell->GetPlatformView()->{Api}(...)` in a `PostSync` on the platform runner before `RunEngine`, and have the fixture report `PlatformDispatcher.instance.{name}` with `notifyMessage`. This cannot be tested through the embedder API: there is no `PlatformView` until `FlutterEngineRunInitialized`, which also starts the isolate. |
| Deprecated channel | `embedder_unittests.cc` | Sending on the old channel still delivers the value through dart:ui. The warning uses a process-wide once flag (see the `deprecation-warning` hop), so only assert the log where no earlier test can have used the channel. `fml::testing::LogCapture` only captures the thread it was created on: create it in a task on the UI runner and read `.str()` in a later UI task. |
| Runtime (outbound) | `$ENGINE/runtime/runtime_controller_unittests.cc` | `RuntimeController::{Api}` reaches the delegate. |
| dart:ui (web) | `$ENGINE/lib/web_ui/test/engine/platform_dispatcher/platform_dispatcher_test.dart` | Getter and callback behave, including "no callback when unchanged". |
| Each adopted embedder | See [platform-adoption.md](platform-adoption.md) | The embedder calls the new API (mocked with `MOCK_ENGINE_PROC`, `MOCK_METHOD`, or Mockito) instead of sending on the channel. Rewrite tests that asserted channel messages; do not just delete them. A test may be deleted only if it tested nothing but code you removed (for example "is the framework listening yet" gating); say so in the PR. |
| Framework | `$FRAMEWORK/test/services/` or the binding's test | The binding reacts to `on{Name}Changed` via `TestPlatformDispatcher.{name}TestValue`; the old channel still works; listeners on `SystemChannels.<channel>` still get messages. |
| api_check | `$ENGINE/tools/api_check/test/apicheck_test.dart` | Every new enum copy is compared with the dart:ui enum, with `expect(values, isNotEmpty)`. Use the helper that matches the source: Dart *enums* are not classes, so `getDartClassFields` returns an empty list for them. Confirm the test fails if you delete one enum value. |

`embedder_proctable_unittests` already fails if the proc table entry is missing or
duplicated; it needs no new test.

When rewriting an existing test, check it can fail: remove the call it covers and
confirm the test fails. Several channel-based tests turned out to pass vacuously.

## Environment

- Run engine commands from `$ENGINE`.
- `et` needs depot_tools on `PATH` (it calls `vpython3`). If GN fails with exit code
  127 or "No such file", the gclient dependencies are stale: tell the user to run
  `gclient sync` (or `et fetch`). Do not edit the build files to work around it.
- Use the existing `host_debug` output directory if there is one; otherwise ask before
  starting a full build.
- Framework tests (step 6) need a full `host_debug` build. Start it early, in the
  background, while you work on platform adoption. Never run two builds on the same
  output directory at once.

## Commands

### 1. Static checks

```bash
dart .agents/skills/migrating-channel-to-embedder-api/scripts/check_hops.dart --direction ... --name ... --api ...
```

### 2. Format

```bash
cd engine/src/flutter && ./bin/et format
dart format <changed framework .dart files>
```

### 3. Build

```bash
cd engine/src/flutter && ./bin/et build -c host_debug \
  //flutter/shell/platform/embedder:embedder_unittests \
  //flutter/shell/platform/embedder:embedder_proctable_unittests \
  //flutter/shell/common:shell_unittests \
  //flutter/runtime:runtime_unittests \
  //flutter/lib/ui:ui_unittests \
  //flutter/shell/platform/linux:flutter_linux_unittests
```

Use `//flutter/shell/platform/windows:flutter_windows_unittests` on Windows and the
macOS targets on macOS instead of the Linux target. A build failure in a file you
did not change usually means a missed delegate implementor: re-run `check_hops.dart`.

### 4. Run engine tests

Run the binaries directly from the output directory, filtered to the new tests
first, then unfiltered:

```bash
cd engine/src/out/host_debug
./embedder_unittests --gtest_filter='*{Name}*'
./embedder_unittests
./embedder_proctable_unittests
./shell_unittests
./runtime_unittests
./ui_unittests
xvfb-run -a ./flutter_linux_unittests  # needs a display
```

### 5. api_check

```bash
cd engine/src/flutter/tools/api_check && ../../../out/host_debug/dart-sdk/bin/dart test
```

### 6. Framework tests

dart:ui changed, so the framework must be tested against the local engine. This
needs a full `host_debug` build (`./bin/et build -c host_debug` with no targets)
so `flutter_tester` and `sky_engine` are up to date:

```bash
cd packages/flutter && ../../bin/flutter test \
  --local-engine=host_debug --local-engine-host=host_debug \
  --local-engine-src-path=../../engine/src \
  test/services/<changed>_test.dart test/widgets/binding_test.dart
```

Run only the test files for the code you changed (plus `binding_test.dart`). Some
unrelated tests fail with a local host engine (for example on the `engineId != null`
assertion in `_window_linux.dart`); compare with a clean tree before investigating.

Analyzing framework code that uses the new dart:ui members needs the local
`sky_engine`, but `flutter analyze` ignores `--local-engine` for `dart:ui`. Either
accept "undefined getter" errors for exactly the new members (the `flutter test` run
above already compiled the code against the local engine), or temporarily point the
`sky_engine` entry in the repository root's `.dart_tool/package_config.json` at
`engine/src/out/host_debug/gen/dart-pkg/sky_engine`, run `bin/dart analyze <files>`,
and restore the file. The web engine package needs its own `dart pub get` (with the
`host_debug` Dart SDK) before `dart analyze` works on its files.

### 7. Web, Android and iOS tests

These need extra toolchains (Chrome via `felt`, Android SDK, Xcode). Run them only if
the host supports them; otherwise list them as unverified:

- Web: `cd engine/src/flutter/lib/web_ui && dev/felt test test/engine/platform_dispatcher/`
- Android Java: `./bin/et test -c android_debug_unopt_arm64 ...` or Robolectric via
  `testing/run_tests.py --type=java`
- iOS and macOS: XCTest via `testing/run_tests.py --type=objc` on macOS

## Unverified platforms

Keep a list of every platform whose code was changed but not built and tested
locally. It goes in the PR description.
