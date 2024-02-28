# Scenario App: Android Tests

As mentioned in the [top-level README](../README.md), this directory contains
the Android-specific native code and tests for the [scenario app](../lib). To
run the tests, you will need to build the engine with the appropriate
configuration.

For example, for the latest `android` build you've made locally:

```sh
dart ./testing/scenario_app/bin/run_android_tests.dart
```

Or for a specific, build, such as `android_debug_unopt_arm64`:

```sh
dart ./testing/scenario_app/bin/run_android_tests.dart --out-dir=../out/android_debug_unopt_arm64
```

See also:

- [File an issue][file_issue] with the `e: scenario-app, platform-android`
  labels.

[file_issue]: https://github.com/flutter/flutter/issues/new?labels=e:%20scenario-app,engine,platform-android,fyi-android,team-engine

## Debugging

Debugging the tests on CI is not straightforward but is being improved:

- <https://github.com/flutter/flutter/issues/143458>
- <https://github.com/flutter/flutter/issues/143459>

Locally (or on a temporary PR for CI), you can run the tests with the
`--smoke-test` argument to run a single test by class name, which can be useful
to verify the setup:

```sh
dart ./testing/scenario_app/bin/run_android_tests.dart --smoke-test dev.flutter.scenarios.EngineLaunchE2ETest
```

The result of `adb logcat` and screenshots taken during the test will be stored
in a logs directory, which is either `FLUTTER_LOGS_DIR` (if set, such as on CI)
or locally in `out/.../scenario_app/logs`.

You can then view the logs and screenshots on LUCI. [For example](https://ci.chromium.org/ui/p/flutter/builders/try/Linux%20Engine%20Drone/2003164/overview):

![Screenshot of the Logs on LUCI](https://github.com/flutter/engine/assets/168174/79dc864c-c18b-4df9-a733-fd55301cc69c)

For a full list of flags, see [the runner](../bin/README.md).

## CI Configuration

See [`ci/builders`](../../../ci/builders) and grep for `run_android_tests.dart`.

### Skia

> [!NOTE]
> As of 2024-02-28, Flutter on Android defaults to the Skia graphics backend.

There are two code branches we test using `scenario_app`:

- Older Android devices, that use `SurfaceTexture`.
  - CI Configuration (TODO: Link)
  - CI History (TODO: Link)
  - Skia Gold (TODO: Link)
- Newer Android devices, (API 34) that use `ImageReader`.
  - CI Configuration (TODO: Link)
  - CI History (TODO: Link)
  - Skia Gold (TODO: Link)

### Impeller with OpenGLES

There are two code branches we test using `scenario_app`:

- Older Android devices, that use `SurfaceTexture`.
  - CI Configuration (TODO: Link)
  - CI History (TODO: Link)
  - Skia Gold (TODO: Link)
- Newer Android devices, (API 34) that use `ImageReader`.
  - CI Configuration (TODO: Link)
  - CI History (TODO: Link)
  - Skia Gold (TODO: Link)

### Impeller with Vulkan

There is only a single code branch we test using `scenario_app`:

- Newer Android devices, (API 34)
  - CI Configuration (TODO: Link)
  - CI History (TODO: Link)
  - Skia Gold (TODO: Link)

## Updating Gradle dependencies

See [Updating the Embedding Dependencies](../../../tools/cipd/android_embedding_bundle/README.md).

## Output validation

The generated output will be checked against a golden file
([`expected_golden_output.txt`](./expected_golden_output.txt)) to make sure all
output was generated. A patch will be printed to stdout if they don't match.
