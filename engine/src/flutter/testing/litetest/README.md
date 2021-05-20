# package:litetest

This is a wrapper around `package:async_helper` from the Dart SDK source repo
at `//pkg/async_helper` that works in the environment of `flutter_tester`.
This wrapper is needed to ensure that all tests run to completion before the
process exits. This is accomplished by opening a `ReceivePort` for each test,
which is only closed when the test finishes running.

## Limitations

This package is intended only for use in the `flutter/engine` repo by unit
tests that run on `flutter_tester`. Even though the API resembles the API
provided by `package:test`, it has all the same limitations that
`package:async_helper` has.
