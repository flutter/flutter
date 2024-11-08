# Automated Flutter integration test suites

Each suite consists of either a complete Flutter app and a `flutter_driver`
specification that drives tests from the UI, or a native app that is meant to
integrate with Flutter for testing.

Intended for use with devicelab tests.

If you want to run a driver test locally, to debug a problem with a test, you
can use this command from the appropriate subdirectory:

```sh
flutter drive -t <test> --driver <driver>
```

For example:

```sh
flutter drive -t lib/keyboard_resize.dart --driver test_driver/keyboard_resize_test.dart
```
