## 3.5.0

* Adds support to limit navigation to pages within the app’s domain. See
  `WebKitWebViewControllerCreationParams.limitsNavigationsToAppBoundDomains`.

## 3.4.4

* Removes obsolete null checks on non-nullable values.

## 3.4.3

* Replace `describeEnum` with the `name` getter.

## 3.4.2

* Fixes an exception caused by the `onUrlChange` callback passing a null `NSUrl`.

## 3.4.1

* Fixes internal type conversion error.
* Adds internal unknown enum values to handle api updates.

## 3.4.0

* Adds support for `PlatformWebViewController.setOnPlatformPermissionRequest`.

## 3.3.0

* Adds support for `PlatformNavigationDelegate.onUrlChange`.

## 3.2.4

* Updates pigeon to fix warnings with clang 15.
* Updates minimum Flutter version to 3.3.
* Fixes common typos in tests and documentation.

## 3.2.3

* Updates to `pigeon` version 7.

## 3.2.2

* Changes Objective-C to use relative imports.

## 3.2.1

* Clarifies explanation of endorsement in README.
* Aligns Dart and Flutter SDK constraints.

## 3.2.0

* Updates minimum Flutter version to 3.3 and iOS 11.

## 3.1.1

* Updates links for the merge of flutter/plugins into flutter/packages.

## 3.1.0

* Adds support to access native `WKWebView`.

## 3.0.5

* Renames Pigeon output files.

## 3.0.4

* Fixes bug that prevented the web view from being garbage collected.

## 3.0.3

* Updates example code for `use_build_context_synchronously` lint.

## 3.0.2

* Updates code for stricter lint checks.

## 3.0.1

* Adds support for retrieving navigation type with internal class.
* Updates README with details on contributing.
* Updates pigeon dev dependency to `4.2.13`.

## 3.0.0

* **BREAKING CHANGE** Updates platform implementation to `2.0.0` release of
  `webview_flutter_platform_interface`. See
  [webview_flutter](https://pub.dev/packages/webview_flutter/versions/4.0.0) for updated usage.
* Updates code for `no_leading_underscores_for_local_identifiers` lint.

## 2.9.5

* Updates imports for `prefer_relative_imports`.

## 2.9.4

* Fixes avoid_redundant_argument_values lint warnings and minor typos.
* Fixes typo in an internal method name, from `setCookieForInsances` to `setCookieForInstances`.

## 2.9.3

* Updates `webview_flutter_platform_interface` constraint to the correct minimum
  version.

## 2.9.2

* Fixes crash when an Objective-C object in `FWFInstanceManager` is released, but the dealloc
  callback is no longer available.

## 2.9.1

* Fixes regression where the behavior for the `UIScrollView` insets were removed.

## 2.9.0

* Ignores unnecessary import warnings in preparation for [upcoming Flutter changes](https://github.com/flutter/flutter/pull/106316).
* Replaces platform implementation with WebKit API built with pigeon.

## 2.8.1

* Ignores unnecessary import warnings in preparation for [upcoming Flutter changes](https://github.com/flutter/flutter/pull/104231).

## 2.8.0

* Raises minimum Dart version to 2.17 and Flutter version to 3.0.0.

## 2.7.5

* Minor fixes for new analysis options.

## 2.7.4

* Removes unnecessary imports.
* Fixes library_private_types_in_public_api, sort_child_properties_last and use_key_in_widget_constructors
  lint warnings.

## 2.7.3

* Removes two occurrences of the compiler warning: "'RequiresUserActionForMediaPlayback' is deprecated: first deprecated in ios 10.0".

## 2.7.2

* Fixes an integration test race condition.
* Migrates deprecated `Scaffold.showSnackBar` to `ScaffoldMessenger` in example app.

## 2.7.1

* Fixes header import for cookie manager to be relative only.

## 2.7.0

* Adds implementation of the `loadFlutterAsset` method from the platform interface.

## 2.6.0

* Implements new cookie manager for setting cookies and providing initial cookies.

## 2.5.0

* Adds an option to set the background color of the webview.
* Migrates from `analysis_options_legacy.yaml` to `analysis_options.yaml`.
* Integration test fixes.
* Updates to webview_flutter_platform_interface version 1.5.2.

## 2.4.0

* Implemented new `loadFile` and `loadHtmlString` methods from the platform interface.

## 2.3.0

* Implemented new `loadRequest` method from platform interface.

## 2.2.0

* Implemented new `runJavascript` and `runJavascriptReturningResult` methods in platform interface.

## 2.1.0

* Add `zoomEnabled` functionality.

## 2.0.14

* Update example App so navigation menu loads immediatly but only becomes available when `WebViewController` is available (same behavior as example App in webview_flutter package).

## 2.0.13

* Extract WKWebView implementation from `webview_flutter`.
