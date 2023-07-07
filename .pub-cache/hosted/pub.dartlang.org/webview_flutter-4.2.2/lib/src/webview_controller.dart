// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(a14n): remove this import once Flutter 3.1 or later reaches stable (including flutter/flutter#104231)
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'navigation_delegate.dart';
import 'webview_widget.dart';

/// Controls a WebView provided by the host platform.
///
/// Pass this to a [WebViewWidget] to display the WebView.
///
/// A [WebViewController] can only be used by a single [WebViewWidget] at a
/// time.
///
/// ## Platform-Specific Features
/// This class contains an underlying implementation provided by the current
/// platform. Once a platform implementation is imported, the examples below
/// can be followed to use features provided by a platform's implementation.
///
/// {@macro webview_flutter.WebViewController.fromPlatformCreationParams}
///
/// Below is an example of accessing the platform-specific implementation for
/// iOS and Android:
///
/// ```dart
/// final WebViewController webViewController = WebViewController();
///
/// if (WebViewPlatform.instance is WebKitWebViewPlatform) {
///   final WebKitWebViewController webKitController =
///       webViewController.platform as WebKitWebViewController;
/// } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
///   final AndroidWebViewController androidController =
///       webViewController.platform as AndroidWebViewController;
/// }
/// ```
class WebViewController {
  /// Constructs a [WebViewController].
  ///
  /// {@template webview_fluttter.WebViewController.constructor}
  /// `onPermissionRequest`: A callback that notifies the host application that
  /// web content is requesting permission to access the specified resources.
  /// To grant access for a device resource, most platforms will need to update
  /// their app configurations for the relevant system resource.
  ///
  /// For Android, you will need to update your `AndroidManifest.xml`. See
  /// https://developer.android.com/training/permissions/declaring
  ///
  /// For iOS, you will need to update your `Info.plist`. See
  /// https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy/requesting_access_to_protected_resources?language=objc.
  /// {@endtemplate}
  ///
  /// See [WebViewController.fromPlatformCreationParams] for setting parameters
  /// for a specific platform.
  WebViewController({
    void Function(WebViewPermissionRequest request)? onPermissionRequest,
  }) : this.fromPlatformCreationParams(
          const PlatformWebViewControllerCreationParams(),
          onPermissionRequest: onPermissionRequest,
        );

  /// Constructs a [WebViewController] from creation params for a specific
  /// platform.
  ///
  /// {@macro webview_fluttter.WebViewController.constructor}
  ///
  /// {@template webview_flutter.WebViewController.fromPlatformCreationParams}
  /// Below is an example of setting platform-specific creation parameters for
  /// iOS and Android:
  ///
  /// ```dart
  /// PlatformWebViewControllerCreationParams params =
  ///     const PlatformWebViewControllerCreationParams();
  ///
  /// if (WebViewPlatform.instance is WebKitWebViewPlatform) {
  ///   params = WebKitWebViewControllerCreationParams
  ///       .fromPlatformWebViewControllerCreationParams(
  ///     params,
  ///   );
  /// } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
  ///   params = AndroidWebViewControllerCreationParams
  ///       .fromPlatformWebViewControllerCreationParams(
  ///     params,
  ///   );
  /// }
  ///
  /// final WebViewController webViewController =
  ///     WebViewController.fromPlatformCreationParams(
  ///   params,
  /// );
  /// ```
  /// {@endtemplate}
  WebViewController.fromPlatformCreationParams(
    PlatformWebViewControllerCreationParams params, {
    void Function(WebViewPermissionRequest request)? onPermissionRequest,
  }) : this.fromPlatform(
          PlatformWebViewController(params),
          onPermissionRequest: onPermissionRequest,
        );

  /// Constructs a [WebViewController] from a specific platform implementation.
  ///
  /// {@macro webview_fluttter.WebViewController.constructor}
  WebViewController.fromPlatform(
    this.platform, {
    void Function(WebViewPermissionRequest request)? onPermissionRequest,
  }) {
    if (onPermissionRequest != null) {
      platform.setOnPlatformPermissionRequest(
        (PlatformWebViewPermissionRequest request) {
          onPermissionRequest(WebViewPermissionRequest._(
            request,
            types: request.types,
          ));
        },
      );
    }
  }

  /// Implementation of [PlatformWebViewController] for the current platform.
  final PlatformWebViewController platform;

  /// Loads the file located on the specified [absoluteFilePath].
  ///
  /// The [absoluteFilePath] parameter should contain the absolute path to the
  /// file as it is stored on the device. For example:
  /// `/Users/username/Documents/www/index.html`.
  ///
  /// Throws a `PlatformException` if the [absoluteFilePath] does not exist.
  Future<void> loadFile(String absoluteFilePath) {
    return platform.loadFile(absoluteFilePath);
  }

  /// Loads the Flutter asset specified in the pubspec.yaml file.
  ///
  /// Throws a `PlatformException` if [key] is not part of the specified assets
  /// in the pubspec.yaml file.
  Future<void> loadFlutterAsset(String key) {
    assert(key.isNotEmpty);
    return platform.loadFlutterAsset(key);
  }

  /// Loads the supplied HTML string.
  ///
  /// The [baseUrl] parameter is used when resolving relative URLs within the
  /// HTML string.
  Future<void> loadHtmlString(String html, {String? baseUrl}) {
    assert(html.isNotEmpty);
    return platform.loadHtmlString(html, baseUrl: baseUrl);
  }

  /// Makes a specific HTTP request and loads the response in the webview.
  ///
  /// [method] must be one of the supported HTTP methods in [LoadRequestMethod].
  ///
  /// If [headers] is not empty, its key-value pairs will be added as the
  /// headers for the request.
  ///
  /// If [body] is not null, it will be added as the body for the request.
  ///
  /// Throws an ArgumentError if [uri] has an empty scheme.
  Future<void> loadRequest(
    Uri uri, {
    LoadRequestMethod method = LoadRequestMethod.get,
    Map<String, String> headers = const <String, String>{},
    Uint8List? body,
  }) {
    if (uri.scheme.isEmpty) {
      throw ArgumentError('Missing scheme in uri: $uri');
    }
    return platform.loadRequest(LoadRequestParams(
      uri: uri,
      method: method,
      headers: headers,
      body: body,
    ));
  }

  /// Returns the current URL that the WebView is displaying.
  ///
  /// If no URL was ever loaded, returns `null`.
  Future<String?> currentUrl() {
    return platform.currentUrl();
  }

  /// Checks whether there's a back history item.
  Future<bool> canGoBack() {
    return platform.canGoBack();
  }

  /// Checks whether there's a forward history item.
  Future<bool> canGoForward() {
    return platform.canGoForward();
  }

  /// Goes back in the history of this WebView.
  ///
  /// If there is no back history item this is a no-op.
  Future<void> goBack() {
    return platform.goBack();
  }

  /// Goes forward in the history of this WebView.
  ///
  /// If there is no forward history item this is a no-op.
  Future<void> goForward() {
    return platform.goForward();
  }

  /// Reloads the current URL.
  Future<void> reload() {
    return platform.reload();
  }

  /// Sets the [NavigationDelegate] containing the callback methods that are
  /// called during navigation events.
  Future<void> setNavigationDelegate(NavigationDelegate delegate) {
    return platform.setPlatformNavigationDelegate(delegate.platform);
  }

  /// Clears all caches used by the WebView.
  ///
  /// The following caches are cleared:
  ///	1. Browser HTTP Cache.
  ///	2. [Cache API](https://developers.google.com/web/fundamentals/instant-and-offline/web-storage/cache-api)
  ///    caches. Service workers tend to use this cache.
  ///	3. Application cache.
  Future<void> clearCache() {
    return platform.clearCache();
  }

  /// Clears the local storage used by the WebView.
  Future<void> clearLocalStorage() {
    return platform.clearLocalStorage();
  }

  /// Runs the given JavaScript in the context of the current page.
  ///
  /// The Future completes with an error if a JavaScript error occurred.
  Future<void> runJavaScript(String javaScript) {
    return platform.runJavaScript(javaScript);
  }

  /// Runs the given JavaScript in the context of the current page, and returns
  /// the result.
  ///
  /// The Future completes with an error if a JavaScript error occurred, or if
  /// the type the given expression evaluates to is unsupported. Unsupported
  /// values include certain non-primitive types on iOS, as well as `undefined`
  /// or `null` on iOS 14+.
  Future<Object> runJavaScriptReturningResult(String javaScript) {
    return platform.runJavaScriptReturningResult(javaScript);
  }

  /// Adds a new JavaScript channel to the set of enabled channels.
  ///
  /// The JavaScript code can then call `postMessage` on that object to send a
  /// message that will be passed to [onMessageReceived].
  ///
  /// For example, after adding the following JavaScript channel:
  ///
  /// ```dart
  /// final WebViewController controller = WebViewController();
  /// controller.addJavaScriptChannel(
  ///   name: 'Print',
  ///   onMessageReceived: (JavascriptMessage message) {
  ///     print(message.message);
  ///   },
  /// );
  /// ```
  ///
  /// JavaScript code can call:
  ///
  /// ```javascript
  /// Print.postMessage('Hello');
  /// ```
  ///
  /// to asynchronously invoke the message handler which will print the message
  /// to standard output.
  ///
  /// Adding a new JavaScript channel only takes effect after the next page is
  /// loaded.
  ///
  /// A channel [name] cannot be the same for multiple channels.
  Future<void> addJavaScriptChannel(
    String name, {
    required void Function(JavaScriptMessage) onMessageReceived,
  }) {
    assert(name.isNotEmpty);
    return platform.addJavaScriptChannel(JavaScriptChannelParams(
      name: name,
      onMessageReceived: onMessageReceived,
    ));
  }

  /// Removes the JavaScript channel with the matching name from the set of
  /// enabled channels.
  ///
  /// This disables the channel with the matching name if it was previously
  /// enabled through the [addJavaScriptChannel].
  Future<void> removeJavaScriptChannel(String javaScriptChannelName) {
    return platform.removeJavaScriptChannel(javaScriptChannelName);
  }

  /// The title of the currently loaded page.
  Future<String?> getTitle() {
    return platform.getTitle();
  }

  /// Sets the scrolled position of this view.
  ///
  /// The parameters `x` and `y` specify the position to scroll to in WebView
  /// pixels.
  Future<void> scrollTo(int x, int y) {
    return platform.scrollTo(x, y);
  }

  /// Moves the scrolled position of this view.
  ///
  /// The parameters `x` and `y` specify the amount of WebView pixels to scroll
  /// by.
  Future<void> scrollBy(int x, int y) {
    return platform.scrollBy(x, y);
  }

  /// Returns the current scroll position of this view.
  ///
  /// Scroll position is measured from the top left.
  Future<Offset> getScrollPosition() {
    return platform.getScrollPosition();
  }

  /// Whether to support zooming using the on-screen zoom controls and gestures.
  Future<void> enableZoom(bool enabled) {
    return platform.enableZoom(enabled);
  }

  /// Sets the current background color of this view.
  Future<void> setBackgroundColor(Color color) {
    return platform.setBackgroundColor(color);
  }

  /// Sets the JavaScript execution mode to be used by the WebView.
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) {
    return platform.setJavaScriptMode(javaScriptMode);
  }

  /// Sets the value used for the HTTP `User-Agent:` request header.
  Future<void> setUserAgent(String? userAgent) {
    return platform.setUserAgent(userAgent);
  }
}

/// Permissions request when web content requests access to protected resources.
///
/// A response MUST be provided by calling [grant], [deny], or a method from
/// [platform].
///
/// ## Platform-Specific Features
/// This class contains an underlying implementation provided by the current
/// platform. Once a platform implementation is imported, the example below
/// can be followed to use features provided by a platform's implementation.
///
/// Below is an example of accessing the platform-specific implementation for
/// iOS and Android:
///
/// ```dart
/// final WebViewPermissionRequest request = ...;
///
/// if (WebViewPlatform.instance is WebKitWebViewPlatform) {
///   final WebKitWebViewPermissionRequest webKitRequest =
///       request.platform as WebKitWebViewPermissionRequest;
/// } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
///   final AndroidWebViewPermissionRequest androidRequest =
///       request.platform as AndroidWebViewPermissionRequest;
/// }
/// ```
@immutable
class WebViewPermissionRequest {
  const WebViewPermissionRequest._(this.platform, {required this.types});

  /// All resources access has been requested for.
  final Set<WebViewPermissionResourceType> types;

  /// Implementation of [PlatformWebViewPermissionRequest] for the current
  /// platform.
  final PlatformWebViewPermissionRequest platform;

  /// Grant permission for the requested resource(s).
  Future<void> grant() {
    return platform.grant();
  }

  /// Deny permission for the requested resource(s).
  Future<void> deny() {
    return platform.deny();
  }
}
