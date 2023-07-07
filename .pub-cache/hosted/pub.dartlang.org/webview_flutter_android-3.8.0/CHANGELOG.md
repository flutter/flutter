## 3.8.0

* Adds support for handling geolocation permissions. See
  `AndroidWebViewController.setGeolocationPermissionsPromptCallbacks`.

## 3.7.1

* Removes obsolete null checks on non-nullable values.

## 3.7.0

* Adds support to accept third party cookies. See
  `AndroidWebViewCookieManager.setAcceptThirdPartyCookies`.

## 3.6.3

* Updates gradle, AGP and fixes some lint errors.

## 3.6.2

* Fixes compatibility with AGP versions older than 4.2.

## 3.6.1

* Adds a namespace for compatibility with AGP 8.0.

## 3.6.0

* Adds support for `PlatformWebViewController.setOnPlatformPermissionRequest`.

## 3.5.3

* Bumps gradle from 7.2.2 to 8.0.0.

## 3.5.2

* Updates internal Java InstanceManager to only stop finalization callbacks when stopped.

## 3.5.1

* Updates pigeon dev dependency to `9.2.4`.
* Fixes Android lint warnings.

## 3.5.0

* Adds support for `PlatformNavigationDelegate.onUrlChange`.
* Bumps androidx.webkit:webkit from 1.6.0 to 1.6.1.
* Fixes common typos in tests and documentation.

## 3.4.5

* Removes unused internal `WebView` field and Java class.

## 3.4.4

* Fixes a bug where the native `WebView` wouldn't be traversed for autofill automatically.
* Updates minimum Flutter version to 3.3.

## 3.4.3

* Updates internal Java InstanceManager to be cleared on hot restart.

## 3.4.2

* Clarifies explanation of endorsement in README.

## 3.4.1

* Fixes a potential bug where a `WebView` that was not added to the `InstanceManager` could be
  returned by a `WebViewClient` or `WebChromeClient`.

## 3.4.0

* Adds support to set text zoom of a page. See `AndroidWebViewController.setTextZoom`.
* Aligns Dart and Flutter SDK constraints.

## 3.3.2

* Resolves compilations warnings.
* Updates compileSdkVersion to 33.
* Bumps androidx.webkit:webkit from 1.5.0 to 1.6.0.

## 3.3.1

* Updates links for the merge of flutter/plugins into flutter/packages.

## 3.3.0

* Adds support to access native `WebView`.

## 3.2.4

* Renames Pigeon output files.

## 3.2.3

* Fixes bug that prevented the web view from being garbage collected.
* Fixes bug causing a `LateInitializationError` when a `PlatformNavigationDelegate` is not provided.

## 3.2.2

* Updates example code for `use_build_context_synchronously` lint.

## 3.2.1

* Updates code for stricter lint checks.

## 3.2.0

* Adds support for handling file selection. See `AndroidWebViewController.setOnShowFileSelector`.
* Updates pigeon dev dependency to `4.2.14`.

## 3.1.3

* Fixes crash when the Java `InstanceManager` was used after plugin was removed from the engine.

## 3.1.2

* Fixes bug where an `AndroidWebViewController` couldn't be reused with a new `WebViewWidget`.

## 3.1.1

* Fixes bug where a `AndroidNavigationDelegate` was required to load a request.

## 3.1.0

* Adds support for selecting Hybrid Composition on versions 23+. Please use
  `AndroidWebViewControllerCreationParams.displayWithHybridComposition`.

## 3.0.0

* **BREAKING CHANGE** Updates platform implementation to `2.0.0` release of
  `webview_flutter_platform_interface`. See
  [webview_flutter](https://pub.dev/packages/webview_flutter/versions/4.0.0) for updated usage.

## 2.10.4

* Updates code for `no_leading_underscores_for_local_identifiers` lint.
* Bumps androidx.annotation from 1.4.0 to 1.5.0.

## 2.10.3

* Updates imports for `prefer_relative_imports`.

## 2.10.2

* Adds a getter to expose the Java InstanceManager.

## 2.10.1

* Adds a method to the `WebView` wrapper to retrieve the X and Y positions simultaneously.
* Removes reference to https://github.com/flutter/flutter/issues/97744 from `README`.

## 2.10.0

* Bumps webkit from 1.0.0 to 1.5.0.
* Raises minimum `compileSdkVersion` to 32.

## 2.9.5

* Adds dispose methods for HostApi and FlutterApi of JavaObject.

## 2.9.4

* Fixes avoid_redundant_argument_values lint warnings and minor typos.
* Bumps gradle from 7.2.1 to 7.2.2.

## 2.9.3

* Updates the Dart InstanceManager to take a listener for when an object is garbage collected.
  See https://github.com/flutter/flutter/issues/107199.

## 2.9.2

* Updates the Java InstanceManager to take a listener for when an object is garbage collected.
  See https://github.com/flutter/flutter/issues/107199.

## 2.9.1

* Updates Android WebView classes as Copyable. This is a part of moving the api to handle garbage
  collection automatically. See https://github.com/flutter/flutter/issues/107199.

## 2.9.0

* Ignores unnecessary import warnings in preparation for [upcoming Flutter changes](https://github.com/flutter/flutter/pull/106316).
* Fixes bug where `Directionality` from context didn't affect `SurfaceAndroidWebView`.
* Fixes bug where default text direction was different for `SurfaceAndroidWebView` and `AndroidWebView`.
  Default is now `TextDirection.ltr` for both.
* Fixes bug where setting WebView to a transparent background could cause visual errors when using
  `SurfaceAndroidWebView`. Hybrid composition is now used when the background color is not 100%
  opaque.
* Raises minimum Flutter version to 3.0.0.

## 2.8.14

* Bumps androidx.annotation from 1.0.0 to 1.4.0.

## 2.8.13

* Fixes a bug which causes an exception when the `onNavigationRequestCallback` return `false`.

## 2.8.12

* Bumps mockito-inline from 3.11.1 to 4.6.1.

## 2.8.11

* Ignores unnecessary import warnings in preparation for [upcoming Flutter changes](https://github.com/flutter/flutter/pull/104231).

## 2.8.10

* Updates references to the obsolete master branch.

## 2.8.9

* Updates Gradle to 7.2.1.

## 2.8.8

* Minor fixes for new analysis options.

## 2.8.7

* Removes unnecessary imports.
* Fixes library_private_types_in_public_api, sort_child_properties_last and use_key_in_widget_constructors
  lint warnings.

## 2.8.6

* Updates pigeon developer dependency to the latest version which adds support for null safety.

## 2.8.5

* Migrates deprecated `Scaffold.showSnackBar` to `ScaffoldMessenger` in example app.

## 2.8.4

* Fixes bug preventing `mockito` code generation for tests.
* Fixes regression where local storage wasn't cleared when `WebViewController.clearCache` was
  called.

## 2.8.3

* Fixes a bug causing `debuggingEnabled` to always be set to true.
* Fixes an integration test race condition.

## 2.8.2

* Adds the `WebSettings.setAllowFileAccess()` method and ensure that file access is allowed when the `WebViewAndroidWidget.loadFile()` method is executed.

## 2.8.1

* Fixes bug where the default user agent string was being set for every rebuild. See
  https://github.com/flutter/flutter/issues/94847.

## 2.8.0

* Implements new cookie manager for setting cookies and providing initial cookies.

## 2.7.0

* Adds support for the `loadRequest` method from the platform interface.

## 2.6.0

* Adds implementation of the `loadFlutterAsset` method from the platform interface.

## 2.5.0

* Adds an option to set the background color of the webview.

## 2.4.0

* Adds support for Android's `WebView.loadData` and `WebView.loadDataWithBaseUrl` methods and implements the `loadFile` and `loadHtmlString` methods from the platform interface.
* Updates to webview_flutter_platform_interface version 1.5.2.

## 2.3.1

* Adds explanation on how to generate the pigeon communication layer and mockito mock objects.
* Updates compileSdkVersion to 31.

## 2.3.0

* Replaces platform implementation with API built with pigeon.

## 2.2.1

* Fix `NullPointerException` from a race condition when changing focus. This only affects `WebView`
when it is created without Hybrid Composition.

## 2.2.0

* Implemented new `runJavascript` and `runJavascriptReturningResult` methods in platform interface.

## 2.1.0

* Add `zoomEnabled` functionality.

## 2.0.15

* Added Overrides in  FlutterWebView.java

## 2.0.14

* Update example App so navigation menu loads immediatly but only becomes available when `WebViewController` is available (same behavior as example App in webview_flutter package).

## 2.0.13

* Extract Android implementation from `webview_flutter`.
