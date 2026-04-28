# iOS Unit Tests

These are the unit tests for the iOS engine, including both Objective-C (XCTest) and Swift (Swift Testing) suites. They can be executed locally and are also run in LUCI builds.

## Running Tests from command line

To build and run all iOS tests (both XCTest and Swift Testing suites), use the `run_tests` script from the `src` directory.

```sh
flutter/testing/run_tests.py --type=objc
```

And if you're on Apple Silicon:

```sh
./flutter/testing/run_tests.py \
  --type=objc \
  --ios-variant ios_debug_sim_unopt_arm64
```

The `.xcresult` is automatically removed after testing ends. To change this:

```sh
export FLUTTER_TEST_OUTPUTS_DIR=~/Desktop
```

To learn more:

```
flutter/testing/run_tests.py --help
```

## Running Tests from Xcode

After the tests are built, you can also run them inside of Xcode:
- For Objective-C tests (XCTest): Use `testing/ios/IosUnitTests/IosUnitTests.xcodeproj`.
- For Swift tests (Swift Testing): Use `testing/ios/IosSwiftTestingTests/IosSwiftTestingTests.xcodeproj`.

When you load the test project into Xcode after running `run_tests.py`, only a few basic tests will appear initially. You have to run the test suite once in Xcode for the rest to appear. Select "iPhone 11" as the device, and press `command-u` to start all the tests running. Once the tests are done running, the tests that ran will appear in the sidebar, and you can pick the specific one you want to debug/run.

If you modify the test or under-test files, you'll have to run [`run_tests.py`](../../run_tests.py) again.

## Adding Tests

When you add a new Objective-C unit test file, add a reference to that file in [`shell/platform/darwin/ios/BUILD.gn`](../../../shell/platform/darwin/ios/BUILD.gn), under the `sources` list of the `ios_test_flutter_xctest` target.

When you add a new Swift unit test file, add it to the `sources` list of the `ios_test_flutter_swift` target instead.
