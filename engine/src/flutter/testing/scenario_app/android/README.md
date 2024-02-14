# Scenario App: Android Tests

As mentioned in the [top-level README](../README.md), this directory contains
the Android-specific native code and tests for the [scenario app](../lib). To
run the tests, you will need to build the engine with the appropriate
configuration.

For example, `android_debug_unopt` or `android_debug_unopt_arm64` was built,
run:

```sh
# From the root of the engine repository
$ ./testing/run_android_tests.sh android_debug_unopt

# Or, for arm64
$ ./testing/run_android_tests.sh android_debug_unopt_arm64
```

## CI Configuration

See [`ci/builders/linux_android_emulator.json`](../../../ci/builders/linux_android_emulator.json)
, and grep for `run_android_tests.sh`.

The following matrix of configurations is tested on the CI:

| API Version | Graphics Backend    | Skia Gold                                                        | Rationale                                                  |
| ----------- | ------------------- | ---------------------------------------------------------------- | ---------------------------------------------------------- |
| 28          | Skia                | [Android 28 + Skia][skia-gold-skia-28]                           | Older Android devices (without `ImageReader`) on Skia.     |
| 28          | Impeller (OpenGLES) | [Android 28 + Impeller OpenGLES][skia-gold-impeller-opengles-28] | Older Android devices (without `ImageReader`) on Impeller. |
| 34          | Skia                | [Android 34 + Skia][skia-gold-skia-34]                           | Newer Android devices on Skia.                             |
| 34          | Impeller (OpenGLES) | [Android 34 + Impeller OpenGLES][skia-gold-impeller-opengles-34] | Newer Android devices on Impeller with OpenGLES.           |
| 34          | Impeller (Vulkan)   | [Android 34 + Impeller Vulkan][skia-gold-impeller-vulkan-34]     | Newer Android devices on Impeller.                         |

[skia-gold-skia-28]: https://flutter-engine-gold.skia.org/search?left_filter=AndroidAPILevel%3D28%26GraphicsBackend%3Dskia&negative=true&positive=true
[skia-gold-impeller-opengles-28]: https://flutter-engine-gold.skia.org/search?left_filter=AndroidAPILevel%3D28%26GraphicsBackend%3Dimpeller-opengles&negative=true&positive=true
[skia-gold-skia-34]: https://flutter-engine-gold.skia.org/search?left_filter=AndroidAPILevel%3D34%26GraphicsBackend%3Dskia&negative=true&positive=true
[skia-gold-impeller-opengles-34]: https://flutter-engine-gold.skia.org/search?left_filter=AndroidAPILevel%3D34%26GraphicsBackend%3Dimpeller-opengles&negative=true&positive=true
[skia-gold-impeller-vulkan-34]: https://flutter-engine-gold.skia.org/search?left_filter=AndroidAPILevel%3D34%26GraphicsBackend%3Dimpeller-vulkan&negative=true&positive=true

## Updating Gradle dependencies

See [Updating the Embedding Dependencies](../../../tools/cipd/android_embedding_bundle/README.md).
