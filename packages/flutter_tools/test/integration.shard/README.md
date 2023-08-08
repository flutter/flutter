# Integration tests

These tests are not hermetic, and use the actual Flutter SDK. While
they don't require actual devices, they run `flutter_tester` to test
Dart VM and Flutter integration.

Use this command to run (from the `flutter_tools` directory):

```shell
../../bin/cache/dart-sdk/bin/dart run test test/integration.shard
```

You need to have downloaded the Dart SDK in your Flutter clone for this
to work. Running `../../bin/flutter` will automatically download it.

## Coverage exclusion

These tests are expensive to run and do not give meaningful coverage
information for the `flutter` tool (since they are black-box tests that
run the tool as a subprocess, rather than being unit tests). For this
reason, they are in a separate shard when running on continuous
integration and are not run when calculating coverage.
