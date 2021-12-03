# iOS Unit Tests

These are the unit tests for iOS engine.  They can be executed locally and are
also run in LUCI builds.

## Running Tests

To build and run the iOS tests, run the following script from the src directory:

```sh
flutter/testing/run_tests.py --type=objc
```

After the `ios_test_flutter` target is built you can also run the tests inside
of Xcode with `testing/ios/IosUnitTests/IosUnitTests.xcodeproj`.

When you load the test project [IosUnitTests.xcodeproj](IosUnitTests.xcodeproj)
into Xcode after running `run_tests.py`, only a few basic tests will appear
initially. You have to run the test suite once in Xcode for the rest to appear.
Select "iPhone 11" as the device, and press `command-u` to start all the tests
running. Once the tests are done running, the tests that ran will appear in the
sidebar, and you can pick the specific one you want to debug/run.

If you modify the test or under-test files, you'll have to run
[`run_tests.py`](../../run_tests.py) again.

## Adding Tests

When you add a new unit test file, also add a reference to that file in
[`shell/platform/darwin/ios/BUILD.gn`](../../../shell/platform/darwin/ios/BUILD.gn),
under the `sources` list of the `ios_test_flutter` target. Once it's there, it
will execute with the other tests.
