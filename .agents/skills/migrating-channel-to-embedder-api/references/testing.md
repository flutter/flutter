# Testing a Channel Migration

## Tests to add

One test per layer at minimum. Copy the shape of the existing test next to it.

| Layer | File | What to test |
|---|---|---|
| Embedder API | `$ENGINE/shell/platform/embedder/tests/embedder_unittests.cc` + a Dart entrypoint in `$ENGINE/shell/platform/embedder/fixtures/main.dart` | The value reaches dart:ui (fixture signals it back with `signalNativeMessage`); invalid arguments and a null engine return `kInvalidArguments`; state set before the isolate starts is delivered. Outbound: the `FlutterProjectArgs` callback fires with the right value. |
| Deprecated channel | `embedder_unittests.cc` | Sending on the old channel still delivers the value through dart:ui and logs the warning exactly once (use `fml::testing::LogCapture` on the UI task runner). |
| Runtime (outbound) | `$ENGINE/runtime/runtime_controller_unittests.cc` | `RuntimeController::{Api}` reaches the delegate. |
| dart:ui (web) | `$ENGINE/lib/web_ui/test/engine/platform_dispatcher/platform_dispatcher_test.dart` | Getter and callback behave, including "no callback when unchanged". |
| Each adopted embedder | See [platform-adoption.md](platform-adoption.md) | The embedder calls the new API (mocked with `MOCK_ENGINE_PROC`, `MOCK_METHOD`, or Mockito) instead of sending on the channel. Rewrite tests that asserted channel messages; do not just delete them. |
| Framework | `$FRAMEWORK/test/services/` or the binding's test | The binding reacts to `on{Name}Changed` via `TestPlatformDispatcher.{name}TestValue`; the old channel still works; listeners on `SystemChannels.<channel>` still get messages. |
| api_check | `$ENGINE/tools/api_check/test/apicheck_test.dart` | Every new enum copy is compared with the dart:ui enum. |

`embedder_proctable_unittests` already fails if the proc table entry is missing or
duplicated; it needs no new test.

## Environment

- Run engine commands from `$ENGINE`.
- `et` needs depot_tools on `PATH` (it calls `vpython3`). If GN fails with exit code
  127 or "No such file", the gclient dependencies are stale: tell the user to run
  `gclient sync` (or `et fetch`). Do not edit the build files to work around it.
- Use the existing `host_debug` output directory if there is one; otherwise ask before
  starting a full build.

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
./flutter_linux_unittests
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

Also analyze the changed framework files:

```bash
bin/flutter analyze --local-engine=host_debug --local-engine-host=host_debug \
  --local-engine-src-path=engine/src <changed .dart files>
```

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
