// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../types/types.dart';
import 'webview_platform_callbacks_handler.dart';

/// Interface for talking to the webview's platform implementation.
///
/// An instance implementing this interface is passed to the `onWebViewPlatformCreated` callback that is
/// passed to [WebViewPlatformBuilder#onWebViewPlatformCreated].
///
/// Platform implementations that live in a separate package should extend this class rather than
/// implement it as webview_flutter does not consider newly added methods to be breaking changes.
/// Extending this class (using `extends`) ensures that the subclass will get the default
/// implementation, while platform implementations that `implements` this interface will be broken
/// by newly added [WebViewPlatformController] methods.
abstract class WebViewPlatformController {
  /// Creates a new WebViewPlatform.
  ///
  /// Callbacks made by the WebView will be delegated to `handler`.
  ///
  /// The `handler` parameter must not be null.
  // TODO(mvanbeusekom): Remove unused constructor parameter with the next
  // breaking change (see issue https://github.com/flutter/flutter/issues/94292).
  // ignore: avoid_unused_constructor_parameters
  WebViewPlatformController(WebViewPlatformCallbacksHandler handler);

  /// Loads the file located on the specified [absoluteFilePath].
  ///
  /// The [absoluteFilePath] parameter should contain the absolute path to the
  /// file as it is stored on the device. For example:
  /// `/Users/username/Documents/www/index.html`.
  ///
  /// Throws an ArgumentError if the [absoluteFilePath] does not exist.
  Future<void> loadFile(
    String absoluteFilePath,
  ) {
    throw UnimplementedError(
        'WebView loadFile is not implemented on the current platform');
  }

  /// Loads the Flutter asset specified in the pubspec.yaml file.
  ///
  /// Throws an ArgumentError if [key] is not part of the specified assets
  /// in the pubspec.yaml file.
  Future<void> loadFlutterAsset(
    String key,
  ) {
    throw UnimplementedError(
        'WebView loadFlutterAsset is not implemented on the current platform');
  }

  /// Loads the supplied HTML string.
  ///
  /// The [baseUrl] parameter is used when resolving relative URLs within the
  /// HTML string.
  Future<void> loadHtmlString(
    String html, {
    String? baseUrl,
  }) {
    throw UnimplementedError(
        'WebView loadHtmlString is not implemented on the current platform');
  }

  /// Loads the specified URL.
  ///
  /// If `headers` is not null and the URL is an HTTP URL, the key value paris in `headers` will
  /// be added as key value pairs of HTTP headers for the request.
  ///
  /// `url` must not be null.
  ///
  /// Throws an ArgumentError if `url` is not a valid URL string.
  Future<void> loadUrl(
    String url,
    Map<String, String>? headers,
  ) {
    throw UnimplementedError(
        'WebView loadUrl is not implemented on the current platform');
  }

  /// Makes a specific HTTP request ands loads the response in the webview.
  ///
  /// [WebViewRequest.method] must be one of the supported HTTP methods
  /// in [WebViewRequestMethod].
  ///
  /// If [WebViewRequest.headers] is not empty, its key-value pairs will be
  /// added as the headers for the request.
  ///
  /// If [WebViewRequest.body] is not null, it will be added as the body
  /// for the request.
  ///
  /// Throws an ArgumentError if [WebViewRequest.uri] has empty scheme.
  Future<void> loadRequest(
    WebViewRequest request,
  ) {
    throw UnimplementedError(
        'WebView loadRequest is not implemented on the current platform');
  }

  /// Updates the webview settings.
  ///
  /// Any non null field in `settings` will be set as the new setting value.
  /// All null fields in `settings` are ignored.
  Future<void> updateSettings(WebSettings setting) {
    throw UnimplementedError(
        'WebView updateSettings is not implemented on the current platform');
  }

  /// Accessor to the current URL that the WebView is displaying.
  ///
  /// If no URL was ever loaded, returns `null`.
  Future<String?> currentUrl() {
    throw UnimplementedError(
        'WebView currentUrl is not implemented on the current platform');
  }

  /// Checks whether there's a back history item.
  Future<bool> canGoBack() {
    throw UnimplementedError(
        'WebView canGoBack is not implemented on the current platform');
  }

  /// Checks whether there's a forward history item.
  Future<bool> canGoForward() {
    throw UnimplementedError(
        'WebView canGoForward is not implemented on the current platform');
  }

  /// Goes back in the history of this WebView.
  ///
  /// If there is no back history item this is a no-op.
  Future<void> goBack() {
    throw UnimplementedError(
        'WebView goBack is not implemented on the current platform');
  }

  /// Goes forward in the history of this WebView.
  ///
  /// If there is no forward history item this is a no-op.
  Future<void> goForward() {
    throw UnimplementedError(
        'WebView goForward is not implemented on the current platform');
  }

  /// Reloads the current URL.
  Future<void> reload() {
    throw UnimplementedError(
        'WebView reload is not implemented on the current platform');
  }

  /// Clears all caches used by the [WebView].
  ///
  /// The following caches are cleared:
  ///	1. Browser HTTP Cache.
  ///	2. [Cache API](https://developers.google.com/web/fundamentals/instant-and-offline/web-storage/cache-api) caches.
  ///    These are not yet supported in iOS WkWebView. Service workers tend to use this cache.
  ///	3. Application cache.
  ///	4. Local Storage.
  Future<void> clearCache() {
    throw UnimplementedError(
        'WebView clearCache is not implemented on the current platform');
  }

  /// Evaluates a JavaScript expression in the context of the current page.
  ///
  /// The Future completes with an error if a JavaScript error occurred, or if the type of the
  /// evaluated expression is not supported (e.g on iOS not all non-primitive types can be evaluated).
  Future<String> evaluateJavascript(String javascript) {
    throw UnimplementedError(
        'WebView evaluateJavascript is not implemented on the current platform');
  }

  /// Runs the given JavaScript in the context of the current page.
  ///
  /// The Future completes with an error if a JavaScript error occurred.
  Future<void> runJavascript(String javascript) {
    throw UnimplementedError(
        'WebView runJavascript is not implemented on the current platform');
  }

  /// Runs the given JavaScript in the context of the current page, and returns the result.
  ///
  /// The Future completes with an error if a JavaScript error occurred, or if the
  /// type the given expression evaluates to is unsupported. Unsupported values include
  /// certain non-primitive types on iOS, as well as `undefined` or `null` on iOS 14+.
  Future<String> runJavascriptReturningResult(String javascript) {
    throw UnimplementedError(
        'WebView runJavascriptReturningResult is not implemented on the current platform');
  }

  /// Adds new JavaScript channels to the set of enabled channels.
  ///
  /// For each value in this list the platform's webview should make sure that a corresponding
  /// property with a postMessage method is set on `window`. For example for a JavaScript channel
  /// named `Foo` it should be possible for JavaScript code executing in the webview to do
  ///
  /// ```javascript
  /// Foo.postMessage('hello');
  /// ```
  ///
  /// See also: [CreationParams.javascriptChannelNames].
  Future<void> addJavascriptChannels(Set<String> javascriptChannelNames) {
    throw UnimplementedError(
        'WebView addJavascriptChannels is not implemented on the current platform');
  }

  /// Removes JavaScript channel names from the set of enabled channels.
  ///
  /// This disables channels that were previously enabled by [addJavascriptChannels] or through
  /// [CreationParams.javascriptChannelNames].
  Future<void> removeJavascriptChannels(Set<String> javascriptChannelNames) {
    throw UnimplementedError(
        'WebView removeJavascriptChannels is not implemented on the current platform');
  }

  /// Returns the title of the currently loaded page.
  Future<String?> getTitle() {
    throw UnimplementedError(
        'WebView getTitle is not implemented on the current platform');
  }

  /// Set the scrolled position of this view.
  ///
  /// The parameters `x` and `y` specify the position to scroll to in WebView pixels.
  Future<void> scrollTo(int x, int y) {
    throw UnimplementedError(
        'WebView scrollTo is not implemented on the current platform');
  }

  /// Move the scrolled position of this view.
  ///
  /// The parameters `x` and `y` specify the amount of WebView pixels to scroll by.
  Future<void> scrollBy(int x, int y) {
    throw UnimplementedError(
        'WebView scrollBy is not implemented on the current platform');
  }

  /// Return the horizontal scroll position of this view.
  ///
  /// Scroll position is measured from left.
  Future<int> getScrollX() {
    throw UnimplementedError(
        'WebView getScrollX is not implemented on the current platform');
  }

  /// Return the vertical scroll position of this view.
  ///
  /// Scroll position is measured from top.
  Future<int> getScrollY() {
    throw UnimplementedError(
        'WebView getScrollY is not implemented on the current platform');
  }
}
