# Leak tracking in Flutter framework

Flutter Framework uses [leak_tracker](https://github.com/dart-lang/leak_tracker/blob/main/doc/leak_tracking/OVERVIEW.md) to auto-detect not disposed objects.

This page contains Flutter Framework related information.

See leak_tracker documentation for
[general leak troubleshooting](https://github.com/dart-lang/leak_tracker/blob/main/doc/leak_tracking/TROUBLESHOOT.md).

## When it is ok to opt-out from leak tracking?

In general, leak tracking should be enabled, to verify that all
disposables are disposed.
All exceptions should be clearly explained in the comments.

1. Hacky tests

    A test leaks because it uses APIs in non-recommended way
    and there is no simple way to either test what is needed
    in a recommended way or to dispose the objects.

2. Thrown exceptions

    Some leaks happen because exceptions are thrown and
    the code did not finalize properly.

    While some exceptions should not result in leaking objects,
    the project to make sure disposables are disposed
    in exceptional situations was not prioritized yet.

## Where leak tracking is configured?

Leak tracker is configured in [flutter_test_config.dart](https://github.com/flutter/flutter/blob/9441f8f6c806fb0a3b7d058a40b5e59c373e6055/packages/flutter/test/flutter_test_config.dart#L45).

To forcefully enable (or disable) leak tracking for flutter tests, pass
`--dart-define LEAK_TRACKING=true` (or false) to `flutter test`.

See [leak_tracker documentation](https://github.com/dart-lang/leak_tracker/blob/main/doc/leak_tracking/TROUBLESHOOT.md)
on how to enable/disable leak tracking for individual tests and files.

## What are defaults and how leaks are monitored?

Leak tracker is disabled for local runs and for all bots except two:

- [Windows framework_tests_libraries_leak_tracking](https://github.com/flutter/flutter/blob/9441f8f6c806fb0a3b7d058a40b5e59c373e6055/.ci.yaml#L5553)
- [Windows framework_tests_widgets_leak_tracking](https://github.com/flutter/flutter/blob/9441f8f6c806fb0a3b7d058a40b5e59c373e6055/.ci.yaml#L5640C11-L5640C56)

You can see the bots status on [Flutter dashboard](https://flutter-dashboard.appspot.com/#/build).
The bots are not blocking yet.
See [a proposal to convert them to be blocking](http://flutter.dev/go/leak-tracker-make-bots-blocking).
