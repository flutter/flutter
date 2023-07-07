// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
// ignore: implementation_imports
import 'package:webview_flutter_platform_interface/src/webview_flutter_platform_interface_legacy.dart';
// ignore: implementation_imports
import 'package:webview_flutter_web/src/webview_flutter_web_legacy.dart';

/// Optional callback invoked when a web view is first created. [controller] is
/// the [WebViewController] for the created web view.
typedef WebViewCreatedCallback = void Function(WebViewController controller);

/// A web view widget for showing html content.
///
/// The [WebView] widget wraps around the [WebWebViewPlatform].
///
/// The [WebView] widget is controlled using the [WebViewController] which is
/// provided through the `onWebViewCreated` callback.
///
/// In this example project it's main purpose is to facilitate integration
/// testing of the `webview_flutter_web` package.
class WebView extends StatefulWidget {
  /// Creates a new web view.
  ///
  /// The web view can be controlled using a `WebViewController` that is passed to the
  /// `onWebViewCreated` callback once the web view is created.
  const WebView({
    Key? key,
    this.onWebViewCreated,
    this.initialUrl,
  }) : super(key: key);

  /// The WebView platform that's used by this WebView.
  ///
  /// The default value is [WebWebViewPlatform].
  /// This property can be set to use a custom platform implementation for WebViews.
  /// Setting `platform` doesn't affect [WebView]s that were already created.
  static WebViewPlatform platform = WebWebViewPlatform();

  /// If not null invoked once the web view is created.
  final WebViewCreatedCallback? onWebViewCreated;

  /// The initial URL to load.
  final String? initialUrl;

  @override
  State<WebView> createState() => _WebViewState();
}

class _WebViewState extends State<WebView> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  late final _PlatformCallbacksHandler _platformCallbacksHandler;

  @override
  void initState() {
    super.initState();
    _platformCallbacksHandler = _PlatformCallbacksHandler();
  }

  @override
  void didUpdateWidget(WebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.future.then((WebViewController controller) {
      controller.updateWidget(widget);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WebView.platform.build(
      context: context,
      onWebViewPlatformCreated:
          (WebViewPlatformController? webViewPlatformController) {
        final WebViewController controller = WebViewController(
          widget,
          webViewPlatformController!,
        );
        _controller.complete(controller);

        if (widget.onWebViewCreated != null) {
          widget.onWebViewCreated!(controller);
        }
      },
      webViewPlatformCallbacksHandler: _platformCallbacksHandler,
      creationParams: CreationParams(
        initialUrl: widget.initialUrl,
        webSettings: _webSettingsFromWidget(widget),
      ),
      javascriptChannelRegistry:
          JavascriptChannelRegistry(<JavascriptChannel>{}),
    );
  }
}

class _PlatformCallbacksHandler implements WebViewPlatformCallbacksHandler {
  _PlatformCallbacksHandler();

  @override
  FutureOr<bool> onNavigationRequest(
      {required String url, required bool isForMainFrame}) {
    throw UnimplementedError();
  }

  @override
  void onPageFinished(String url) {}

  @override
  void onPageStarted(String url) {}

  @override
  void onProgress(int progress) {}

  @override
  void onWebResourceError(WebResourceError error) {}
}

/// Controls a [WebView].
///
/// A [WebViewController] instance can be obtained by setting the [WebView.onWebViewCreated]
/// callback for a [WebView] widget.
class WebViewController {
  /// Creates a [WebViewController] which can be used to control the provided
  /// [WebView] widget.
  WebViewController(
    this._widget,
    this._webViewPlatformController,
  ) : assert(_webViewPlatformController != null) {
    _settings = _webSettingsFromWidget(_widget);
  }

  final WebViewPlatformController _webViewPlatformController;

  late WebSettings _settings;

  WebView _widget;

  /// Loads the specified URL.
  ///
  /// If `headers` is not null and the URL is an HTTP URL, the key value paris in `headers` will
  /// be added as key value pairs of HTTP headers for the request.
  ///
  /// `url` must not be null.
  ///
  /// Throws an ArgumentError if `url` is not a valid URL string.
  Future<void> loadUrl(
    String url, {
    Map<String, String>? headers,
  }) async {
    assert(url != null);
    _validateUrlString(url);
    return _webViewPlatformController.loadUrl(url, headers);
  }

  /// Loads a page by making the specified request.
  Future<void> loadRequest(WebViewRequest request) async {
    return _webViewPlatformController.loadRequest(request);
  }

  /// Accessor to the current URL that the WebView is displaying.
  ///
  /// If [WebView.initialUrl] was never specified, returns `null`.
  /// Note that this operation is asynchronous, and it is possible that the
  /// current URL changes again by the time this function returns (in other
  /// words, by the time this future completes, the WebView may be displaying a
  /// different URL).
  Future<String?> currentUrl() {
    return _webViewPlatformController.currentUrl();
  }

  /// Checks whether there's a back history item.
  ///
  /// Note that this operation is asynchronous, and it is possible that the "canGoBack" state has
  /// changed by the time the future completed.
  Future<bool> canGoBack() {
    return _webViewPlatformController.canGoBack();
  }

  /// Checks whether there's a forward history item.
  ///
  /// Note that this operation is asynchronous, and it is possible that the "canGoForward" state has
  /// changed by the time the future completed.
  Future<bool> canGoForward() {
    return _webViewPlatformController.canGoForward();
  }

  /// Goes back in the history of this WebView.
  ///
  /// If there is no back history item this is a no-op.
  Future<void> goBack() {
    return _webViewPlatformController.goBack();
  }

  /// Goes forward in the history of this WebView.
  ///
  /// If there is no forward history item this is a no-op.
  Future<void> goForward() {
    return _webViewPlatformController.goForward();
  }

  /// Reloads the current URL.
  Future<void> reload() {
    return _webViewPlatformController.reload();
  }

  /// Clears all caches used by the [WebView].
  ///
  /// The following caches are cleared:
  ///	1. Browser HTTP Cache.
  ///	2. [Cache API](https://developers.google.com/web/fundamentals/instant-and-offline/web-storage/cache-api) caches.
  ///    These are not yet supported in iOS WkWebView. Service workers tend to use this cache.
  ///	3. Application cache.
  ///	4. Local Storage.
  ///
  /// Note: Calling this method also triggers a reload.
  Future<void> clearCache() async {
    await _webViewPlatformController.clearCache();
    return reload();
  }

  /// Update the widget managed by the [WebViewController].
  Future<void> updateWidget(WebView widget) async {
    _widget = widget;
    await _updateSettings(_webSettingsFromWidget(widget));
  }

  Future<void> _updateSettings(WebSettings newSettings) {
    final WebSettings update =
        _clearUnchangedWebSettings(_settings, newSettings);
    _settings = newSettings;
    return _webViewPlatformController.updateSettings(update);
  }

  @visibleForTesting
  // ignore: public_member_api_docs
  Future<String> evaluateJavascript(String javascriptString) {
    if (_settings.javascriptMode == JavascriptMode.disabled) {
      return Future<String>.error(FlutterError(
          'JavaScript mode must be enabled/unrestricted when calling evaluateJavascript.'));
    }
    return _webViewPlatformController.evaluateJavascript(javascriptString);
  }

  /// Runs the given JavaScript in the context of the current page.
  /// If you are looking for the result, use [runJavascriptReturningResult] instead.
  /// The Future completes with an error if a JavaScript error occurred.
  ///
  /// When running JavaScript in a [WebView], it is best practice to wait for
  //  the [WebView.onPageFinished] callback. This guarantees all the JavaScript
  //  embedded in the main frame HTML has been loaded.
  Future<void> runJavascript(String javaScriptString) {
    if (_settings.javascriptMode == JavascriptMode.disabled) {
      return Future<void>.error(FlutterError(
          'Javascript mode must be enabled/unrestricted when calling runJavascript.'));
    }
    return _webViewPlatformController.runJavascript(javaScriptString);
  }

  /// Runs the given JavaScript in the context of the current page, and returns the result.
  ///
  /// Returns the evaluation result as a JSON formatted string.
  /// The Future completes with an error if a JavaScript error occurred.
  ///
  /// When evaluating JavaScript in a [WebView], it is best practice to wait for
  /// the [WebView.onPageFinished] callback. This guarantees all the JavaScript
  /// embedded in the main frame HTML has been loaded.
  Future<String> runJavascriptReturningResult(String javaScriptString) {
    if (_settings.javascriptMode == JavascriptMode.disabled) {
      return Future<String>.error(FlutterError(
          'Javascript mode must be enabled/unrestricted when calling runJavascriptReturningResult.'));
    }
    return _webViewPlatformController
        .runJavascriptReturningResult(javaScriptString);
  }

  /// Returns the title of the currently loaded page.
  Future<String?> getTitle() {
    return _webViewPlatformController.getTitle();
  }

  /// Sets the WebView's content scroll position.
  ///
  /// The parameters `x` and `y` specify the scroll position in WebView pixels.
  Future<void> scrollTo(int x, int y) {
    return _webViewPlatformController.scrollTo(x, y);
  }

  /// Move the scrolled position of this view.
  ///
  /// The parameters `x` and `y` specify the amount of WebView pixels to scroll by horizontally and vertically respectively.
  Future<void> scrollBy(int x, int y) {
    return _webViewPlatformController.scrollBy(x, y);
  }

  /// Return the horizontal scroll position, in WebView pixels, of this view.
  ///
  /// Scroll position is measured from left.
  Future<int> getScrollX() {
    return _webViewPlatformController.getScrollX();
  }

  /// Return the vertical scroll position, in WebView pixels, of this view.
  ///
  /// Scroll position is measured from top.
  Future<int> getScrollY() {
    return _webViewPlatformController.getScrollY();
  }

  // This method assumes that no fields in `currentValue` are null.
  WebSettings _clearUnchangedWebSettings(
      WebSettings currentValue, WebSettings newValue) {
    assert(currentValue.javascriptMode != null);
    assert(currentValue.hasNavigationDelegate != null);
    assert(currentValue.hasProgressTracking != null);
    assert(currentValue.debuggingEnabled != null);
    assert(currentValue.userAgent != null);
    assert(newValue.javascriptMode != null);
    assert(newValue.hasNavigationDelegate != null);
    assert(newValue.debuggingEnabled != null);
    assert(newValue.userAgent != null);
    assert(newValue.zoomEnabled != null);

    JavascriptMode? javascriptMode;
    bool? hasNavigationDelegate;
    bool? hasProgressTracking;
    bool? debuggingEnabled;
    WebSetting<String?> userAgent = const WebSetting<String?>.absent();
    bool? zoomEnabled;
    if (currentValue.javascriptMode != newValue.javascriptMode) {
      javascriptMode = newValue.javascriptMode;
    }
    if (currentValue.hasNavigationDelegate != newValue.hasNavigationDelegate) {
      hasNavigationDelegate = newValue.hasNavigationDelegate;
    }
    if (currentValue.hasProgressTracking != newValue.hasProgressTracking) {
      hasProgressTracking = newValue.hasProgressTracking;
    }
    if (currentValue.debuggingEnabled != newValue.debuggingEnabled) {
      debuggingEnabled = newValue.debuggingEnabled;
    }
    if (currentValue.userAgent != newValue.userAgent) {
      userAgent = newValue.userAgent;
    }
    if (currentValue.zoomEnabled != newValue.zoomEnabled) {
      zoomEnabled = newValue.zoomEnabled;
    }

    return WebSettings(
      javascriptMode: javascriptMode,
      hasNavigationDelegate: hasNavigationDelegate,
      hasProgressTracking: hasProgressTracking,
      debuggingEnabled: debuggingEnabled,
      userAgent: userAgent,
      zoomEnabled: zoomEnabled,
    );
  }

  // Throws an ArgumentError if `url` is not a valid URL string.
  void _validateUrlString(String url) {
    try {
      final Uri uri = Uri.parse(url);
      if (uri.scheme.isEmpty) {
        throw ArgumentError('Missing scheme in URL string: "$url"');
      }
    } on FormatException catch (e) {
      throw ArgumentError(e);
    }
  }
}

WebSettings _webSettingsFromWidget(WebView widget) {
  return WebSettings(
    javascriptMode: JavascriptMode.unrestricted,
    hasNavigationDelegate: false,
    hasProgressTracking: false,
    debuggingEnabled: false,
    gestureNavigationEnabled: false,
    allowsInlineMediaPlayback: true,
    userAgent: const WebSetting<String?>.of(''),
    zoomEnabled: false,
  );
}
