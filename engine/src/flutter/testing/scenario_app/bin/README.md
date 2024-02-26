# `android_integration_tests` runner

This directory contains code specific to running Android integration tests.

The tests are uploaded and run on the device using `adb`, and screenshots are
captured and compared using Skia Gold (if available, for example on CI).

## Usage

```sh
dart bin/android_integration_tests.dart
```

## Debugging

When debugging, you can use the `--smoke-test` argument to run a single test
by class name, which can be useful to verify the setup.

For example, to run the `EngineLaunchE2ETest` test:

```sh
dart bin/android_integration_tests.dart --smoke-test dev.flutter.scenarios.EngineLaunchE2ETest
```

## Additional arguments

```txt
-v, --verbose                                        Enable verbose logging
-h, --help                                           Print usage information
    --[no-]enable-impeller                           Whether to enable Impeller as the graphics backend. If true, the
                                                     test runner will use --impeller-backend if set, otherwise the
                                                     default backend will be used. To explicitly run with the Skia
                                                     backend, set this to false (--no-enable-impeller).
    --impeller-backend                               The graphics backend to use when --enable-impeller is true. Unlike
                                                     the similar option when launching an app, there is no fallback;
                                                     that is, either Vulkan or OpenGLES must be specified.
                                                     [vulkan (default), opengles]
    --logs-dir                                       Path to a directory where logs and screenshots are stored.
    --out-dir=<path/to/out/android_variant>          Path to a out/{variant} directory where the APKs are built.
                                                     Defaults to the latest updated out/ directory that starts with
                                                     "android_" if the current working directory is within the engine
                                                     repository.
    --smoke-test=<package.ClassName>                 Fully qualified class name of a single test to run. For example try
                                                     "dev.flutter.scenarios.EngineLaunchE2ETest" or
                                                     "dev.flutter.scenariosui.ExternalTextureTests".
    --output-contents-golden=<path/to/golden.txt>    Path to a file that contains the expected filenames of golden
                                                     files. If the current working directory is within the engine
                                                     repository, defaults to
                                                     ./testing/scenario_app/android/expected_golden_output.txt.
```

## Advanced usage

```txt
    --[no-]use-skia-gold                             Whether to use Skia Gold to compare screenshots. Defaults to true
                                                     on CI and false otherwise.
    --adb=<path/to/adb>                              Path to the Android Debug Bridge (adb) executable. If the current
                                                     working directory is within the engine repository, defaults to
                                                     ./third_party/android_tools/sdk/platform-tools/adb.
    --ndk-stack=<path/to/ndk-stack>                  Path to the NDK stack tool. Defaults to the checked-in version in
                                                     third_party/android_tools if the current working directory is
                                                     within the engine repository on a supported platform.
```
