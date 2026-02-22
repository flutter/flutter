# Running iOS text input unit tests (issue #135221)

After building the engine, run the iOS embedder tests that include `FlutterTextInputPluginTest`:

## 1. Build the engine (from repo root)

```bash
# Ensure depot_tools is on PATH, then:
cd /path/to/flutter
gclient sync   # if not already done
cd engine/src
./flutter/tools/gn --ios --simulator --unoptimized   # or --ios --unoptimized for device
./flutter/tools/gn --unoptimized --mac-cpu=arm64    # host build (Apple Silicon)
ninja -C out/ios_debug_sim_unopt
ninja -C out/host_debug_unopt_arm64
```

Or use the Engine Tool: `et build -c ios_debug_sim_unopt` and `et build -c host_debug_unopt_arm64`.

## 2. Run the tests

**Option A – Xcode**

Open the generated project and run the test target:

```bash
open out/ios_debug_sim_unopt/flutter_engine.xcodeproj
# Select the test target (e.g. ios_test_flutter) and run tests (Cmd+U or Product > Test)
```

**Option B – Command line** (if the test runner is built)

```bash
# From engine/src, run the iOS unit test binary if available, e.g.:
out/ios_debug_sim_unopt/ios_test_flutter
```

## 3. Run only the new test

In Xcode, run the single test `testSetAttributedMarkedTextSelectedRange` (in `FlutterTextInputPluginTest`). It is guarded with `API_AVAILABLE(ios(17.0))` and runs on iOS 17+.

## 4. Framework tests (Dart)

From the Flutter repo root (no engine changes in framework):

```bash
./bin/flutter test packages/flutter/test/widgets/editable_text_test.dart
./bin/flutter test packages/flutter/test/services/text_input_test.dart
```

Our changes are engine-only; these confirm no framework regressions.
