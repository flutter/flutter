# iOS Unit Tests

These are the unit tests for iOS engine.  They can be executed locally and are
also run in LUCI builds.

## Running Tests

```sh
testing/run_tests.py [--type=objc]
```

After the `ios_test_flutter` target is built you can also run the tests inside
of Xcode with `testing/ios/IosUnitTests/IosUnitTests.xcodeproj`. If you
modify the test or under-test files, you'll have to run `run_tests.py` again.

## Adding Tests

When you add a new unit test file, also add a reference to that file in
shell/platform/darwin/ios/BUILD.gn, under the `sources` list of the
`ios_test_flutter` target. Once it's there, it will execute with the other
tests.
