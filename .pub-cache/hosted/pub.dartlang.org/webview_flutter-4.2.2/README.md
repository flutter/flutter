# WebView for Flutter

<?code-excerpt path-base="excerpts/packages/webview_flutter_example"?>

[![pub package](https://img.shields.io/pub/v/webview_flutter.svg)](https://pub.dev/packages/webview_flutter)

A Flutter plugin that provides a WebView widget.

On iOS the WebView widget is backed by a [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview).
On Android the WebView widget is backed by a [WebView](https://developer.android.com/reference/android/webkit/WebView).

|             | Android        | iOS   |
|-------------|----------------|-------|
| **Support** | SDK 19+ or 20+ | 11.0+ |

## Usage
Add `webview_flutter` as a [dependency in your pubspec.yaml file](https://pub.dev/packages/webview_flutter/install).

You can now display a WebView by:

1. Instantiating a [WebViewController](https://pub.dev/documentation/webview_flutter/latest/webview_flutter/WebViewController-class.html).

<?code-excerpt "simple_example.dart (webview_controller)"?>
```dart
controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..setBackgroundColor(const Color(0x00000000))
  ..setNavigationDelegate(
    NavigationDelegate(
      onProgress: (int progress) {
        // Update loading bar.
      },
      onPageStarted: (String url) {},
      onPageFinished: (String url) {},
      onWebResourceError: (WebResourceError error) {},
      onNavigationRequest: (NavigationRequest request) {
        if (request.url.startsWith('https://www.youtube.com/')) {
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
    ),
  )
  ..loadRequest(Uri.parse('https://flutter.dev'));
```

2. Passing the controller to a [WebViewWidget](https://pub.dev/documentation/webview_flutter/latest/webview_flutter/WebViewWidget-class.html).

<?code-excerpt "simple_example.dart (webview_widget)"?>
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Flutter Simple Example')),
    body: WebViewWidget(controller: controller),
  );
}
```

See the Dartdocs for [WebViewController](https://pub.dev/documentation/webview_flutter/latest/webview_flutter/WebViewController-class.html)
and [WebViewWidget](https://pub.dev/documentation/webview_flutter/latest/webview_flutter/WebViewWidget-class.html)
for more details.

### Android Platform Views

This plugin uses
[Platform Views](https://flutter.dev/docs/development/platform-integration/platform-views) to embed
the Android’s WebView within the Flutter app.

You should however make sure to set the correct `minSdkVersion` in `android/app/build.gradle` if it was previously lower than 19:

```groovy
android {
    defaultConfig {
        minSdkVersion 19
    }
}
```

### Platform-Specific Features

Many classes have a subclass or an underlying implementation that provides access to platform-specific
features.

To access platform-specific features, start by adding the platform implementation packages to your
app or package:

* **Android**: [webview_flutter_android](https://pub.dev/packages/webview_flutter_android/install)
* **iOS**: [webview_flutter_wkwebview](https://pub.dev/packages/webview_flutter_wkwebview/install)

Next, add the imports of the implementation packages to your app or package:

<?code-excerpt "main.dart (platform_imports)"?>
```dart
// Import for Android features.
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import for iOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
```

Now, additional features can be accessed through the platform implementations. Classes
[WebViewController], [WebViewWidget], [NavigationDelegate], and [WebViewCookieManager] pass their
functionality to a class provided by the current platform. Below are a couple of ways to access
additional functionality provided by the platform and is followed by an example.

1. Pass a creation params class provided by a platform implementation to a `fromPlatformCreationParams`
   constructor (e.g. `WebViewController.fromPlatformCreationParams`,
   `WebViewWidget.fromPlatformCreationParams`, etc.).
2. Call methods on a platform implementation of a class by using the `platform` field (e.g.
   `WebViewController.platform`, `WebViewWidget.platform`, etc.).

Below is an example of setting additional iOS and Android parameters on the `WebViewController`.

<?code-excerpt "main.dart (platform_features)"?>
```dart
late final PlatformWebViewControllerCreationParams params;
if (WebViewPlatform.instance is WebKitWebViewPlatform) {
  params = WebKitWebViewControllerCreationParams(
    allowsInlineMediaPlayback: true,
    mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
  );
} else {
  params = const PlatformWebViewControllerCreationParams();
}

final WebViewController controller =
    WebViewController.fromPlatformCreationParams(params);
// ···
if (controller.platform is AndroidWebViewController) {
  AndroidWebViewController.enableDebugging(true);
  (controller.platform as AndroidWebViewController)
      .setMediaPlaybackRequiresUserGesture(false);
}
```

See https://pub.dev/documentation/webview_flutter_android/latest/webview_flutter_android/webview_flutter_android-library.html
for more details on Android features.

See https://pub.dev/documentation/webview_flutter_wkwebview/latest/webview_flutter_wkwebview/webview_flutter_wkwebview-library.html
for more details on iOS features.

### Enable Material Components for Android

To use Material Components when the user interacts with input elements in the WebView,
follow the steps described in the [Enabling Material Components instructions](https://flutter.dev/docs/deployment/android#enabling-material-components).

### Setting custom headers on POST requests

Currently, setting custom headers when making a post request with the WebViewController's `loadRequest` method is not supported on Android.
If you require this functionality, a workaround is to make the request manually, and then load the response data using `loadHtmlString` instead.

## Migrating from 3.0 to 4.0

### Instantiating WebViewController

In version 3.0 and below, `WebViewController` could only be retrieved in a callback after the
`WebView` was added to the widget tree. Now, `WebViewController` must be instantiated and can be
used before it is added to the widget tree. See `Usage` section above for an example.

### Replacing WebView Functionality

The `WebView` class has been removed and its functionality has been split into `WebViewController`
and `WebViewWidget`.

`WebViewController` handles all functionality that is associated with the underlying web view
provided by each platform. (e.g., loading a url, setting the background color of the underlying
platform view, or clearing the cache).

`WebViewWidget` takes a `WebViewController` and handles all Flutter widget related functionality
(e.g., layout direction, gesture recognizers).

See the Dartdocs for [WebViewController](https://pub.dev/documentation/webview_flutter/latest/webview_flutter/WebViewController-class.html)
and [WebViewWidget](https://pub.dev/documentation/webview_flutter/latest/webview_flutter/WebViewWidget-class.html)
for more details.

### PlatformView Implementation on Android

The PlatformView implementation for Android uses Texture Layer Hybrid Composition on versions 23+
and automatically fallbacks to Hybrid Composition for version 19-23. See section
`Platform-Specific Features` and [AndroidWebViewWidgetCreationParams.displayWithHybridComposition](https://pub.dev/documentation/webview_flutter_android/latest/webview_flutter_android/AndroidWebViewWidgetCreationParams/displayWithHybridComposition.html)
to manually switch to Hybrid Composition on versions 23+.

### API Changes

Below is a non-exhaustive list of changes to the API:

* `WebViewController.clearCache` no longer clears local storage. Please use
  `WebViewController.clearLocalStorage`.
* `WebViewController.clearCache` no longer reloads the page.
* `WebViewController.loadUrl` has been removed. Please use `WebViewController.loadRequest`.
* `WebViewController.evaluateJavascript` has been removed. Please use
  `WebViewController.runJavaScript` or `WebViewController.runJavaScriptReturningResult`.
* `WebViewController.getScrollX` and `WebViewController.getScrollY` have been removed and have
  been replaced by `WebViewController.getScrollPosition`.
* `WebViewController.runJavaScriptReturningResult` now returns an `Object` and not a `String`. This
  will attempt to return a `bool` or `num` if the return value can be parsed.
* `WebView.initialCookies` has been removed. Use `WebViewCookieManager.setCookie` before calling
  `WebViewController.loadRequest`.
* `CookieManager` is replaced by `WebViewCookieManager`.
* `NavigationDelegate.onWebResourceError` callback includes errors that are not from the main frame.
   Use the `WebResourceError.isForMainFrame` field to filter errors.
* The following fields from `WebView` have been moved to `NavigationDelegate`. They can be added to
  a WebView with `WebViewController.setNavigationDelegate`.
  * `WebView.navigationDelegate` -> `NavigationDelegate.onNavigationRequest`
  * `WebView.onPageStarted` -> `NavigationDelegate.onPageStarted`
  * `WebView.onPageFinished` -> `NavigationDelegate.onPageFinished`
  * `WebView.onProgress` -> `NavigationDelegate.onProgress`
  * `WebView.onWebResourceError` -> `NavigationDelegate.onWebResourceError`
* The following fields from `WebView` have been moved to `WebViewController`:
  * `WebView.javascriptMode` -> `WebViewController.setJavaScriptMode`
  * `WebView.javascriptChannels` ->
    `WebViewController.addJavaScriptChannel`/`WebViewController.removeJavaScriptChannel`
  * `WebView.zoomEnabled` -> `WebViewController.enableZoom`
  * `WebView.userAgent` -> `WebViewController.setUserAgent`
  * `WebView.backgroundColor` -> `WebViewController.setBackgroundColor`
* The following features have been moved to an Android implementation class. See section
  `Platform-Specific Features` for details on accessing Android platform-specific features.
  * `WebView.debuggingEnabled` -> `static AndroidWebViewController.enableDebugging`
  * `WebView.initialMediaPlaybackPolicy` -> `AndroidWebViewController.setMediaPlaybackRequiresUserGesture`
* The following features have been moved to an iOS implementation class. See section
  `Platform-Specific Features` for details on accessing iOS platform-specific features.
  * `WebView.gestureNavigationEnabled` -> `WebKitWebViewController.setAllowsBackForwardNavigationGestures`
  * `WebView.initialMediaPlaybackPolicy` -> `WebKitWebViewControllerCreationParams.mediaTypesRequiringUserAction`
  * `WebView.allowsInlineMediaPlayback` -> `WebKitWebViewControllerCreationParams.allowsInlineMediaPlayback`

<!-- Links -->
[WebViewController]: https://pub.dev/documentation/webview_flutter/latest/webview_flutter/WebViewController-class.html
[WebViewWidget]: https://pub.dev/documentation/webview_flutter/latest/webview_flutter/WebViewWidget-class.html
[NavigationDelegate]: https://pub.dev/documentation/webview_flutter/latest/webview_flutter/NavigationDelegate-class.html
[WebViewCookieManager]: https://pub.dev/documentation/webview_flutter/latest/webview_flutter/WebViewCookieManager-class.html