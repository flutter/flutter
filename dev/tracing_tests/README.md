# Tracing tests

## "Application"

The `lib/test.dart` and `lib/control.dart` files in this directory are
used by `dev/bots/test.dart`'s `runTracingTests` function to check
whether aspects of the tracing logic in the framework get compiled out
in profile and release builds. They're not meant to be run directly.

The strings in these files are used in `dev/bots/test.dart`.

## Tests

The tests in this folder must be run with `flutter test --enable-vmservice`,
since they test that trace data is written to the timeline by connecting to
the VM service.

These tests will fail if run without this flag.
