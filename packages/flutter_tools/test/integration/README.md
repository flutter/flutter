# Integration tests

These tests are not hermetic, and use actual Flutter SDK.
While they don't require actual devices, they run `flutter_tester` to test
Dart VM and Flutter integration.

Some of these tests change the current directory for the process,
so only one test can be run at a time. Use this command to run:

```shell
../../bin/cache/dart-sdk/bin/pub run test -j1
```
