# `AndroidNativeDriver` Tests

This directory are tests that require an Android device or emulator to run.

To run locally, connect an Android device or start an emulator and run:

```bash
# Assumuing your current working directory is `packages/flutter_driver`.\

$ flutter test test/src/native_tests/android
```

On CI, these tests are run via [`run_flutter_driver_android_tests.dart`][ci].

[ci]: ../../../../../../dev/bots/suite_runners/run_flutter_driver_android_tests.dart
