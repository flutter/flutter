## 3.0.0

* Stable release for null safety.

## 3.0.0-nullsafety.1

* Make pedantic a dev_dependency.

## 3.0.0-nullsafety.0

- Enable null safety.

## v2.1.2

* Updated to latest version of sync_http.

## v2.1.1

* Forward-compatible fix for upcoming Dart SDK breaking change
  (`HttpClientResponse` implementing `Stream<Uint8List>`)

## v2.1.0

* Full support of JsonWire and W3C protocol specs in sync and async WebDriver.

## v2.0.0

* Dropped support for `pkg:unittest`.
* Add W3C spec mouse and keyboard support.
* Remove deprecated methods in async WebDriver.

The two big changes are the addition of support for synchronous communication
via the `package:sync_http` (along with an accompanying synchronous API) and
support for the W3C spec.

Currently, only the synchronous API supports the W3C spec, but in the future
both asynchronous and synchronous APIs will support this.

## v1.2.4
* Adds null check for status before checking status code.
  Avoids throwing exceptions if status code is not present. (Due to
  oversight this was never properly released.)

## v1.2.3

*  Enable generics for waitFor.

## v1.2.2+1

* Disable generics for waitFor.

## v1.2.2

*  Refactor tests.
*  Make project buildable and testable with Bazel.


## v1.2.1

* Enable redirects to handle 303 responses from Selenium.

## v1.2.0

* Fix all strong mode errors.

## v1.1.1

* Fix some analyzer warnings.
* `_performRequest` now uses `whenComplete`, not `finally` (#119).


## v1.1.0

* Added `WebDriver.captureScreenshotAsBase64()`, which returns the screenshot as
  a base64-encoded string.
* Added `WebDriver.captureScreenshotAsList()`, which returns the screenshot as
  list of uint8.
* Deprecated `WebDriver.captureScreenshot()` due to bad performance (#114).
  Please use the new screenshot methods instead.
* Removed dependency on crypto package.

Thanks to @blackhc and @xavierhainaux for the contributions.

## v1.0.0

No functional change, just bumping the version number.

## v0.10.0-pre.15

* Add Future-based listeners to `web_driver.dart`.
* Use google.com/ncr to avoid redirect when running outside US
* Add chords support to `keyboard.dart`.
* Add enum for mouse buttons (breaking API change!)

## v0.10.0-pre.14

* Adds support for enabling/disabling listeners to WebDriver.
* Adds `awaitChecking` mode to Lock class.

## v0.10.0-pre.13

* Lots of cleanup and new features.

## v0.10.0-pre.12

* Adds a Stepper interface and StdioStepper which allows control of execution of
  WebDriver commands.

## v0.10.0-pre.11

* Improve exception stack traces.
* Add option to `quit()` to not end the WebDriver session.

## v0.10.0-pre.10

* Minor updates.

## v0.10.0-pre.9

* Adds command listening.

## v0.10.0-pre.8

* Add `support/forwarder.dart`.
* Move `async_helpers.dart` to `support/async.dart`.

## v0.10.0-pre.7

* Fix expect implementation.

## v0.10.0-pre.6

* Fixes to pubspec.
* Added missing copyright notices.

## v0.10.0-pre.4

* Various cleanup.
* Change `captureScreenshot` to return Stream.

## v0.10.0-pre.3

* Rename some methods.
* Add `WebDriver.get()` and remove `WebDriver.navigate.to()`.

## v0.10.0-pre.2

* Added `close()` method to CommandProcessor that gets called by
  `WebDriver.quit()`.
* Ensure that HttpClient in _IOCommandProcessor gets closed.
* Add `fromExistingSession()` functions to allow creation of WebDriver instances
  connected to existing sessions.

## v0.10.0-pre.1

* Isolate HTTP code from the rest of the WebDriver implementation.
* Create support for running WebDriver from inside browser.
* Other cleanup.
