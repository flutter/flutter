// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'platform_navigation_delegate.dart';
import 'webview_platform.dart';

/// Interface for a platform implementation of a web view controller.
///
/// Platform implementations should extend this class rather than implement it
/// as `webview_flutter` does not consider newly added methods to be breaking
/// changes. Extending this class (using `extends`) ensures that the subclass
/// will get the default implementation, while platform implementations that
/// `implements` this interface will be broken by newly added
/// [PlatformWebViewCookieManager] methods.
abstract class PlatformWebViewController extends PlatformInterface {
  /// Creates a new [PlatformWebViewController]
  factory PlatformWebViewController(
      PlatformWebViewControllerCreationParams params) {
    final PlatformWebViewController webViewControllerDelegate =
        WebViewPlatform.instance!.createPlatformWebViewController(params);
    PlatformInterface.verify(webViewControllerDelegate, _token);
    return webViewControllerDelegate;
  }

  /// Used by the platform implementation to create a new [PlatformWebViewController].
  ///
  /// Should only be used by platform implementations because they can't extend
  /// a class that only contains a factory constructor.
  @protected
  PlatformWebViewController.implementation(this.params) : super(token: _token);

  static final Object _token = Object();

  /// The parameters used to initialize the [PlatformWebViewController].
  final PlatformWebViewControllerCreationParams params;

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
        'loadFile is not implemented on the current platform');
  }

  /// Loads the Flutter asset specified in the pubspec.yaml file.
  ///
  /// Throws an ArgumentError if [key] is not part of the specified assets
  /// in the pubspec.yaml file.
  Future<void> loadFlutterAsset(
    String key,
  ) {
    throw UnimplementedError(
        'loadFlutterAsset is not implemented on the current platform');
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
        'loadHtmlString is not implemented on the current platform');
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
    LoadRequestParams params,
  ) {
    throw UnimplementedError(
        'loadRequest is not implemented on the current platform');
  }

  /// Accessor to the current URL that the WebView is displaying.
  ///
  /// If no URL was ever loaded, returns `null`.
  Future<String?> currentUrl() {
    throw UnimplementedError(
        'currentUrl is not implemented on the current platform');
  }

  /// Checks whether there's a back history item.
  Future<bool> canGoBack() {
    throw UnimplementedError(
        'canGoBack is not implemented on the current platform');
  }

  /// Checks whether there's a forward history item.
  Future<bool> canGoForward() {
    throw UnimplementedError(
        'canGoForward is not implemented on the current platform');
  }

  /// Goes back in the history of this WebView.
  ///
  /// If there is no back history item this is a no-op.
  Future<void> goBack() {
    throw UnimplementedError(
        'goBack is not implemented on the current platform');
  }

  /// Goes forward in the history of this WebView.
  ///
  /// If there is no forward history item this is a no-op.
  Future<void> goForward() {
    throw UnimplementedError(
        'goForward is not implemented on the current platform');
  }

  /// Reloads the current URL.
  Future<void> reload() {
    throw UnimplementedError(
        'reload is not implemented on the current platform');
  }

  /// Clears all caches used by the [WebView].
  ///
  /// The following caches are cleared:
  ///	1. Browser HTTP Cache.
  ///	2. [Cache API](https://developers.google.com/web/fundamentals/instant-and-offline/web-storage/cache-api) caches.
  ///    These are not yet supported in iOS WkWebView. Service workers tend to use this cache.
  ///	3. Application cache.
  Future<void> clearCache() {
    throw UnimplementedError(
        'clearCache is not implemented on the current platform');
  }

  /// Clears the local storage used by the [WebView].
  Future<void> clearLocalStorage() {
    throw UnimplementedError(
        'clearLocalStorage is not implemented on the current platform');
  }

  /// Sets the [PlatformNavigationDelegate] containing the callback methods that
  /// are called during navigation events.
  Future<void> setPlatformNavigationDelegate(
      PlatformNavigationDelegate handler) {
    throw UnimplementedError(
        'setPlatformNavigationDelegate is not implemented on the current platform');
  }

  /// Runs the given JavaScript in the context of the current page.
  ///
  /// The Future completes with an error if a JavaScript error occurred.
  Future<void> runJavaScript(String javaScript) {
    throw UnimplementedError(
        'runJavaScript is not implemented on the current platform');
  }

  /// Runs the given JavaScript in the context of the current page, and returns the result.
  ///
  /// The Future completes with an error if a JavaScript error occurred, or if the
  /// type the given expression evaluates to is unsupported. Unsupported values include
  /// certain non-primitive types on iOS, as well as `undefined` or `null` on iOS 14+.
  Future<String> runJavaScriptReturningResult(String javaScript) {
    throw UnimplementedError(
        'runJavaScriptReturningResult is not implemented on the current platform');
  }

  /// Adds a new JavaScript channel to the set of enabled channels.
  Future<void> addJavaScriptChannel(
    JavaScriptChannelParams javaScriptChannelParams,
  ) {
    throw UnimplementedError(
        'addJavaScriptChannel is not implemented on the current platform');
  }

  /// Removes the JavaScript channel with the matching name from the set of
  /// enabled channels.
  ///
  /// This disables the channel with the matching name if it was previously
  /// enabled through the [addJavaScriptChannel].
  Future<void> removeJavaScriptChannel(String javaScriptChannelName) {
    throw UnimplementedError(
        'removeJavaScriptChannel is not implemented on the current platform');
  }

  /// Returns the title of the currently loaded page.
  Future<String?> getTitle() {
    throw UnimplementedError(
        'getTitle is not implemented on the current platform');
  }

  /// Set the scrolled position of this view.
  ///
  /// The parameters `x` and `y` specify the position to scroll to in WebView pixels.
  Future<void> scrollTo(int x, int y) {
    throw UnimplementedError(
        'scrollTo is not implemented on the current platform');
  }

  /// Move the scrolled position of this view.
  ///
  /// The parameters `x` and `y` specify the amount of WebView pixels to scroll by.
  Future<void> scrollBy(int x, int y) {
    throw UnimplementedError(
        'scrollBy is not implemented on the current platform');
  }

  /// Return the current scroll position of this view.
  ///
  /// Scroll position is measured from the top left.
  Future<Point<int>> getScrollPosition() {
    throw UnimplementedError(
        'getScrollPosition is not implemented on the current platform');
  }

  /// Whether to enable the platform's webview content debugging tools.
  Future<void> enableDebugging(bool enabled) {
    throw UnimplementedError(
        'enableDebugging is not implemented on the current platform');
  }

  /// Whether to allow swipe based navigation on supported platforms.
  Future<void> enableGestureNavigation(bool enabled) {
    throw UnimplementedError(
        'enableGestureNavigation is not implemented on the current platform');
  }

  /// Whhether to support zooming using its on-screen zoom controls and gestures.
  Future<void> enableZoom(bool enabled) {
    throw UnimplementedError(
        'enableZoom is not implemented on the current platform');
  }

  /// Set the current background color of this view.
  Future<void> setBackgroundColor(Color color) {
    throw UnimplementedError(
        'setBackgroundColor is not implemented on the current platform');
  }

  /// Sets the JavaScript execution mode to be used by the webview.
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) {
    throw UnimplementedError(
        'setJavaScriptMode is not implemented on the current platform');
  }

  /// Sets the value used for the HTTP `User-Agent:` request header.
  Future<void> setUserAgent(String? userAgent) {
    throw UnimplementedError(
        'setUserAgent is not implemented on the current platform');
  }
}

/// Describes the parameters necessary for registering a JavaScript channel.
class JavaScriptChannelParams {
  /// Creates a new [JavaScriptChannelParams] object.
  JavaScriptChannelParams({
    required this.name,
    required this.onMessageReceived,
  });

  /// The name that identifies the JavaScript channel.
  final String name;

  /// The callback method that is invoked when a [JavaScriptMessage] is
  /// received.
  final void Function(JavaScriptMessage) onMessageReceived;
}
