# external_textures

Tests external texture rendering between a native[^1] platform and Flutter.

Part of Flutter's API for [plugins](https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin) includes passing _external textures_, or textures
created outside of Flutter, to Flutter, typically using the [`Texture`][texture]
widget. This is useful for plugins that render video, or for plugins that
interact with the camera.

For example:

- [`packages/camera`][camera]
- [`packages/video_player`][video_player]

[texture]: https://api.flutter.dev/flutter/widgets/Texture-class.html
[camera]: https://github.com/flutter/packages/tree/8255fbed74465425a1ec06a1804225e705e29f52/packages/camera
[video_player]: https://github.com/flutter/packages/tree/8255fbed74465425a1ec06a1804225e705e29f52/packages/video_player

Because external textures are created outside of Flutter, there is often subtle
translation that needs to happen between the native platform and Flutter, which
is hard to observe. These integration tests are designed to help catch these
subtle translation issues.

## How it works

- Each `lib/*_main.dart` file is a Flutter app instrumenting a test case.
- There is a corresponding `test_driver/*_test.dart` that runs assertions.

To run the test cases locally, use `flutter drive`[^2]:

```sh
flutter drive lib/frame_rate_main.dart --driver test_driver/frame_rate_test.dart
```

> [!TIP]
> On CI, the test cases are run within our [device lab](../../devicelab/README.md).
>
> See [`devicelab/lib/tasks/integration_tests.dart`](../../devicelab/lib/tasks/integration_tests.dart)
> and search for `createExternalUiFrameRateIntegrationTest`.
>
> The actual tests are run by task runners:
>
> - [Android](../../devicelab/bin/tasks/external_textures_integration_test.dart)
> - [iOS](../../devicelab/bin/tasks/external_textures_integration_test_ios.dart)

[^1]: Only iOS and Android.
[^2]: Unfortunately documentation is quite limited. See [#142021](https://github.com/flutter/flutter/issues/142021).
