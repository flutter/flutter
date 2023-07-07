## 1.9.5

* Updates code for `no_leading_underscores_for_local_identifiers` lint.

## 1.9.4

* Updates imports for `prefer_relative_imports`.

## 1.9.3

* Updates minimum Flutter version to 2.10.
* Removes `BuildParams` from v4 interface and adds `layoutDirection` to the creation params.

## 1.9.2

* Fixes avoid_redundant_argument_values lint warnings and minor typos.
* Ignores unnecessary import warnings in preparation for [upcoming Flutter changes](https://github.com/flutter/flutter/pull/106316).
* Adds missing build params for v4 WebViewWidget interface.

## 1.9.1

* Ignores unnecessary import warnings in preparation for [upcoming Flutter changes](https://github.com/flutter/flutter/pull/104231).

## 1.9.0

* Adds the first iteration of the v4 webview_flutter interface implementation.
* Removes unnecessary imports.

## 1.8.2

* Migrates from `ui.hash*` to `Object.hash*`.
* Updates minimum Flutter version to 2.5.0.

## 1.8.1

* Update to use the `verify` method introduced in platform_plugin_interface 2.1.0.

## 1.8.0

* Adds the `loadFlutterAsset` method to the platform interface.

## 1.7.0

* Add an option to set the background color of the webview.

## 1.6.1

* Revert deprecation of `clearCookies` in WebViewPlatform for later deprecation.

## 1.6.0

* Adds platform interface for cookie manager.
* Deprecates `clearCookies` in WebViewPlatform in favour of `CookieManager#clearCookies`.
* Expanded `CreationParams` to include cookies to be set at webview creation.

## 1.5.2

* Mirgrates from analysis_options_legacy.yaml to the more strict analysis_options.yaml.

## 1.5.1

* Reverts the addition of `onUrlChanged`, which was unintentionally a breaking
  change.

## 1.5.0

* Added `onUrlChanged` callback to platform callback handler.

## 1.4.0

* Added `loadFile` and `loadHtml` interface methods.

## 1.3.0

* Added `loadRequest` method to platform interface.

## 1.2.0

* Added `runJavascript` and `runJavascriptReturningResult` interface methods to supersede `evaluateJavascript`.

## 1.1.0

* Add `zoomEnabled` functionality to `WebSettings`.

## 1.0.0

* Extracted platform interface from `webview_flutter`.
