# external_textures

Tests external texture rendering between a native[^1] platform and Flutter.

## How it works

- Each `lib/*_main.dart` file is a Flutter app instrumenting a test case.
- There is a cooresponding `test_driver/*_test.dart` that runs assertions.

To run the test cases locally, use `flutter drive`[^2]:

```shell
flutter drive lib/frame_rate_main.dart --driver test_driver/frame_rate_test.dart
```

> [!TIP]
> On CI, the test cases are run within our [device lab](../../devicelab/README.md).
>
> See [`devicelab/lib/tasks/integration_tests.dart`](../../devicelab/lib/tasks/integration_tests.dart)
> and search for `createExternalTexturesIntegrationTest`.

[^1]: Only iOS and Android.
[^2]: Unfortunately documentation is quite limited. See [#142021](https://github.com/flutter/flutter/issues/142021).
