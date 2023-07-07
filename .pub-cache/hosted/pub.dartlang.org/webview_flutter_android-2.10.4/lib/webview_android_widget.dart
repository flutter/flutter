// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'src/android_webview.dart' as android_webview;
import 'webview_android_cookie_manager.dart';

/// Creates a [Widget] with a [android_webview.WebView].
class WebViewAndroidWidget extends StatefulWidget {
  /// Constructs a [WebViewAndroidWidget].
  const WebViewAndroidWidget({
    Key? key,
    required this.creationParams,
    required this.useHybridComposition,
    required this.callbacksHandler,
    required this.javascriptChannelRegistry,
    required this.onBuildWidget,
    @visibleForTesting this.webViewProxy = const WebViewProxy(),
    @visibleForTesting
        this.flutterAssetManager = const android_webview.FlutterAssetManager(),
    @visibleForTesting this.webStorage,
  }) : super(key: key);

  /// Initial parameters used to setup the WebView.
  final CreationParams creationParams;

  /// Whether the [android_webview.WebView] will be rendered with an [AndroidViewSurface].
  ///
  /// This implementation uses hybrid composition to render the
  /// [WebViewAndroidWidget]. This comes at the cost of some performance on
  /// Android versions below 10. See
  /// https://flutter.dev/docs/development/platform-integration/platform-views#performance
  /// for more information.
  ///
  /// Defaults to false.
  final bool useHybridComposition;

  /// Handles callbacks that are made by [android_webview.WebViewClient], [android_webview.DownloadListener], and [android_webview.WebChromeClient].
  final WebViewPlatformCallbacksHandler callbacksHandler;

  /// Manages named JavaScript channels and forwarding incoming messages on the correct channel.
  final JavascriptChannelRegistry javascriptChannelRegistry;

  /// Handles constructing [android_webview.WebView]s and calling static methods.
  ///
  /// This should only be changed for testing purposes.
  final WebViewProxy webViewProxy;

  /// Manages access to Flutter assets that are part of the Android App bundle.
  ///
  /// This should only be changed for testing purposes.
  final android_webview.FlutterAssetManager flutterAssetManager;

  /// Callback to build a widget once [android_webview.WebView] has been initialized.
  final Widget Function(WebViewAndroidPlatformController controller)
      onBuildWidget;

  /// Manages the JavaScript storage APIs.
  final android_webview.WebStorage? webStorage;

  @override
  State<StatefulWidget> createState() => _WebViewAndroidWidgetState();
}

class _WebViewAndroidWidgetState extends State<WebViewAndroidWidget> {
  late final WebViewAndroidPlatformController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewAndroidPlatformController(
      useHybridComposition: widget.useHybridComposition,
      creationParams: widget.creationParams,
      callbacksHandler: widget.callbacksHandler,
      javascriptChannelRegistry: widget.javascriptChannelRegistry,
      webViewProxy: widget.webViewProxy,
      flutterAssetManager: widget.flutterAssetManager,
      webStorage: widget.webStorage,
    );
  }

  @override
  void dispose() {
    super.dispose();
    controller._dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.onBuildWidget(controller);
  }
}

/// Implementation of [WebViewPlatformController] with the Android WebView api.
class WebViewAndroidPlatformController extends WebViewPlatformController {
  /// Construct a [WebViewAndroidPlatformController].
  WebViewAndroidPlatformController({
    required bool useHybridComposition,
    required CreationParams creationParams,
    required this.callbacksHandler,
    required this.javascriptChannelRegistry,
    @visibleForTesting this.webViewProxy = const WebViewProxy(),
    @visibleForTesting
        this.flutterAssetManager = const android_webview.FlutterAssetManager(),
    @visibleForTesting android_webview.WebStorage? webStorage,
  })  : webStorage = webStorage ?? android_webview.WebStorage.instance,
        assert(creationParams.webSettings?.hasNavigationDelegate != null),
        super(callbacksHandler) {
    webView = webViewProxy.createWebView(
      useHybridComposition: useHybridComposition,
    );

    webView.settings.setDomStorageEnabled(true);
    webView.settings.setJavaScriptCanOpenWindowsAutomatically(true);
    webView.settings.setSupportMultipleWindows(true);
    webView.settings.setLoadWithOverviewMode(true);
    webView.settings.setUseWideViewPort(true);
    webView.settings.setDisplayZoomControls(false);
    webView.settings.setBuiltInZoomControls(true);

    _setCreationParams(creationParams);
    webView.setDownloadListener(downloadListener);
    webView.setWebChromeClient(webChromeClient);

    final String? initialUrl = creationParams.initialUrl;
    if (initialUrl != null) {
      loadUrl(initialUrl, <String, String>{});
    }
  }

  final Map<String, WebViewAndroidJavaScriptChannel> _javaScriptChannels =
      <String, WebViewAndroidJavaScriptChannel>{};

  late WebViewAndroidWebViewClient _webViewClient;

  /// Represents the WebView maintained by platform code.
  late final android_webview.WebView webView;

  /// Handles callbacks that are made by [android_webview.WebViewClient], [android_webview.DownloadListener], and [android_webview.WebChromeClient].
  final WebViewPlatformCallbacksHandler callbacksHandler;

  /// Manages named JavaScript channels and forwarding incoming messages on the correct channel.
  final JavascriptChannelRegistry javascriptChannelRegistry;

  /// Handles constructing [android_webview.WebView]s and calling static methods.
  ///
  /// This should only be changed for testing purposes.
  final WebViewProxy webViewProxy;

  /// Manages access to Flutter assets that are part of the Android App bundle.
  ///
  /// This should only be changed for testing purposes.
  final android_webview.FlutterAssetManager flutterAssetManager;

  /// Receives callbacks when content should be downloaded instead.
  @visibleForTesting
  late final WebViewAndroidDownloadListener downloadListener =
      WebViewAndroidDownloadListener(loadUrl: loadUrl);

  /// Handles JavaScript dialogs, favicons, titles, new windows, and the progress for [android_webview.WebView].
  @visibleForTesting
  late final WebViewAndroidWebChromeClient webChromeClient =
      WebViewAndroidWebChromeClient();

  /// Manages the JavaScript storage APIs.
  final android_webview.WebStorage webStorage;

  /// Receive various notifications and requests for [android_webview.WebView].
  @visibleForTesting
  WebViewAndroidWebViewClient get webViewClient => _webViewClient;

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) {
    return webView.loadDataWithBaseUrl(
      baseUrl: baseUrl,
      data: html,
      mimeType: 'text/html',
    );
  }

  @override
  Future<void> loadFile(String absoluteFilePath) {
    final String url = absoluteFilePath.startsWith('file://')
        ? absoluteFilePath
        : 'file://$absoluteFilePath';

    webView.settings.setAllowFileAccess(true);
    return webView.loadUrl(url, <String, String>{});
  }

  @override
  Future<void> loadFlutterAsset(String key) async {
    final String assetFilePath =
        await flutterAssetManager.getAssetFilePathByName(key);
    final List<String> pathElements = assetFilePath.split('/');
    final String fileName = pathElements.removeLast();
    final List<String?> paths =
        await flutterAssetManager.list(pathElements.join('/'));

    if (!paths.contains(fileName)) {
      throw ArgumentError(
        'Asset for key "$key" not found.',
        'key',
      );
    }

    return webView.loadUrl(
      'file:///android_asset/$assetFilePath',
      <String, String>{},
    );
  }

  @override
  Future<void> loadUrl(
    String url,
    Map<String, String>? headers,
  ) {
    return webView.loadUrl(url, headers ?? <String, String>{});
  }

  /// When making a POST request, headers are ignored. As a workaround, make
  /// the request manually and load the response data using [loadHTMLString].
  @override
  Future<void> loadRequest(
    WebViewRequest request,
  ) async {
    if (!request.uri.hasScheme) {
      throw ArgumentError('WebViewRequest#uri is required to have a scheme.');
    }
    switch (request.method) {
      case WebViewRequestMethod.get:
        return webView.loadUrl(request.uri.toString(), request.headers);
      case WebViewRequestMethod.post:
        return webView.postUrl(
            request.uri.toString(), request.body ?? Uint8List(0));
      default:
        throw UnimplementedError(
          'This version of webview_android_widget currently has no implementation for HTTP method ${request.method.serialize()} in loadRequest.',
        );
    }
  }

  @override
  Future<String?> currentUrl() => webView.getUrl();

  @override
  Future<bool> canGoBack() => webView.canGoBack();

  @override
  Future<bool> canGoForward() => webView.canGoForward();

  @override
  Future<void> goBack() => webView.goBack();

  @override
  Future<void> goForward() => webView.goForward();

  @override
  Future<void> reload() => webView.reload();

  @override
  Future<void> clearCache() {
    webView.clearCache(true);
    return webStorage.deleteAllData();
  }

  @override
  Future<void> updateSettings(WebSettings setting) async {
    await Future.wait(<Future<void>>[
      _setUserAgent(setting.userAgent),
      if (setting.hasProgressTracking != null)
        _setHasProgressTracking(setting.hasProgressTracking!),
      if (setting.hasNavigationDelegate != null)
        _setHasNavigationDelegate(setting.hasNavigationDelegate!),
      if (setting.javascriptMode != null)
        _setJavaScriptMode(setting.javascriptMode!),
      if (setting.debuggingEnabled != null)
        _setDebuggingEnabled(setting.debuggingEnabled!),
      if (setting.zoomEnabled != null) _setZoomEnabled(setting.zoomEnabled!),
    ]);
  }

  @override
  Future<String> evaluateJavascript(String javascript) async {
    return runJavascriptReturningResult(javascript);
  }

  @override
  Future<void> runJavascript(String javascript) async {
    await webView.evaluateJavascript(javascript);
  }

  @override
  Future<String> runJavascriptReturningResult(String javascript) async {
    return await webView.evaluateJavascript(javascript) ?? '';
  }

  @override
  Future<void> addJavascriptChannels(Set<String> javascriptChannelNames) {
    return Future.wait(
      javascriptChannelNames.where(
        (String channelName) {
          return !_javaScriptChannels.containsKey(channelName);
        },
      ).map<Future<void>>(
        (String channelName) {
          final WebViewAndroidJavaScriptChannel javaScriptChannel =
              WebViewAndroidJavaScriptChannel(
                  channelName, javascriptChannelRegistry);
          _javaScriptChannels[channelName] = javaScriptChannel;
          return webView.addJavaScriptChannel(javaScriptChannel);
        },
      ),
    );
  }

  @override
  Future<void> removeJavascriptChannels(
    Set<String> javascriptChannelNames,
  ) {
    return Future.wait(
      javascriptChannelNames.where(
        (String channelName) {
          return _javaScriptChannels.containsKey(channelName);
        },
      ).map<Future<void>>(
        (String channelName) {
          final WebViewAndroidJavaScriptChannel javaScriptChannel =
              _javaScriptChannels[channelName]!;
          _javaScriptChannels.remove(channelName);
          return webView.removeJavaScriptChannel(javaScriptChannel);
        },
      ),
    );
  }

  @override
  Future<String?> getTitle() => webView.getTitle();

  @override
  Future<void> scrollTo(int x, int y) => webView.scrollTo(x, y);

  @override
  Future<void> scrollBy(int x, int y) => webView.scrollBy(x, y);

  @override
  Future<int> getScrollX() => webView.getScrollX();

  @override
  Future<int> getScrollY() => webView.getScrollY();

  Future<void> _dispose() => webView.release();

  void _setCreationParams(CreationParams creationParams) {
    final WebSettings? webSettings = creationParams.webSettings;
    if (webSettings != null) {
      updateSettings(webSettings);
    }

    final String? userAgent = creationParams.userAgent;
    if (userAgent != null) {
      webView.settings.setUserAgentString(userAgent);
    }

    webView.settings.setMediaPlaybackRequiresUserGesture(
      creationParams.autoMediaPlaybackPolicy !=
          AutoMediaPlaybackPolicy.always_allow,
    );

    final Color? backgroundColor = creationParams.backgroundColor;
    if (backgroundColor != null) {
      webView.setBackgroundColor(backgroundColor);
    }

    addJavascriptChannels(creationParams.javascriptChannelNames);

    // TODO(BeMacized): Remove once platform implementations
    // are able to register themselves (Flutter >=2.8),
    // https://github.com/flutter/flutter/issues/94224
    WebViewCookieManagerPlatform.instance ??= WebViewAndroidCookieManager();

    creationParams.cookies
        .forEach(WebViewCookieManagerPlatform.instance!.setCookie);
  }

  Future<void> _setHasProgressTracking(bool hasProgressTracking) async {
    if (hasProgressTracking) {
      webChromeClient._onProgress = callbacksHandler.onProgress;
    } else {
      webChromeClient._onProgress = null;
    }
  }

  Future<void> _setHasNavigationDelegate(bool hasNavigationDelegate) {
    if (hasNavigationDelegate) {
      downloadListener._onNavigationRequest =
          callbacksHandler.onNavigationRequest;
      _webViewClient = WebViewAndroidWebViewClient.handlesNavigation(
        onPageStartedCallback: callbacksHandler.onPageStarted,
        onPageFinishedCallback: callbacksHandler.onPageFinished,
        onWebResourceErrorCallback: callbacksHandler.onWebResourceError,
        loadUrl: loadUrl,
        onNavigationRequestCallback: callbacksHandler.onNavigationRequest,
      );
    } else {
      downloadListener._onNavigationRequest = null;
      _webViewClient = WebViewAndroidWebViewClient(
        onPageStartedCallback: callbacksHandler.onPageStarted,
        onPageFinishedCallback: callbacksHandler.onPageFinished,
        onWebResourceErrorCallback: callbacksHandler.onWebResourceError,
      );
    }
    return webView.setWebViewClient(_webViewClient);
  }

  Future<void> _setJavaScriptMode(JavascriptMode mode) {
    switch (mode) {
      case JavascriptMode.disabled:
        return webView.settings.setJavaScriptEnabled(false);
      case JavascriptMode.unrestricted:
        return webView.settings.setJavaScriptEnabled(true);
    }
  }

  Future<void> _setDebuggingEnabled(bool debuggingEnabled) {
    return webViewProxy.setWebContentsDebuggingEnabled(debuggingEnabled);
  }

  Future<void> _setUserAgent(WebSetting<String?> userAgent) {
    if (userAgent.isPresent) {
      // If the string is empty, the system default value will be used.
      return webView.settings.setUserAgentString(userAgent.value ?? '');
    }

    return Future<void>.value();
  }

  Future<void> _setZoomEnabled(bool zoomEnabled) {
    return webView.settings.setSupportZoom(zoomEnabled);
  }
}

/// Exposes a channel to receive calls from javaScript.
class WebViewAndroidJavaScriptChannel
    extends android_webview.JavaScriptChannel {
  /// Creates a [WebViewAndroidJavaScriptChannel].
  WebViewAndroidJavaScriptChannel(
      String channelName, this.javascriptChannelRegistry)
      : super(channelName);

  /// Manages named JavaScript channels and forwarding incoming messages on the correct channel.
  final JavascriptChannelRegistry javascriptChannelRegistry;

  @override
  void postMessage(String message) {
    javascriptChannelRegistry.onJavascriptChannelMessage(channelName, message);
  }
}

/// Receives callbacks when content can not be handled by the rendering engine for [WebViewAndroidPlatformController], and should be downloaded instead.
///
/// When handling navigation requests, this calls [onNavigationRequestCallback]
/// when a [android_webview.WebView] attempts to navigate to a new page. If
/// this callback return true, this calls [loadUrl].
class WebViewAndroidDownloadListener extends android_webview.DownloadListener {
  /// Creates a [WebViewAndroidDownloadListener].
  WebViewAndroidDownloadListener({required this.loadUrl});

  // Changed by WebViewAndroidPlatformController.
  FutureOr<bool> Function({
    required String url,
    required bool isForMainFrame,
  })? _onNavigationRequest;

  /// Callback to load a URL when a navigation request is approved.
  final Future<void> Function(String url, Map<String, String>? headers) loadUrl;

  @override
  void onDownloadStart(
    String url,
    String userAgent,
    String contentDisposition,
    String mimetype,
    int contentLength,
  ) {
    if (_onNavigationRequest == null) {
      return;
    }

    final FutureOr<bool> returnValue = _onNavigationRequest!(
      url: url,
      isForMainFrame: true,
    );

    if (returnValue is bool && returnValue) {
      loadUrl(url, <String, String>{});
    } else {
      (returnValue as Future<bool>).then((bool shouldLoadUrl) {
        if (shouldLoadUrl) {
          loadUrl(url, <String, String>{});
        }
      });
    }
  }
}

/// Receives various navigation requests and errors for [WebViewAndroidPlatformController].
///
/// When handling navigation requests, this calls [onNavigationRequestCallback]
/// when a [android_webview.WebView] attempts to navigate to a new page. If
/// this callback return true, this calls [loadUrl].
class WebViewAndroidWebViewClient extends android_webview.WebViewClient {
  /// Creates a [WebViewAndroidWebViewClient] that doesn't handle navigation requests.
  WebViewAndroidWebViewClient({
    required this.onPageStartedCallback,
    required this.onPageFinishedCallback,
    required this.onWebResourceErrorCallback,
  })  : loadUrl = null,
        onNavigationRequestCallback = null,
        super(shouldOverrideUrlLoading: false);

  /// Creates a [WebViewAndroidWebViewClient] that handles navigation requests.
  WebViewAndroidWebViewClient.handlesNavigation({
    required this.onPageStartedCallback,
    required this.onPageFinishedCallback,
    required this.onWebResourceErrorCallback,
    required this.onNavigationRequestCallback,
    required this.loadUrl,
  }) : super(shouldOverrideUrlLoading: true);

  /// Callback when [android_webview.WebViewClient] receives a callback from [android_webview.WebViewClient].onPageStarted.
  final void Function(String url) onPageStartedCallback;

  /// Callback when [android_webview.WebViewClient] receives a callback from [android_webview.WebViewClient].onPageFinished.
  final void Function(String url) onPageFinishedCallback;

  /// Callback when [android_webview.WebViewClient] receives an error callback.
  void Function(WebResourceError error) onWebResourceErrorCallback;

  /// Checks whether a navigation request should be approved or disaproved.
  final FutureOr<bool> Function({
    required String url,
    required bool isForMainFrame,
  })? onNavigationRequestCallback;

  /// Callback when a navigation request is approved.
  final Future<void> Function(String url, Map<String, String>? headers)?
      loadUrl;

  static WebResourceErrorType _errorCodeToErrorType(int errorCode) {
    switch (errorCode) {
      case android_webview.WebViewClient.errorAuthentication:
        return WebResourceErrorType.authentication;
      case android_webview.WebViewClient.errorBadUrl:
        return WebResourceErrorType.badUrl;
      case android_webview.WebViewClient.errorConnect:
        return WebResourceErrorType.connect;
      case android_webview.WebViewClient.errorFailedSslHandshake:
        return WebResourceErrorType.failedSslHandshake;
      case android_webview.WebViewClient.errorFile:
        return WebResourceErrorType.file;
      case android_webview.WebViewClient.errorFileNotFound:
        return WebResourceErrorType.fileNotFound;
      case android_webview.WebViewClient.errorHostLookup:
        return WebResourceErrorType.hostLookup;
      case android_webview.WebViewClient.errorIO:
        return WebResourceErrorType.io;
      case android_webview.WebViewClient.errorProxyAuthentication:
        return WebResourceErrorType.proxyAuthentication;
      case android_webview.WebViewClient.errorRedirectLoop:
        return WebResourceErrorType.redirectLoop;
      case android_webview.WebViewClient.errorTimeout:
        return WebResourceErrorType.timeout;
      case android_webview.WebViewClient.errorTooManyRequests:
        return WebResourceErrorType.tooManyRequests;
      case android_webview.WebViewClient.errorUnknown:
        return WebResourceErrorType.unknown;
      case android_webview.WebViewClient.errorUnsafeResource:
        return WebResourceErrorType.unsafeResource;
      case android_webview.WebViewClient.errorUnsupportedAuthScheme:
        return WebResourceErrorType.unsupportedAuthScheme;
      case android_webview.WebViewClient.errorUnsupportedScheme:
        return WebResourceErrorType.unsupportedScheme;
    }

    throw ArgumentError(
      'Could not find a WebResourceErrorType for errorCode: $errorCode',
    );
  }

  /// Whether this [android_webview.WebViewClient] handles navigation requests.
  bool get handlesNavigation =>
      loadUrl != null && onNavigationRequestCallback != null;

  @override
  void onPageStarted(android_webview.WebView webView, String url) {
    onPageStartedCallback(url);
  }

  @override
  void onPageFinished(android_webview.WebView webView, String url) {
    onPageFinishedCallback(url);
  }

  @override
  void onReceivedError(
    android_webview.WebView webView,
    int errorCode,
    String description,
    String failingUrl,
  ) {
    onWebResourceErrorCallback(WebResourceError(
      errorCode: errorCode,
      description: description,
      failingUrl: failingUrl,
      errorType: _errorCodeToErrorType(errorCode),
    ));
  }

  @override
  void onReceivedRequestError(
    android_webview.WebView webView,
    android_webview.WebResourceRequest request,
    android_webview.WebResourceError error,
  ) {
    if (request.isForMainFrame) {
      onWebResourceErrorCallback(WebResourceError(
        errorCode: error.errorCode,
        description: error.description,
        failingUrl: request.url,
        errorType: _errorCodeToErrorType(error.errorCode),
      ));
    }
  }

  @override
  void urlLoading(android_webview.WebView webView, String url) {
    if (!handlesNavigation) {
      return;
    }

    final FutureOr<bool> returnValue = onNavigationRequestCallback!(
      url: url,
      isForMainFrame: true,
    );

    if (returnValue is bool && returnValue) {
      loadUrl!(url, <String, String>{});
    } else if (returnValue is Future<bool>) {
      returnValue.then((bool shouldLoadUrl) {
        if (shouldLoadUrl) {
          loadUrl!(url, <String, String>{});
        }
      });
    }
  }

  @override
  void requestLoading(
    android_webview.WebView webView,
    android_webview.WebResourceRequest request,
  ) {
    if (!handlesNavigation) {
      return;
    }

    final FutureOr<bool> returnValue = onNavigationRequestCallback!(
      url: request.url,
      isForMainFrame: request.isForMainFrame,
    );

    if (returnValue is bool && returnValue) {
      loadUrl!(request.url, <String, String>{});
    } else if (returnValue is Future<bool>) {
      returnValue.then((bool shouldLoadUrl) {
        if (shouldLoadUrl) {
          loadUrl!(request.url, <String, String>{});
        }
      });
    }
  }
}

/// Handles JavaScript dialogs, favicons, titles, and the progress for [WebViewAndroidPlatformController].
class WebViewAndroidWebChromeClient extends android_webview.WebChromeClient {
  // Changed by WebViewAndroidPlatformController.
  void Function(int progress)? _onProgress;

  @override
  void onProgressChanged(android_webview.WebView webView, int progress) {
    if (_onProgress != null) {
      _onProgress!(progress);
    }
  }
}

/// Handles constructing [android_webview.WebView]s and calling static methods.
///
/// This should only be used for testing purposes.
@visibleForTesting
class WebViewProxy {
  /// Creates a [WebViewProxy].
  const WebViewProxy();

  /// Constructs a [android_webview.WebView].
  android_webview.WebView createWebView({required bool useHybridComposition}) {
    return android_webview.WebView(useHybridComposition: useHybridComposition);
  }

  /// Enables debugging of web contents (HTML / CSS / JavaScript) loaded into any WebViews of this application.
  ///
  /// This flag can be enabled in order to facilitate debugging of web layouts
  /// and JavaScript code running inside WebViews. Please refer to
  /// [android_webview.WebView] documentation for the debugging guide. The
  /// default is false.
  ///
  /// See [android_webview.WebView].setWebContentsDebuggingEnabled.
  Future<void> setWebContentsDebuggingEnabled(bool enabled) {
    return android_webview.WebView.setWebContentsDebuggingEnabled(enabled);
  }
}
