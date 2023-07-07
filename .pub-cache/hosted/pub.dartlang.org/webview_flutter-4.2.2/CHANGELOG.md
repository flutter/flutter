## 4.2.2

* Fixes documentation typo.

## 4.2.1

* Removes obsolete null checks on non-nullable values.

## 4.2.0

* Adds support to receive permission requests. See `WebViewController(onPermissionRequest)`.

## 4.1.0

* Adds support to track URL changes. See `NavigationDelegate(onUrlChange)`.
* Updates minimum Flutter version to 3.3.
* Fixes common typos in tests and documentation.
* Fixes documentation for `WebViewController` and `WebViewCookieManager`.

## 4.0.7

* Updates the README with the migration of `WebView.initialCookies` and Hybrid Composition on
  Android.

## 4.0.6

* Updates iOS minimum version in README.

## 4.0.5

* Updates links for the merge of flutter/plugins into flutter/packages.

## 4.0.4

* Adds examples of accessing platform-specific features for each class.

## 4.0.3

* Updates example code for `use_build_context_synchronously` lint.

## 4.0.2

* Updates code for stricter lint checks.

## 4.0.1

* Exposes `WebResourceErrorType` from platform interface.

## 4.0.0

* **BREAKING CHANGE** Updates implementation to use the `2.0.0` release of
  `webview_flutter_platform_interface`. See `Usage` section in the README for updated usage. See
  `Migrating from 3.0 to 4.0` section in the README for details on migrating to this version.
* Updates minimum Flutter version to 3.0.0.
* Updates code for new analysis options.
* Updates references to the obsolete master branch.

## 3.0.4

* Minor fixes for new analysis options.

## 3.0.3

* Removes unnecessary imports.
* Fixes library_private_types_in_public_api, sort_child_properties_last and use_key_in_widget_constructors
  lint warnings.

## 3.0.2

* Migrates deprecated `Scaffold.showSnackBar` to `ScaffoldMessenger` in example app.
* Adds OS version support information to README.

## 3.0.1

* Removes a duplicate Android-specific integration test.
* Fixes an integration test race condition.
* Fixes comments (accidentally mixed // with ///).

## 3.0.0

* **BREAKING CHANGE**: On Android, hybrid composition (SurfaceAndroidWebView)
  is now the default. The previous default, virtual display, can be specified
  with `WebView.platform = AndroidWebView()`

## 2.8.0

* Adds support for the `loadFlutterAsset` method.

## 2.7.0

* Adds `setCookie` to CookieManager.
* CreationParams now supports setting `initialCookies`.

## 2.6.0

* Adds support for the `loadRequest` method.

## 2.5.0

* Adds an option to set the background color of the webview.

## 2.4.0

* Adds support for the `loadFile` and `loadHtmlString` methods.
* Updates example app Android compileSdkVersion to 31.
* Integration test fixes.
* Updates code for new analysis options.

## 2.3.1

* Add iOS-specific note to set `JavascriptMode.unrestricted` in order to set `zoomEnabled: false`.

## 2.3.0

* Add ability to enable/disable zoom functionality.

## 2.2.0

* Added `runJavascript` and `runJavascriptForResult` to supersede `evaluateJavascript`.
* Deprecated `evaluateJavascript`.

## 2.1.2

* Fix typos in the README.

## 2.1.1

* Fixed `_CastError` that was thrown when running the example App.

## 2.1.0

* Migrated to fully federated architecture.

## 2.0.14

* Update minimum Flutter SDK to 2.5 and iOS deployment target to 9.0.

## 2.0.13

* Send URL of File to download to the NavigationDelegate on Android just like it is already done on iOS.
* Updated Android lint settings.

## 2.0.12

* Improved the documentation on using the different Android Platform View modes.
* So that Android and iOS behave the same, `onWebResourceError` is now only called for the main
  page.

## 2.0.11

* Remove references to the Android V1 embedding.

## 2.0.10

* Fix keyboard issues link in the README.

## 2.0.9

* Add iOS UI integration test target.
* Suppress deprecation warning for iOS APIs deprecated in iOS 9.

## 2.0.8

* Migrate maven repository from jcenter to mavenCentral.

## 2.0.7

* Republished 2.0.6 with Flutter 2.2 to avoid https://github.com/dart-lang/pub/issues/3001

## 2.0.6

* WebView requires at least Android 19 if you are using
hybrid composition ([flutter/issues/59894](https://github.com/flutter/flutter/issues/59894)).

## 2.0.5

* Example app observes `uiMode`, so the WebView isn't reattached when the UI mode changes. (e.g. switching to Dark mode).

## 2.0.4

* Fix a bug where `allowsInlineMediaPlayback` is not respected on iOS.

## 2.0.3

* Fixes bug where scroll bars on the Android non-hybrid WebView are rendered on
the wrong side of the screen.

## 2.0.2

* Fixes bug where text fields are hidden behind the keyboard
when hybrid composition is used [flutter/issues/75667](https://github.com/flutter/flutter/issues/75667).

## 2.0.1

* Run CocoaPods iOS tests in RunnerUITests target

## 2.0.0

* Migration to null-safety.
* Added support for progress tracking.
* Add section to the wiki explaining how to use Material components.
* Update integration test to workaround an iOS 14 issue with `evaluateJavascript`.
* Fix `onWebResourceError` on iOS.
* Fix outdated links across a number of markdown files ([#3276](https://github.com/flutter/plugins/pull/3276))
* Added `allowsInlineMediaPlayback` property.

## 1.0.8

* Update Flutter SDK constraint.

## 1.0.7

* Minor documentation update to indicate known issue on iOS 13.4 and 13.5.
  * See: https://github.com/flutter/flutter/issues/53490

## 1.0.6

* Invoke the WebView.onWebResourceError on iOS when the webview content process crashes.

## 1.0.5

* Fix example in the readme.

## 1.0.4

* Suppress the `deprecated_member_use` warning in the example app for `ScaffoldMessenger.showSnackBar`.

## 1.0.3

* Update android compileSdkVersion to 29.

## 1.0.2

* Android Code Inspection and Clean up.

## 1.0.1

* Add documentation for `WebViewPlatformCreatedCallback`.

## 1.0.0 - Out of developer preview 🎉.

* Bumped the minimal Flutter SDK to 1.22 where platform views are out of developer preview, and
performing better on iOS. Flutter 1.22 no longer requires adding the
`io.flutter.embedded_views_preview` flag to `Info.plist`.

* Added support for Hybrid Composition on Android (see opt-in instructions in [README](https://github.com/flutter/plugins/blob/main/packages/webview_flutter/README.md#android))
  * Lowered the required Android API to 19 (was previously 20): [#23728](https://github.com/flutter/flutter/issues/23728).
  * Fixed the following issues:
    * 🎹 Keyboard: [#41089](https://github.com/flutter/flutter/issues/41089), [#36478](https://github.com/flutter/flutter/issues/36478), [#51254](https://github.com/flutter/flutter/issues/51254), [#50716](https://github.com/flutter/flutter/issues/50716), [#55724](https://github.com/flutter/flutter/issues/55724),  [#56513](https://github.com/flutter/flutter/issues/56513), [#56515](https://github.com/flutter/flutter/issues/56515), [#61085](https://github.com/flutter/flutter/issues/61085), [#62205](https://github.com/flutter/flutter/issues/62205), [#62547](https://github.com/flutter/flutter/issues/62547), [#58943](https://github.com/flutter/flutter/issues/58943), [#56361](https://github.com/flutter/flutter/issues/56361), [#56361](https://github.com/flutter/flutter/issues/42902), [#40716](https://github.com/flutter/flutter/issues/40716), [#37989](https://github.com/flutter/flutter/issues/37989), [#27924](https://github.com/flutter/flutter/issues/27924).
    * ♿️ Accessibility: [#50716](https://github.com/flutter/flutter/issues/50716).
    * ⚡️ Performance: [#61280](https://github.com/flutter/flutter/issues/61280), [#31243](https://github.com/flutter/flutter/issues/31243),  [#52211](https://github.com/flutter/flutter/issues/52211).
    * 📹 Video: [#5191](https://github.com/flutter/flutter/issues/5191).

## 0.3.24

* Keep handling deprecated Android v1 classes for backward compatibility.

## 0.3.23

* Handle WebView multi-window support.

## 0.3.22+2

* Update package:e2e reference to use the local version in the flutter/plugins
  repository.

## 0.3.22+1

* Update the `setAndGetScrollPosition` to use hard coded values and add a `pumpAndSettle` call.

## 0.3.22

* Add support for passing a failing url.

## 0.3.21

* Enable programmatic scrolling using Android's WebView.scrollTo & iOS WKWebView.scrollView.contentOffset.

## 0.3.20+2

* Fix CocoaPods podspec lint warnings.

## 0.3.20+1

* OCMock module import -> #import, unit tests compile generated as library.
* Fix select drop down crash on old Android tablets (https://github.com/flutter/flutter/issues/54164).

## 0.3.20

* Added support for receiving web resource loading errors. See `WebView.onWebResourceError`.

## 0.3.19+10

* Replace deprecated `getFlutterEngine` call on Android.

## 0.3.19+9

* Remove example app's iOS workspace settings.

## 0.3.19+8

* Make the pedantic dev_dependency explicit.

## 0.3.19+7

* Remove the Flutter SDK constraint upper bound.

## 0.3.19+6

* Enable opening links that target the "_blank" window (links open in same window).

## 0.3.19+5

* On iOS, always keep contentInsets of the WebView to be 0.
* Fix XCTest case to follow XCTest naming convention.

## 0.3.19+4

* On iOS, fix the scroll view content inset is automatically adjusted. After the fix, the content position of the WebView is customizable by Flutter.
* Fix an iOS 13 bug where the scroll indicator shows at random location.

## 0.3.19+3

* Setup XCTests.

## 0.3.19+2

* Migrate from deprecated BinaryMessages to ServicesBinding.instance.defaultBinaryMessenger.

## 0.3.19+1

* Raise min Flutter SDK requirement to the latest stable. v2 embedding apps no
  longer need to special case their Flutter SDK requirement like they have
  since v0.3.15+3.

## 0.3.19

* Add setting for iOS to allow gesture based navigation.

## 0.3.18+1

* Be explicit that keyboard is not ready for production in README.md.

## 0.3.18

* Add support for onPageStarted event.
* Remove the deprecated `author:` field from pubspec.yaml
* Migrate to the new pubspec platforms manifest.
* Require Flutter SDK 1.10.0 or greater.

## 0.3.17

* Fix pedantic lint errors. Added missing documentation and awaited some futures
  in tests and the example app.

## 0.3.16

* Add support for async NavigationDelegates. Synchronous NavigationDelegates
  should still continue to function without any change in behavior.

## 0.3.15+3

* Re-land support for the v2 Android embedding. This correctly sets the minimum
  SDK to the latest stable and avoid any compile errors. *WARNING:* the V2
  embedding itself still requires the current Flutter master channel
  (flutter/flutter@1d4d63a) for text input to work properly on all Android
  versions.

## 0.3.15+2

* Remove AndroidX warnings.

## 0.3.15+1

* Revert the prior embedding support add since it requires an API that hasn't
  rolled to stable.

## 0.3.15

* Add support for the v2 Android embedding. This shouldn't affect existing
  functionality. Plugin authors who use the V2 embedding can now register the
  plugin and expect that it correctly responds to app lifecycle changes.

## 0.3.14+2

* Define clang module for iOS.

## 0.3.14+1

* Allow underscores anywhere for Javascript Channel name.

## 0.3.14

* Added a getTitle getter to WebViewController.

## 0.3.13

* Add an optional `userAgent` property to set a custom User Agent.

## 0.3.12+1

* Temporarily revert getTitle (doing this as a patch bump shortly after publishing).

## 0.3.12

* Added a getTitle getter to WebViewController.

## 0.3.11+6

* Calling destroy on Android webview when flutter webview is getting disposed.

## 0.3.11+5

* Reduce compiler warnings regarding iOS9 compatibility by moving a single
  method back into a `@available` block.

## 0.3.11+4

* Removed noisy log messages on iOS.

## 0.3.11+3

* Apply the display listeners workaround that was shipped in 0.3.11+1 on
  all Android versions prior to P.

## 0.3.11+2

* Add fix for input connection being dropped after a screen resize on certain
  Android devices.

## 0.3.11+1

* Work around a bug in old Android WebView versions that was causing a crash
  when resizing the webview on old devices.

## 0.3.11

* Add an initialAutoMediaPlaybackPolicy setting for controlling how auto media
  playback is restricted.

## 0.3.10+5

* Add dependency on `androidx.annotation:annotation:1.0.0`.

## 0.3.10+4

* Add keyboard text to README.

## 0.3.10+3

* Don't log an unknown setting key error for 'debuggingEnabled' on iOS.

## 0.3.10+2

* Fix InputConnection being lost when combined with route transitions.

## 0.3.10+1

* Add support for simultaenous Flutter `TextInput` and WebView text fields.

## 0.3.10

* Add partial WebView keyboard support for Android versions prior to N. Support
  for UIs that also have Flutter `TextInput` fields is still pending. This basic
  support currently only works with Flutter `master`. The keyboard will still
  appear when it previously did not when run with older versions of Flutter. But
  if the WebView is resized while showing the keyboard the text field will need
  to be focused multiple times for any input to be registered.

## 0.3.9+2

* Update Dart code to conform to current Dart formatter.

## 0.3.9+1

* Add missing template type parameter to `invokeMethod` calls.
* Bump minimum Flutter version to 1.5.0.
* Replace invokeMethod with invokeMapMethod wherever necessary.

## 0.3.9

* Allow external packages to provide webview implementations for new platforms.

## 0.3.8+1

* Suppress deprecation warning for BinaryMessages. See: https://github.com/flutter/flutter/issues/33446

## 0.3.8

* Add `debuggingEnabled` property.

## 0.3.7+1

* Fix an issue where JavaScriptChannel messages weren't sent from the platform thread on Android.

## 0.3.7

* Fix loadUrlWithHeaders flaky test.

## 0.3.6+1

* Remove un-used method params in webview\_flutter

## 0.3.6

* Add an optional `headers` field to the controller.

## 0.3.5+5

* Fixed error in documentation of `javascriptChannels`.

## 0.3.5+4

* Fix bugs in the example app by updating it to use a `StatefulWidget`.

## 0.3.5+3

* Make sure to post javascript channel messages from the platform thread.

## 0.3.5+2

* Fix crash from `NavigationDelegate` on later versions of Android.

## 0.3.5+1

* Fix a bug where updates to onPageFinished were ignored.

## 0.3.5

* Added an onPageFinished callback.

## 0.3.4

* Support specifying navigation delegates that can prevent navigations from being executed.

## 0.3.3+2

* Exclude LongPress handler from semantics tree since it does nothing.

## 0.3.3+1

* Fixed a memory leak on Android - the WebView was not properly disposed.

## 0.3.3

* Add clearCache method to WebView controller.

## 0.3.2+1

* Log a more detailed warning at build time about the previous AndroidX
  migration.

## 0.3.2

* Added CookieManager to interface with WebView cookies. Currently has the ability to clear cookies.

## 0.3.1

* Added JavaScript channels to facilitate message passing from JavaScript code running inside
  the WebView to the Flutter app's Dart code.

## 0.3.0

* **Breaking change**. Migrate from the deprecated original Android Support
  Library to AndroidX. This shouldn't result in any functional changes, but it
  requires any Android apps using this plugin to [also
  migrate](https://developer.android.com/jetpack/androidx/migrate) if they're
  using the original support library.

## 0.2.0

* Added a evaluateJavascript method to WebView controller.
* (BREAKING CHANGE) Renamed the `JavaScriptMode` enum to `JavascriptMode`, and the WebView `javasScriptMode` parameter to `javascriptMode`.

## 0.1.2

* Added a reload method to the WebView controller.

## 0.1.1

* Added a `currentUrl` accessor for the WebView controller to look up what URL
  is being displayed.

## 0.1.0+1

* Fix null crash when initialUrl is unset on iOS.

## 0.1.0

* Add goBack, goForward, canGoBack, and canGoForward methods to the WebView controller.

## 0.0.1+1

* Fix case for "FLTWebViewFlutterPlugin" (iOS was failing to buld on case-sensitive file systems).

## 0.0.1

* Initial release.
