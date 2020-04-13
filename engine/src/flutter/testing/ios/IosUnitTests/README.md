# iOS Unit Tests

These are the unit tests for iOS engine.  They can be executed locally and are
also run in LUCI builds.

## Running Tests

```sh
./flutter/tools/gn --ios --simulator --unoptimized
cd flutter/testing/ios/IosUnitTests
./build_and_run_tests.sh
```

After the `ios_flutter_test` target is built you can also run the tests inside
of xcode with `IosUnitTests.xcodeproj`.

## Adding Tests

When you add a new unit test file, also add a reference to that file in
shell/platform/darwin/ios/BUILD.gn, under the `sources` list of the
`ios_flutter_test` target. Once it's there, it will execute with the other
tests.
