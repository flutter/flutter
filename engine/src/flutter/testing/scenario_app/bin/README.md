# `android_integration_tests` runner

This directory contains code specific to running Android integration tests.

The tests are uploaded and run on the device using `adb`, and screenshots are
captured and compared using Skia Gold (if available, for example on CI).

## Usage

```sh
dart bin/android_integration_tests.dart \
  --adb ../third_party/android_tools/sdk/platform-tools/adb \
  --out-dir ../out/android_debug_unopt_arm64
```

## Debugging

When debugging, you can use the `--smoke-test` argument to run a single test
by class name, which can be useful to verify the setup.

For example, to run the `EngineLaunchE2ETest` test:

```sh
dart bin/android_integration_tests.dart \
  --adb ../third_party/android_tools/sdk/platform-tools/adb \
  --out-dir ../out/android_debug_unopt_arm64 \
  --smoke-test dev.flutter.scenarios.EngineLaunchE2ETest
```

## Additional arguments

- `--use-skia-gold`: Use Skia Gold to compare screenshots. Defaults to true
  when running on CI, and false otherwise (i.e. when running locally). If
  set to true, [isSkiaGoldClientAvailable] must be true.

- `--enable-impeller`: Enable Impeller for the Android app. Defaults to
  false, which means that the app will use Skia as the graphics backend.

- `--impeller-backend`: The Impeller backend to use for the Android app.
  Defaults to 'vulkan'. Only used when `--enable-impeller` is set to true.
