# Integration tests

These tests are not hermetic, and use actual Flutter SDK.
While they don't require actual devices, they run `flutter_tester` to test
Dart VM and Flutter integration.

Use this command to run:

```shell
../../bin/cache/dart-sdk/bin/pub run test
```
