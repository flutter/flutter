# Forbidden from release tests

This program compiles the Dart portions of a Flutter application to the
AOT format used for release builds, and verifies that debugging related types
are not retained. By default, it uses the `//examples/hello_world` application
in this repository.

This harness is invoked from `dev/bots/test.dart`. By default it uses the
`examples/hello_world.dart` as if it were being compiled for Android arm64
release. New forbidden types may be added by adding more `--forbidden-type`
options in the `runForbiddenFromReleaseTests` method in `dev/bots/test.dart`
