# CHANGELOG

This changelog was discontinued after version 0.9.2+2, when the package started
to vend from the Flutter SDK rather than pub.

It is maintained here for historical purposes only.

## 0.9.2+2

* Broaden the constraint on vm_service.

## 0.9.2+1

* Update android compileSdkVersion to 29.

## 0.9.2

* Add `watchPerformance` for performance test.

## 0.9.1

* Keep handling deprecated Android v1 classes for backward compatibility.

## 0.9.0

* Add screenshot capability to web tests.

## 0.8.2

* Add support to get timeline.

## 0.8.1

* Show stack trace of widget test errors on the platform side
* Fix method channel name for iOS

## 0.8.0

* Rename plugin to integration_test.

## 0.7.0

* Move utilities for tracking frame performance in an e2e test to `flutter_test`.

## 0.6.3

* Add customizable `flutter_driver` adaptor.
* Add utilities for tracking frame performance in an e2e test.

## 0.6.2+1

* Fix incorrect test results when one test passes then another fails

## 0.6.2

* Fix `setSurfaceSize` for e2e tests

## 0.6.1

* Added `data` in the reported json.

## 0.6.0

* **Breaking change** `E2EPlugin` exports a `Future` for `testResults`.

## 0.5.0+1

* Fixed the device pixel ratio problem.

## 0.5.0

* **Breaking change** by default, tests will use the device window size.
  Tests can still override the window size by using the `setSurfaceSize` method.
* **Breaking change** If using Flutter 1.19.0-2.0.pre.196 or greater, the
  `testTextInput` will no longer automatically register.
* **Breaking change** If using Flutter 1.19.0-2.0.pre.196 or greater, the
  `HttpOverrides` will no longer be set by default.
* Minor formatting changes to Dart code.

## 0.4.3+3

* Fixed code snippet in readme that referenced a non-existent `result` variable.

## 0.4.3+2

* Bumps AGP to 3.6.3
* Changes android-retrofuture dependency type to "implementation"

## 0.4.3+1

* Post-v2 Android embedding cleanup.

## 0.4.3

* Uses CompletableFuture from android-retrofuture allow compatibility with API < 24.

## 0.4.2

* Adds support for Android E2E tests that utilize other @Rule's, like GrantPermissionRule.
* Fix CocoaPods podspec lint warnings.

## 0.4.1

* Remove Android dependencies fallback.
* Require Flutter SDK 1.12.13+hotfix.5 or greater.

## 0.4.0

* **Breaking change** Driver request_data call's response has changed to
  encapsulate the failure details.
* Details for failure cases are added: failed method name, stack trace.

## 0.3.0+1

* Replace deprecated `getFlutterEngine` call on Android.

## 0.3.0

* Updates documentation to instruct developers not to launch the activity since
  we are doing it for them.
* Renames `FlutterRunner` to `FlutterTestRunner` to avoid conflict with Fuchsia.

## 0.2.4+4

* Fixed a hang that occurred on platforms that don't have a `MethodChannel` listener registered..

## 0.2.4+3

* Fixed code snippet in the readme under the "Using Flutter driver to run tests" section.

## 0.2.4+2

* Make the pedantic dev_dependency explicit.

## 0.2.4+1

* Registering web service extension for using e2e with web.

## 0.2.4

* Fixed problem with XCTest in XCode 11.3 where the testing bundles were getting
  opened multiple times which interfered with the singleton logic for E2EPlugin.

## 0.2.3+1

* Added a driver test for failure behavior.

## 0.2.3

* Updates `E2EPlugin` and add skeleton iOS test case `E2EIosTest`.
* Adds instructions to README.md about e2e testing on iOS devices.
* Adds iOS e2e testing to example.

## 0.2.2+3

* Remove the deprecated `author:` field from pubspec.yaml
* Migrate the plugin to the pubspec platforms manifest.
* Require Flutter SDK 1.10.0 or greater.

## 0.2.2+2

* Adds an android dummy project to silence warnings and removes unnecessary
  .gitignore files.

## 0.2.2+1

* Fix pedantic lints. Adds a missing await in the example test and some missing
  documentation.

## 0.2.2

* Added a stub macos implementation
* Added a macos example

## 0.2.1+1

* Updated README.

## 0.2.1

* Support the v2 Android embedder.
* Print a warning if the plugin is not registered.
* Updated method channel name.
* Set a Flutter minimum SDK version.

## 0.2.0+1

* Updated README.

## 0.2.0

* Renamed package from instrumentation_adapter to e2e.
* Refactored example app test.
* **Breaking change**. Renamed `InstrumentationAdapterFlutterBinding` to
  `IntegrationTestWidgetsFlutterBinding`.
* Updated README.

## 0.1.4

* Migrate example to AndroidX.
* Define clang module for iOS.

## 0.1.3

* Added example app.
* Added stub iOS implementation.
* Updated README.
* No longer throws errors when running tests on the host.

## 0.1.2

* Added support for running tests using Flutter driver.

## 0.1.1

* Updates about using *androidx* library.

## 0.1.0

* Update boilerplate test to use `@Rule` instead of `FlutterTest`.

## 0.0.2

* Document current usage instructions, which require adding a Java test file.

## 0.0.1

* Initial release
