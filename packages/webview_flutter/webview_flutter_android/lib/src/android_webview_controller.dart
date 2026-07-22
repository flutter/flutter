// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'android_ssl_auth_error.dart';
import 'android_webkit.g.dart' as android_webview;
import 'android_webkit_constants.dart';
import 'platform_views_service_proxy.dart';
import 'weak_reference_utils.dart';

/// Defines different types of sources causing window insets.
///
/// See https://developer.android.com/reference/androidx/core/view/WindowInsetsCompat.Type
enum AndroidWebViewInsets {
  /// All system bars.
  ///
  /// Includes [statusBars], [captionBar] as well as [navigationBars], but not
  /// [ime].
  systemBars,

  /// An inset type representing the area that used by DisplayCutout.
  displayCutout,

  /// An inset type representing the window of a caption bar.
  captionBar,

  /// An inset type representing the window of an InputMethod.
  ime,

  /// An inset type representing the area of a window where mandatory system
  /// gestures have priority and may consume some or all touch input, e.g. due
  /// to the a system bar occupying it, or it being reserved for touch-only
  /// gestures.
  mandatorySystemGestures,

  /// An inset type representing any system bars for navigation.
  navigationBars,

  /// An inset type representing any system bars for displaying status.
  statusBars,

  /// An inset type representing the area of a window where system gestures
  /// have priority and may consume some or all touch input, e.g. due to the a
  /// system bar occupying it, or it being reserved for touch-only gestures.
  systemGestures,

  /// An insets type representing how much tappable elements must at least be
  /// inset to remain both tappable and visually unobstructed by persistent
  /// system windows.
  tappableElement,
}

/// Object specifying parameters for loading a local file in a
/// [AndroidWebViewController].
@immutable
base class AndroidLoadFileParams extends LoadFileParams {
  /// Constructs a [AndroidLoadFileParams], the subclass of a [LoadFileParams].
  AndroidLoadFileParams({required String absoluteFilePath, this.headers = const <String, String>{}})
    : super(
        absoluteFilePath: absoluteFilePath.startsWith('file://')
            ? absoluteFilePath
            : Uri.file(absoluteFilePath).toString(),
      );

  /// Constructs a [AndroidLoadFileParams] using a [LoadFileParams].
  factory AndroidLoadFileParams.fromLoadFileParams(
    LoadFileParams params, {
    Map<String, String> headers = const <String, String>{},
  }) {
    return AndroidLoadFileParams(absoluteFilePath: params.absoluteFilePath, headers: headers);
  }

  /// Additional HTTP headers to be included when loading the local file.
  ///
  /// If not provided at initialization time, doesn't add any additional headers.
  ///
  /// On Android, WebView supports adding headers when loading local or remote
  /// content. This can be useful for scenarios like authentication,
  /// content-type overrides, or custom request context.
  final Map<String, String> headers;
}

/// Object specifying creation parameters for creating a [AndroidWebViewController].
///
/// When adding additional fields make sure they can be null or have a default
/// value to avoid breaking changes. See [PlatformWebViewControllerCreationParams] for
/// more information.
@immutable
class AndroidWebViewControllerCreationParams extends PlatformWebViewControllerCreationParams {
  /// Creates a new [AndroidWebViewControllerCreationParams] instance.
  AndroidWebViewControllerCreationParams({
    @visibleForTesting android_webview.WebStorage? androidWebStorage,
  }) : androidWebStorage = androidWebStorage ?? android_webview.WebStorage.instance,
       super();

  /// Creates a [AndroidWebViewControllerCreationParams] instance based on [PlatformWebViewControllerCreationParams].
  factory AndroidWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
    // Recommended placeholder to prevent being broken by platform interface.
    // ignore: avoid_unused_constructor_parameters
    PlatformWebViewControllerCreationParams params, {
    @visibleForTesting android_webview.WebStorage? androidWebStorage,
  }) {
    return AndroidWebViewControllerCreationParams(
      androidWebStorage: androidWebStorage ?? android_webview.WebStorage.instance,
    );
  }

  /// Manages the JavaScript storage APIs provided by the [android_webview.WebView].
  @visibleForTesting
  final android_webview.WebStorage androidWebStorage;
}

/// Android-specific resources that can require permissions.
class AndroidWebViewPermissionResourceType extends WebViewPermissionResourceType {
  const AndroidWebViewPermissionResourceType._(super.name);

  /// A resource that will allow sysex messages to be sent to or received from
  /// MIDI devices.
  static const AndroidWebViewPermissionResourceType midiSysex =
      AndroidWebViewPermissionResourceType._('midiSysex');

  /// A resource that belongs to a protected media identifier.
  static const AndroidWebViewPermissionResourceType protectedMediaId =
      AndroidWebViewPermissionResourceType._('protectedMediaId');
}

/// Implementation of the [PlatformWebViewController] with the Android WebView API.
class AndroidWebViewController extends PlatformWebViewController {
  /// Creates a new [AndroidWebViewController].
  AndroidWebViewController(PlatformWebViewControllerCreationParams params)
    : super.implementation(
        params is AndroidWebViewControllerCreationParams
            ? params
            : AndroidWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
                params,
              ),
      ) {
    _webView.settings.setDomStorageEnabled(true);
    _webView.settings.setJavaScriptCanOpenWindowsAutomatically(true);
    _webView.settings.setSupportMultipleWindows(true);
    _webView.settings.setLoadWithOverviewMode(true);
    _webView.settings.setUseWideViewPort(false);
    _webView.settings.setDisplayZoomControls(false);
    _webView.settings.setBuiltInZoomControls(true);

    _webView.setWebChromeClient(_webChromeClient);
  }

  AndroidWebViewControllerCreationParams get _androidWebViewParams =>
      params as AndroidWebViewControllerCreationParams;

  /// The native [android_webview.WebView] being controlled.
  late final android_webview.WebView _webView = android_webview.WebView(
    onScrollChanged: withWeakReferenceTo(this, (
      WeakReference<AndroidWebViewController> weakReference,
    ) {
      return (_, int left, int top, int oldLeft, int oldTop) async {
        final void Function(ScrollPositionChange)? callback =
            weakReference.target?._onScrollPositionChangedCallback;
        callback?.call(ScrollPositionChange(left.toDouble(), top.toDouble()));
      };
    }),
  );

  late final android_webview.WebChromeClient _webChromeClient = android_webview.WebChromeClient(
    onProgressChanged: withWeakReferenceTo(this, (
      WeakReference<AndroidWebViewController> weakReference,
    ) {
      return (_, android_webview.WebView webView, int progress) {
        if (weakReference.target?._currentNavigationDelegate?._onProgress != null) {
          weakReference.target!._currentNavigationDelegate!._onProgress!(progress);
        }
      };
    }),
    onGeolocationPermissionsShowPrompt: withWeakReferenceTo(this, (
      WeakReference<AndroidWebViewController> weakReference,
    ) {
      return (_, String origin, android_webview.GeolocationPermissionsCallback callback) async {
        final OnGeolocationPermissionsShowPrompt? onShowPrompt =
            weakReference.target?._onGeolocationPermissionsShowPrompt;
        if (onShowPrompt != null) {
          final GeolocationPermissionsResponse response = await onShowPrompt(
            GeolocationPermissionsRequestParams(origin: origin),
          );
          return callback.invoke(origin, response.allow, response.retain);
        } else {
          // default don't allow
          return callback.invoke(origin, false, false);
        }
      };
    }),
    onGeolocationPermissionsHidePrompt: withWeakReferenceTo(this, (
      WeakReference<AndroidWebViewController> weakReference,
    ) {
      return (android_webview.WebChromeClient instance) {
        final OnGeolocationPermissionsHidePrompt? onHidePrompt =
            weakReference.target?._onGeolocationPermissionsHidePrompt;
        if (onHidePrompt != null) {
          onHidePrompt();
        }
      };
    }),
    onShowCustomView: withWeakReferenceTo(this, (
      WeakReference<AndroidWebViewController> weakReference,
    ) {
      return (_, android_webview.View view, android_webview.CustomViewCallback callback) {
        final AndroidWebViewController? webViewController = weakReference.target;
        if (webViewController == null) {
          callback.onCustomViewHidden();
          return;
        }
        final OnShowCustomWidgetCallback? onShowCallback =
            webViewController._onShowCustomWidgetCallback;
        if (onShowCallback == null) {
          callback.onCustomViewHidden();
          return;
        }
        onShowCallback(
          AndroidCustomViewWidget.private(controller: webViewController, customView: view),
          () => callback.onCustomViewHidden(),
        );
      };
    }),
    onHideCustomView: withWeakReferenceTo(this, (
      WeakReference<AndroidWebViewController> weakReference,
    ) {
      return (android_webview.WebChromeClient instance) {
        final OnHideCustomWidgetCallback? onHideCustomViewCallback =
            weakReference.target?._onHideCustomWidgetCallback;
        if (onHideCustomViewCallback != null) {
          onHideCustomViewCallback();
        }
      };
    }),
    onShowFileChooser: withWeakReferenceTo(this, (
      WeakReference<AndroidWebViewController> weakReference,
    ) {
      return (_, android_webview.WebView webView, android_webview.FileChooserParams params) async {
        if (weakReference.target?._onShowFileSelectorCallback != null) {
          return weakReference.target!._onShowFileSelectorCallback!(
            FileSelectorParams._fromFileChooserParams(params),
          );
        }
        return <String>[];
      };
    }),
    onConsoleMessage: withWeakReferenceTo(this, (
      WeakReference<AndroidWebViewController> weakReference,
    ) {
      return (
        android_webview.WebChromeClient webChromeClient,
        android_webview.ConsoleMessage consoleMessage,
      ) async {
        final void Function(JavaScriptConsoleMessage)? callback =
            weakReference.target?._onConsoleLogCallback;
        if (callback != null) {
          JavaScriptLogLevel logLevel;
          switch (consoleMessage.level) {
            // Android maps `console.debug` to `MessageLevel.TIP`, it seems
            // `MessageLevel.DEBUG` if not being used.
            case android_webview.ConsoleMessageLevel.debug:
            case android_webview.ConsoleMessageLevel.tip:
              logLevel = JavaScriptLogLevel.debug;
            case android_webview.ConsoleMessageLevel.error:
              logLevel = JavaScriptLogLevel.error;
            case android_webview.ConsoleMessageLevel.warning:
              logLevel = JavaScriptLogLevel.warning;
            case android_webview.ConsoleMessageLevel.unknown:
            case android_webview.ConsoleMessageLevel.log:
              logLevel = JavaScriptLogLevel.log;
          }

          callback(JavaScriptConsoleMessage(level: logLevel, message: consoleMessage.message));
        }
      };
    }),
    onPermissionRequest: withWeakReferenceTo(this, (
      WeakReference<AndroidWebViewController> weakReference,
    ) {
      return (_, android_webview.PermissionRequest request) async {
        final void Function(PlatformWebViewPermissionRequest)? callback =
            weakReference.target?._onPermissionRequestCallback;
        if (callback == null) {
          return request.deny();
        } else {
          final Set<WebViewPermissionResourceType> types = request.resources.nonNulls
              .map<WebViewPermissionResourceType?>((String type) {
                switch (type) {
                  case PermissionRequestConstants.videoCapture:
                    return WebViewPermissionResourceType.camera;
                  case PermissionRequestConstants.audioCapture:
                    return WebViewPermissionResourceType.microphone;
                  case PermissionRequestConstants.midiSysex:
                    return AndroidWebViewPermissionResourceType.midiSysex;
                  case PermissionRequestConstants.protectedMediaId:
                    return AndroidWebViewPermissionResourceType.protectedMediaId;
                }

                // Type not supported.
                return null;
              })
              .whereType<WebViewPermissionResourceType>()
              .toSet();

          // If the request didn't contain any permissions recognized by the
          // implementation, deny by default.
          if (types.isEmpty) {
            return request.deny();
          }

          callback(AndroidWebViewPermissionRequest._(types: types, request: request));
        }
      };
    }),
    onJsAlert: withWeakReferenceTo(this, (WeakReference<AndroidWebViewController> weakReference) {
      return (_, _, String url, String message) async {
        final Future<void> Function(JavaScriptAlertDialogRequest)? callback =
            weakReference.target?._onJavaScriptAlert;
        if (callback != null) {
          final request = JavaScriptAlertDialogRequest(message: message, url: url);

          await callback.call(request);
        }
        return;
      };
    }),
    onJsConfirm: withWeakReferenceTo(this, (WeakReference<AndroidWebViewController> weakReference) {
      return (_, _, String url, String message) async {
        final Future<bool> Function(JavaScriptConfirmDialogRequest)? callback =
            weakReference.target?._onJavaScriptConfirm;
        if (callback != null) {
          final request = JavaScriptConfirmDialogRequest(message: message, url: url);
          final bool result = await callback.call(request);
          return result;
        }
        return false;
      };
    }),
    onJsPrompt: withWeakReferenceTo(this, (WeakReference<AndroidWebViewController> weakReference) {
      return (_, _, String url, String message, String defaultValue) async {
        final Future<String> Function(JavaScriptTextInputDialogRequest)? callback =
            weakReference.target?._onJavaScriptPrompt;
        if (callback != null) {
          final request = JavaScriptTextInputDialogRequest(
            message: message,
            url: url,
            defaultText: defaultValue,
          );
          final String result = await callback.call(request);
          return result;
        }
        return '';
      };
    }),
  );

  /// The native [android_webview.FlutterAssetManager] allows managing assets.
  late final android_webview.FlutterAssetManager _flutterAssetManager =
      android_webview.FlutterAssetManager.instance;

  final Map<String, AndroidJavaScriptChannelParams> _javaScriptChannelParams =
      <String, AndroidJavaScriptChannelParams>{};

  AndroidNavigationDelegate? _currentNavigationDelegate;

  Future<List<String>> Function(FileSelectorParams)? _onShowFileSelectorCallback;

  OnGeolocationPermissionsShowPrompt? _onGeolocationPermissionsShowPrompt;

  OnGeolocationPermissionsHidePrompt? _onGeolocationPermissionsHidePrompt;

  OnShowCustomWidgetCallback? _onShowCustomWidgetCallback;

  OnHideCustomWidgetCallback? _onHideCustomWidgetCallback;

  void Function(PlatformWebViewPermissionRequest)? _onPermissionRequestCallback;

  void Function(JavaScriptConsoleMessage consoleMessage)? _onConsoleLogCallback;

  Future<void> Function(JavaScriptAlertDialogRequest request)? _onJavaScriptAlert;
  Future<bool> Function(JavaScriptConfirmDialogRequest request)? _onJavaScriptConfirm;
  Future<String> Function(JavaScriptTextInputDialogRequest request)? _onJavaScriptPrompt;

  void Function(ScrollPositionChange scrollPositionChange)? _onScrollPositionChangedCallback;

  /// Sets the file access permission for the web view.
  ///
  /// The default value is true for apps targeting API 29 and below, and false
  /// when targeting API 30 and above.
  Future<void> setAllowFileAccess(bool allow) => _webView.settings.setAllowFileAccess(allow);

  /// Whether to enable the platform's webview content debugging tools.
  ///
  /// Defaults to false.
  static Future<void> enableDebugging(bool enabled) {
    return android_webview.WebView.setWebContentsDebuggingEnabled(enabled);
  }

  /// Identifier used to retrieve the underlying native `WebView`.
  ///
  /// This is typically used by other plugins to retrieve the native `WebView`
  /// from an `InstanceManager`.
  ///
  /// See Java method `WebViewFlutterPlugin.getWebView`.
  int get webViewIdentifier =>
      android_webview.PigeonInstanceManager.instance.getIdentifier(_webView)!;

  @override
  Future<void> loadFile(String absoluteFilePath) {
    return loadFileWithParams(AndroidLoadFileParams(absoluteFilePath: absoluteFilePath));
  }

  @override
  Future<void> loadFileWithParams(LoadFileParams params) async {
    switch (params) {
      case final AndroidLoadFileParams params:
        await Future.wait(<Future<void>>[
          _webView.settings.setAllowFileAccess(true),
          _webView.loadUrl(params.absoluteFilePath, params.headers),
        ]);

      default:
        await loadFileWithParams(AndroidLoadFileParams.fromLoadFileParams(params));
    }
  }

  @override
  Future<void> loadFlutterAsset(String key) async {
    final String assetFilePath = await _flutterAssetManager.getAssetFilePathByName(key);
    final List<String> pathElements = assetFilePath.split('/');
    final String fileName = pathElements.removeLast();
    final List<String?> paths = await _flutterAssetManager.list(pathElements.join('/'));

    if (!paths.contains(fileName)) {
      throw ArgumentError('Asset for key "$key" not found.', 'key');
    }

    return _webView.loadUrl(
      Uri.file('/android_asset/$assetFilePath').toString(),
      <String, String>{},
    );
  }

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) {
    return _webView.loadDataWithBaseUrl(baseUrl, html, 'text/html', null, null);
  }

  @override
  Future<void> loadRequest(LoadRequestParams params) {
    if (!params.uri.hasScheme) {
      throw ArgumentError('WebViewRequest#uri is required to have a scheme.');
    }
    switch (params.method) {
      case LoadRequestMethod.get:
        return _webView.loadUrl(params.uri.toString(), params.headers);
      case LoadRequestMethod.post:
        return _webView.postUrl(params.uri.toString(), params.body ?? Uint8List(0));
    }
    // The enum comes from a different package, which could get a new value at
    // any time, so a fallback case is necessary. Since there is no reasonable
    // default behavior, throw to alert the client that they need an updated
    // version. This is deliberately outside the switch rather than a `default`
    // so that the linter will flag the switch as needing an update.
    // ignore: dead_code
    throw UnimplementedError(
      'This version of `AndroidWebViewController` currently has no '
      'implementation for HTTP method ${params.method.serialize()} in '
      'loadRequest.',
    );
  }

  @override
  Future<String?> currentUrl() => _webView.getUrl();

  @override
  Future<bool> canGoBack() => _webView.canGoBack();

  @override
  Future<bool> canGoForward() => _webView.canGoForward();

  @override
  Future<void> goBack() => _webView.goBack();

  @override
  Future<void> goForward() => _webView.goForward();

  @override
  Future<void> reload() => _webView.reload();

  @override
  Future<void> clearCache() => _webView.clearCache(true);

  @override
  Future<void> clearLocalStorage() => _androidWebViewParams.androidWebStorage.deleteAllData();

  @override
  Future<void> setPlatformNavigationDelegate(covariant AndroidNavigationDelegate handler) async {
    _currentNavigationDelegate = handler;
    await Future.wait(<Future<void>>[
      handler.setOnLoadRequest(loadRequest),
      _webView.setWebViewClient(handler.androidWebViewClient),
      _webView.setDownloadListener(handler.androidDownloadListener),
    ]);
  }

  @override
  Future<void> runJavaScript(String javaScript) {
    return _webView.evaluateJavascript(javaScript);
  }

  @override
  Future<Object> runJavaScriptReturningResult(String javaScript) async {
    final String? result = await _webView.evaluateJavascript(javaScript);

    if (result == null) {
      return '';
    } else if (result == 'true') {
      return true;
    } else if (result == 'false') {
      return false;
    }

    return num.tryParse(result) ?? result;
  }

  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams javaScriptChannelParams) {
    final AndroidJavaScriptChannelParams androidJavaScriptParams =
        javaScriptChannelParams is AndroidJavaScriptChannelParams
        ? javaScriptChannelParams
        : AndroidJavaScriptChannelParams.fromJavaScriptChannelParams(javaScriptChannelParams);

    // When JavaScript channel with the same name exists make sure to remove it
    // before registering the new channel.
    if (_javaScriptChannelParams.containsKey(androidJavaScriptParams.name)) {
      _webView.removeJavaScriptChannel(androidJavaScriptParams.name);
    }

    _javaScriptChannelParams[androidJavaScriptParams.name] = androidJavaScriptParams;

    return _webView.addJavaScriptChannel(androidJavaScriptParams._javaScriptChannel);
  }

  @override
  Future<void> removeJavaScriptChannel(String javaScriptChannelName) async {
    final AndroidJavaScriptChannelParams? javaScriptChannelParams =
        _javaScriptChannelParams[javaScriptChannelName];
    if (javaScriptChannelParams == null) {
      return;
    }

    _javaScriptChannelParams.remove(javaScriptChannelName);
    return _webView.removeJavaScriptChannel(javaScriptChannelParams.name);
  }

  @override
  Future<String?> getTitle() => _webView.getTitle();

  @override
  Future<void> scrollTo(int x, int y) => _webView.scrollTo(x, y);

  @override
  Future<void> scrollBy(int x, int y) => _webView.scrollBy(x, y);

  @override
  Future<Offset> getScrollPosition() async {
    final android_webview.WebViewPoint point = await _webView.getScrollPosition();
    return Offset(point.x.toDouble(), point.y.toDouble());
  }

  @override
  Future<void> enableZoom(bool enabled) => _webView.settings.setSupportZoom(enabled);

  @override
  Future<void> setBackgroundColor(Color color) => _webView.setBackgroundColor(color.toARGB32());

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) =>
      _webView.settings.setJavaScriptEnabled(javaScriptMode == JavaScriptMode.unrestricted);

  @override
  Future<void> setUserAgent(String? userAgent) => _webView.settings.setUserAgentString(userAgent);

  @override
  Future<void> setOnScrollPositionChange(
    void Function(ScrollPositionChange scrollPositionChange)? onScrollPositionChange,
  ) async {
    _onScrollPositionChangedCallback = onScrollPositionChange;
  }

  /// Sets the restrictions that apply on automatic media playback.
  Future<void> setMediaPlaybackRequiresUserGesture(bool require) {
    return _webView.settings.setMediaPlaybackRequiresUserGesture(require);
  }

  /// Sets the text zoom of the page in percent.
  ///
  /// The default is 100.
  Future<void> setTextZoom(int textZoom) => _webView.settings.setTextZoom(textZoom);

  /// Sets whether the WebView should enable support for the "viewport" HTML
  /// meta tag or should use a wide viewport.
  ///
  /// The default is false.
  Future<void> setUseWideViewPort(bool use) => _webView.settings.setUseWideViewPort(use);

  /// Enables or disables content URL access.
  ///
  /// The default is true.
  Future<void> setAllowContentAccess(bool enabled) =>
      _webView.settings.setAllowContentAccess(enabled);

  /// Sets whether Geolocation is enabled.
  ///
  /// The default is true.
  Future<void> setGeolocationEnabled(bool enabled) =>
      _webView.settings.setGeolocationEnabled(enabled);

  /// Sets the callback that is invoked when the client should show a file
  /// selector.
  Future<void> setOnShowFileSelector(
    Future<List<String>> Function(FileSelectorParams params)? onShowFileSelector,
  ) {
    _onShowFileSelectorCallback = onShowFileSelector;
    return _webChromeClient.setSynchronousReturnValueForOnShowFileChooser(
      onShowFileSelector != null,
    );
  }

  /// Sets a callback that notifies the host application that web content is
  /// requesting permission to access the specified resources.
  @override
  Future<void> setOnPlatformPermissionRequest(
    void Function(PlatformWebViewPermissionRequest request) onPermissionRequest,
  ) async {
    _onPermissionRequestCallback = onPermissionRequest;
  }

  /// Sets the callback that is invoked when the client request handle geolocation permissions.
  ///
  /// Param [onShowPrompt] notifies the host application that web content from the specified origin is attempting to use the Geolocation API,
  /// but no permission state is currently set for that origin.
  ///
  /// The host application should invoke the specified callback with the desired permission state.
  /// See GeolocationPermissions for details.
  ///
  /// This method is only called for requests originating from secure origins such as https.
  /// On non-secure origins geolocation requests are automatically denied.
  ///
  /// Param [onHidePrompt] notifies the host application that a request for Geolocation permissions,
  /// made with a previous call to onGeolocationPermissionsShowPrompt() has been canceled.
  /// Any related UI should therefore be hidden.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebChromeClient#onGeolocationPermissionsShowPrompt(java.lang.String,%20android.webkit.GeolocationPermissions.Callback)
  ///
  /// See https://developer.android.com/reference/android/webkit/WebChromeClient#onGeolocationPermissionsHidePrompt()
  Future<void> setGeolocationPermissionsPromptCallbacks({
    OnGeolocationPermissionsShowPrompt? onShowPrompt,
    OnGeolocationPermissionsHidePrompt? onHidePrompt,
  }) async {
    _onGeolocationPermissionsShowPrompt = onShowPrompt;
    _onGeolocationPermissionsHidePrompt = onHidePrompt;
  }

  /// Sets the callbacks that are invoked when the host application wants to
  /// show or hide a custom widget.
  ///
  /// The most common use case these methods are invoked a video element wants
  /// to be displayed in fullscreen.
  ///
  /// The [onShowCustomWidget] notifies the host application that web content
  /// from the specified origin wants to be displayed in a custom widget. After
  /// this call, web content will no longer be rendered in the `WebViewWidget`,
  /// but will instead be rendered in the custom widget. The application may
  /// explicitly exit fullscreen mode by invoking `onCustomWidgetHidden` in the
  /// [onShowCustomWidget] callback (ex. when the user presses the back
  /// button). However, this is generally not necessary as the web page will
  /// often show its own UI to close out of fullscreen. Regardless of how the
  /// WebView exits fullscreen mode, WebView will invoke [onHideCustomWidget],
  /// signaling for the application to remove the custom widget. If this value
  /// is `null` when passed to an `AndroidWebViewWidget`, a default handler
  /// will be set.
  ///
  /// The [onHideCustomWidget] notifies the host application that the custom
  /// widget must be hidden. After this call, web content will render in the
  /// original `WebViewWidget` again.
  Future<void> setCustomWidgetCallbacks({
    required OnShowCustomWidgetCallback? onShowCustomWidget,
    required OnHideCustomWidgetCallback? onHideCustomWidget,
  }) async {
    _onShowCustomWidgetCallback = onShowCustomWidget;
    _onHideCustomWidgetCallback = onHideCustomWidget;
  }

  /// Sets a callback that notifies the host application of any log messages
  /// written to the JavaScript console.
  @override
  Future<void> setOnConsoleMessage(
    void Function(JavaScriptConsoleMessage consoleMessage) onConsoleMessage,
  ) async {
    _onConsoleLogCallback = onConsoleMessage;

    return _webChromeClient.setSynchronousReturnValueForOnConsoleMessage(
      _onConsoleLogCallback != null,
    );
  }

  @override
  Future<String?> getUserAgent() => _webView.settings.getUserAgentString();

  @override
  Future<void> setOnJavaScriptAlertDialog(
    Future<void> Function(JavaScriptAlertDialogRequest request) onJavaScriptAlertDialog,
  ) async {
    _onJavaScriptAlert = onJavaScriptAlertDialog;
    return _webChromeClient.setSynchronousReturnValueForOnJsAlert(true);
  }

  @override
  Future<void> setOnJavaScriptConfirmDialog(
    Future<bool> Function(JavaScriptConfirmDialogRequest request) onJavaScriptConfirmDialog,
  ) async {
    _onJavaScriptConfirm = onJavaScriptConfirmDialog;
    return _webChromeClient.setSynchronousReturnValueForOnJsConfirm(true);
  }

  @override
  Future<void> setOnJavaScriptTextInputDialog(
    Future<String> Function(JavaScriptTextInputDialogRequest request) onJavaScriptTextInputDialog,
  ) async {
    _onJavaScriptPrompt = onJavaScriptTextInputDialog;
    return _webChromeClient.setSynchronousReturnValueForOnJsPrompt(true);
  }

  @override
  Future<void> setVerticalScrollBarEnabled(bool enabled) =>
      _webView.setVerticalScrollBarEnabled(enabled);

  @override
  Future<void> setHorizontalScrollBarEnabled(bool enabled) =>
      _webView.setHorizontalScrollBarEnabled(enabled);

  @override
  bool supportsSetScrollBarsEnabled() => true;

  @override
  Future<void> setOverScrollMode(WebViewOverScrollMode mode) {
    return switch (mode) {
      WebViewOverScrollMode.always => _webView.setOverScrollMode(
        android_webview.OverScrollMode.always,
      ),
      WebViewOverScrollMode.ifContentScrolls => _webView.setOverScrollMode(
        android_webview.OverScrollMode.ifContentScrolls,
      ),
      WebViewOverScrollMode.never => _webView.setOverScrollMode(
        android_webview.OverScrollMode.never,
      ),
      // This prevents future additions from causing a breaking change.
      // ignore: unreachable_switch_case
      _ => throw UnsupportedError('Android does not support $mode.'),
    };
  }

  /// Configures the WebView's behavior when handling mixed content.
  Future<void> setMixedContentMode(MixedContentMode mode) {
    final android_webview.MixedContentMode androidMode = switch (mode) {
      MixedContentMode.alwaysAllow => android_webview.MixedContentMode.alwaysAllow,
      MixedContentMode.compatibilityMode => android_webview.MixedContentMode.compatibilityMode,
      MixedContentMode.neverAllow => android_webview.MixedContentMode.neverAllow,
    };
    return _webView.settings.setMixedContentMode(androidMode);
  }

  /// Checks if a WebView feature is supported on the current device.
  ///
  /// This method uses [android_webview.WebViewFeature.isFeatureSupported] to check
  /// if the specified WebView feature is available on the current device and WebView version.
  ///
  /// See [WebViewFeatureType] for available feature constants.
  Future<bool> isWebViewFeatureSupported(WebViewFeatureType featureType) {
    final String feature = switch (featureType) {
      WebViewFeatureType.paymentRequest => WebViewFeatureConstants.paymentRequest,
    };
    return android_webview.WebViewFeature.isFeatureSupported(feature);
  }

  /// Sets whether the WebView should enable the Payment Request API.
  ///
  /// This method uses [android_webview.WebSettingsCompat.setPaymentRequestEnabled]
  /// to enable or disable the Payment Request API for the WebView.
  ///
  /// Before calling this method, you should check if the feature is supported using
  /// [isWebViewFeatureSupported] with [WebViewFeatureType.paymentRequest].
  ///
  /// This feature requires adding queries to the AndroidManifest.xml to allow WebView to query the device for the user's payment applications:
  /// See https://developer.android.com/reference/androidx/webkit/WebSettingsCompat#setPaymentRequestEnabled(android.webkit.WebSettings,boolean).
  Future<void> setPaymentRequestEnabled(bool enabled) {
    return android_webview.WebSettingsCompat.setPaymentRequestEnabled(_webView.settings, enabled);
  }

  /// Sets the insets that the native View should prevent the web contents from
  /// receiving.
  Future<void> setInsetsForWebContentToIgnore(List<AndroidWebViewInsets> insets) async {
    return _webView.setInsetListenerToSetInsetsToZero(
      insets
          .map(
            (AndroidWebViewInsets inset) => switch (inset) {
              AndroidWebViewInsets.systemBars => android_webview.WindowInsetsType.systemBars,
              AndroidWebViewInsets.displayCutout => android_webview.WindowInsetsType.displayCutout,
              AndroidWebViewInsets.captionBar => android_webview.WindowInsetsType.captionBar,
              AndroidWebViewInsets.ime => android_webview.WindowInsetsType.ime,
              AndroidWebViewInsets.mandatorySystemGestures =>
                android_webview.WindowInsetsType.mandatorySystemGestures,
              AndroidWebViewInsets.navigationBars =>
                android_webview.WindowInsetsType.navigationBars,
              AndroidWebViewInsets.statusBars => android_webview.WindowInsetsType.statusBars,
              AndroidWebViewInsets.systemGestures =>
                android_webview.WindowInsetsType.systemGestures,
              AndroidWebViewInsets.tappableElement =>
                android_webview.WindowInsetsType.tappableElement,
            },
          )
          .toSet()
          .toList(),
    );
  }
}

/// Android implementation of [PlatformWebViewPermissionRequest].
class AndroidWebViewPermissionRequest extends PlatformWebViewPermissionRequest {
  const AndroidWebViewPermissionRequest._({required super.types, required this._request});

  final android_webview.PermissionRequest _request;

  @override
  Future<void> grant() {
    return _request.grant(
      types.map<String>((WebViewPermissionResourceType type) {
        switch (type) {
          case WebViewPermissionResourceType.camera:
            return PermissionRequestConstants.videoCapture;
          case WebViewPermissionResourceType.microphone:
            return PermissionRequestConstants.audioCapture;
          case AndroidWebViewPermissionResourceType.midiSysex:
            return PermissionRequestConstants.midiSysex;
          case AndroidWebViewPermissionResourceType.protectedMediaId:
            return PermissionRequestConstants.protectedMediaId;
        }

        throw UnsupportedError('Resource of type `${type.name}` is not supported.');
      }).toList(),
    );
  }

  @override
  Future<void> deny() {
    return _request.deny();
  }
}

/// Signature for the `setGeolocationPermissionsPromptCallbacks` callback responsible for request the Geolocation API.
typedef OnGeolocationPermissionsShowPrompt =
    Future<GeolocationPermissionsResponse> Function(GeolocationPermissionsRequestParams request);

/// Signature for the `setGeolocationPermissionsPromptCallbacks` callback responsible for request the Geolocation API is cancel.
typedef OnGeolocationPermissionsHidePrompt = void Function();

/// Signature for the `setCustomWidgetCallbacks` callback responsible for showing the custom view.
typedef OnShowCustomWidgetCallback =
    void Function(Widget widget, void Function() onCustomWidgetHidden);

/// Signature for the `setCustomWidgetCallbacks` callback responsible for hiding the custom view.
typedef OnHideCustomWidgetCallback = void Function();

/// A request params used by the host application to set the Geolocation permission state for an origin.
@immutable
class GeolocationPermissionsRequestParams {
  /// [origin]: The origin for which permissions are set.
  const GeolocationPermissionsRequestParams({required this.origin});

  /// [origin]: The origin for which permissions are set.
  final String origin;
}

/// A response used by the host application to set the Geolocation permission state for an origin.
@immutable
class GeolocationPermissionsResponse {
  /// [allow]: Whether or not the origin should be allowed to use the Geolocation API.
  ///
  /// [retain]: Whether the permission should be retained beyond the lifetime of
  /// a page currently being displayed by a WebView.
  const GeolocationPermissionsResponse({required this.allow, required this.retain});

  /// Whether or not the origin should be allowed to use the Geolocation API.
  final bool allow;

  /// Whether the permission should be retained beyond the lifetime of
  /// a page currently being displayed by a WebView.
  final bool retain;
}

/// Mode of how to select files for a file chooser.
enum FileSelectorMode {
  /// Open single file and requires that the file exists before allowing the
  /// user to pick it.
  open,

  /// Similar to [open] but allows multiple files to be selected.
  openMultiple,

  /// Allows picking a nonexistent file and saving it.
  save,
}

/// Mode for controlling mixed content handling.

/// See [AndroidWebViewController.setMixedContentMode].
enum MixedContentMode {
  /// The WebView will allow a secure origin to load content from any other
  /// origin, even if that origin is insecure.
  ///
  /// This is the least secure mode of operation, and where possible apps should
  /// not set this mode.
  alwaysAllow,

  /// The WebView will attempt to be compatible with the approach of a modern
  /// web browser with regard to mixed content.
  ///
  /// The types of content are allowed or blocked may change release to release
  /// of the underlying Android WebView, and are not explicitly defined. This
  /// mode is intended to be used by apps that are not in control of the content
  /// that they render but desire to operate in a reasonably secure environment.
  compatibilityMode,

  /// The WebView will not allow a secure origin to load content from an
  /// insecure origin.
  ///
  /// This is the preferred and most secure mode of operation, and apps are
  /// strongly advised to use this mode.
  ///
  /// This is the default mode.
  neverAllow,
}

/// WebView support library feature types used to query for support on the device.
///
/// See https://developer.android.com/reference/androidx/webkit/WebViewFeature#constants_1.
enum WebViewFeatureType {
  /// Feature for isFeatureSupported.
  ///
  /// This feature covers [WebSettingsCompat.setPaymentRequestEnabled].
  paymentRequest,
}

/// Parameters received when the `WebView` should show a file selector.
@immutable
class FileSelectorParams {
  /// Constructs a [FileSelectorParams].
  const FileSelectorParams({
    required this.isCaptureEnabled,
    required this.acceptTypes,
    this.filenameHint,
    required this.mode,
  });

  factory FileSelectorParams._fromFileChooserParams(android_webview.FileChooserParams params) {
    final FileSelectorMode mode;
    switch (params.mode) {
      case android_webview.FileChooserMode.open:
        mode = FileSelectorMode.open;
      case android_webview.FileChooserMode.openMultiple:
        mode = FileSelectorMode.openMultiple;
      case android_webview.FileChooserMode.save:
        mode = FileSelectorMode.save;
      case android_webview.FileChooserMode.unknown:
        throw UnsupportedError(
          'FileSelectorParams could not be instantiated because it received an unsupported mode.',
        );
    }

    return FileSelectorParams(
      isCaptureEnabled: params.isCaptureEnabled,
      acceptTypes: params.acceptTypes.nonNulls.toList(),
      mode: mode,
      filenameHint: params.filenameHint,
    );
  }

  /// Preference for a live media captured value (e.g. Camera, Microphone).
  final bool isCaptureEnabled;

  /// A list of acceptable MIME types.
  final List<String> acceptTypes;

  /// The file name of a default selection if specified, or null.
  final String? filenameHint;

  /// Mode of how to select files for a file selector.
  final FileSelectorMode mode;
}

/// An implementation of [JavaScriptChannelParams] with the Android WebView API.
///
/// See [AndroidWebViewController.addJavaScriptChannel].
@immutable
class AndroidJavaScriptChannelParams extends JavaScriptChannelParams {
  /// Constructs a [AndroidJavaScriptChannelParams].
  AndroidJavaScriptChannelParams({required super.name, required super.onMessageReceived})
    : assert(name.isNotEmpty),
      _javaScriptChannel = android_webview.JavaScriptChannel(
        channelName: name,
        postMessage: withWeakReferenceTo(onMessageReceived, (
          WeakReference<void Function(JavaScriptMessage)> weakReference,
        ) {
          return (_, String message) {
            if (weakReference.target != null) {
              weakReference.target!(JavaScriptMessage(message: message));
            }
          };
        }),
      );

  /// Constructs a [AndroidJavaScriptChannelParams] using a
  /// [JavaScriptChannelParams].
  AndroidJavaScriptChannelParams.fromJavaScriptChannelParams(JavaScriptChannelParams params)
    : this(name: params.name, onMessageReceived: params.onMessageReceived);

  final android_webview.JavaScriptChannel _javaScriptChannel;
}

/// Object specifying creation parameters for creating a [AndroidWebViewWidget].
///
/// When adding additional fields make sure they can be null or have a default
/// value to avoid breaking changes. See [PlatformWebViewWidgetCreationParams] for
/// more information.
@immutable
class AndroidWebViewWidgetCreationParams extends PlatformWebViewWidgetCreationParams {
  /// Creates [AndroidWebWidgetCreationParams].
  const AndroidWebViewWidgetCreationParams({
    super.key,
    required super.controller,
    super.layoutDirection,
    super.gestureRecognizers,
    this.displayWithHybridComposition = false,
    @visibleForTesting this.platformViewsServiceProxy = const PlatformViewsServiceProxy(),
  });

  /// Constructs a [WebKitWebViewWidgetCreationParams] using a
  /// [PlatformWebViewWidgetCreationParams].
  AndroidWebViewWidgetCreationParams.fromPlatformWebViewWidgetCreationParams(
    PlatformWebViewWidgetCreationParams params, {
    bool displayWithHybridComposition = false,
    @visibleForTesting
    PlatformViewsServiceProxy platformViewsServiceProxy = const PlatformViewsServiceProxy(),
  }) : this(
         key: params.key,
         controller: params.controller,
         layoutDirection: params.layoutDirection,
         gestureRecognizers: params.gestureRecognizers,
         displayWithHybridComposition: displayWithHybridComposition,
         platformViewsServiceProxy: platformViewsServiceProxy,
       );

  /// Proxy that provides access to the platform views service.
  ///
  /// This service allows creating and controlling platform-specific views.
  @visibleForTesting
  final PlatformViewsServiceProxy platformViewsServiceProxy;

  /// Whether the [WebView] will be displayed using the Hybrid Composition
  /// PlatformView implementation.
  ///
  /// For most use cases, this flag should be set to false. Hybrid Composition
  /// can have performance costs but doesn't have the limitation of rendering to
  /// an Android SurfaceTexture. See
  /// * https://docs.flutter.dev/platform-integration/android/platform-views#performance
  /// * https://github.com/flutter/flutter/issues/104889
  /// * https://github.com/flutter/flutter/issues/116954
  ///
  /// Defaults to false.
  final bool displayWithHybridComposition;

  @override
  int get hashCode => Object.hash(
    controller,
    layoutDirection,
    displayWithHybridComposition,
    platformViewsServiceProxy,
  );

  @override
  bool operator ==(Object other) {
    return other is AndroidWebViewWidgetCreationParams &&
        controller == other.controller &&
        layoutDirection == other.layoutDirection &&
        displayWithHybridComposition == other.displayWithHybridComposition &&
        platformViewsServiceProxy == other.platformViewsServiceProxy;
  }
}

/// An implementation of [PlatformWebViewWidget] with the Android WebView API.
class AndroidWebViewWidget extends PlatformWebViewWidget {
  /// Constructs a [WebKitWebViewWidget].
  AndroidWebViewWidget(PlatformWebViewWidgetCreationParams params)
    : super.implementation(
        params is AndroidWebViewWidgetCreationParams
            ? params
            : AndroidWebViewWidgetCreationParams.fromPlatformWebViewWidgetCreationParams(params),
      );

  AndroidWebViewWidgetCreationParams get _androidParams =>
      params as AndroidWebViewWidgetCreationParams;

  @override
  Widget build(BuildContext context) {
    _trySetDefaultOnShowCustomWidgetCallbacks(context);
    return ClipRect(
      child: PlatformViewLink(
        // Setting a default key using `params` ensures the `PlatformViewLink`
        // recreates the PlatformView when changes are made.
        key:
            _androidParams.key ??
            ValueKey<AndroidWebViewWidgetCreationParams>(
              params as AndroidWebViewWidgetCreationParams,
            ),
        viewType: 'plugins.flutter.io/webview',
        surfaceFactory: (BuildContext context, PlatformViewController controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: _androidParams.gestureRecognizers,
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (PlatformViewCreationParams params) {
          return _initAndroidView(
              params,
              displayWithHybridComposition: _androidParams.displayWithHybridComposition,
              platformViewsServiceProxy: _androidParams.platformViewsServiceProxy,
              view: (_androidParams.controller as AndroidWebViewController)._webView,
              layoutDirection: _androidParams.layoutDirection,
            )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..create();
        },
      ),
    );
  }

  // Attempt to handle custom views with a default implementation if it has not
  // been set.
  void _trySetDefaultOnShowCustomWidgetCallbacks(BuildContext context) {
    final controller = _androidParams.controller as AndroidWebViewController;

    if (controller._onShowCustomWidgetCallback == null) {
      controller.setCustomWidgetCallbacks(
        onShowCustomWidget: (Widget widget, OnHideCustomWidgetCallback callback) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext context) => widget,
              fullscreenDialog: true,
            ),
          );
        },
        onHideCustomWidget: () {
          Navigator.of(context).pop();
        },
      );
    }
  }
}

/// Represents a Flutter implementation of the Android [View](https://developer.android.com/reference/android/view/View)
/// that is created by the host platform when web content needs to be displayed
/// in fullscreen mode.
///
/// The [AndroidCustomViewWidget] cannot be manually instantiated and is
/// provided to the host application through the callbacks specified using the
/// [AndroidWebViewController.setCustomWidgetCallbacks] method.
///
/// The [AndroidCustomViewWidget] is initialized internally and should only be
/// exposed as a [Widget] externally. The type [AndroidCustomViewWidget] is
/// visible for testing purposes only and should never be called externally.
@visibleForTesting
class AndroidCustomViewWidget extends StatelessWidget {
  /// Creates a [AndroidCustomViewWidget].
  ///
  /// The [AndroidCustomViewWidget] should only be instantiated internally.
  /// This constructor is visible for testing purposes only and should
  /// never be called externally.
  @visibleForTesting
  const AndroidCustomViewWidget.private({
    super.key,
    required this.controller,
    required this.customView,
    @visibleForTesting this.platformViewsServiceProxy = const PlatformViewsServiceProxy(),
  });

  /// The reference to the Android native view that should be shown.
  final android_webview.View customView;

  /// The [PlatformWebViewController] that allows controlling the native web
  /// view.
  final PlatformWebViewController controller;

  /// Proxy that provides access to the platform views service.
  ///
  /// This service allows creating and controlling platform-specific views.
  @visibleForTesting
  final PlatformViewsServiceProxy platformViewsServiceProxy;

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      key: key,
      viewType: 'plugins.flutter.io/webview',
      surfaceFactory: (BuildContext context, PlatformViewController controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        );
      },
      onCreatePlatformView: (PlatformViewCreationParams params) {
        return _initAndroidView(
            params,
            displayWithHybridComposition: false,
            platformViewsServiceProxy: platformViewsServiceProxy,
            view: customView,
          )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..create();
      },
    );
  }
}

AndroidViewController _initAndroidView(
  PlatformViewCreationParams params, {
  required bool displayWithHybridComposition,
  required PlatformViewsServiceProxy platformViewsServiceProxy,
  required android_webview.View view,
  TextDirection layoutDirection = TextDirection.ltr,
}) {
  final int identifier = android_webview.PigeonInstanceManager.instance.getIdentifier(view)!;

  if (displayWithHybridComposition) {
    return platformViewsServiceProxy.initExpensiveAndroidView(
      id: params.id,
      viewType: 'plugins.flutter.io/webview',
      layoutDirection: layoutDirection,
      creationParams: identifier,
      creationParamsCodec: const StandardMessageCodec(),
    );
  } else {
    return platformViewsServiceProxy.initSurfaceAndroidView(
      id: params.id,
      viewType: 'plugins.flutter.io/webview',
      layoutDirection: layoutDirection,
      creationParams: identifier,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

/// Signature for the `loadRequest` callback responsible for loading the [url]
/// after a navigation request has been approved.
typedef LoadRequestCallback = Future<void> Function(LoadRequestParams params);

/// Error returned in `WebView.onWebResourceError` when a web resource loading error has occurred.
@immutable
class AndroidWebResourceError extends WebResourceError {
  /// Creates a new [AndroidWebResourceError].
  AndroidWebResourceError._({
    required super.errorCode,
    required super.description,
    super.isForMainFrame,
    super.url,
  }) : failingUrl = url,
       super(errorType: _errorCodeToErrorType(errorCode));

  /// Gets the URL for which the failing resource request was made.
  @Deprecated('Please use `url`.')
  final String? failingUrl;

  static WebResourceErrorType? _errorCodeToErrorType(int errorCode) {
    switch (errorCode) {
      case WebViewClientConstants.errorAuthentication:
        return WebResourceErrorType.authentication;
      case WebViewClientConstants.errorBadUrl:
        return WebResourceErrorType.badUrl;
      case WebViewClientConstants.errorConnect:
        return WebResourceErrorType.connect;
      case WebViewClientConstants.errorFailedSslHandshake:
        return WebResourceErrorType.failedSslHandshake;
      case WebViewClientConstants.errorFile:
        return WebResourceErrorType.file;
      case WebViewClientConstants.errorFileNotFound:
        return WebResourceErrorType.fileNotFound;
      case WebViewClientConstants.errorHostLookup:
        return WebResourceErrorType.hostLookup;
      case WebViewClientConstants.errorIO:
        return WebResourceErrorType.io;
      case WebViewClientConstants.errorProxyAuthentication:
        return WebResourceErrorType.proxyAuthentication;
      case WebViewClientConstants.errorRedirectLoop:
        return WebResourceErrorType.redirectLoop;
      case WebViewClientConstants.errorTimeout:
        return WebResourceErrorType.timeout;
      case WebViewClientConstants.errorTooManyRequests:
        return WebResourceErrorType.tooManyRequests;
      case WebViewClientConstants.errorUnknown:
        return WebResourceErrorType.unknown;
      case WebViewClientConstants.errorUnsafeResource:
        return WebResourceErrorType.unsafeResource;
      case WebViewClientConstants.errorUnsupportedAuthScheme:
        return WebResourceErrorType.unsupportedAuthScheme;
      case WebViewClientConstants.errorUnsupportedScheme:
        return WebResourceErrorType.unsupportedScheme;
    }

    throw ArgumentError('Could not find a WebResourceErrorType for errorCode: $errorCode');
  }
}

/// Object specifying creation parameters for creating a [AndroidNavigationDelegate].
///
/// When adding additional fields make sure they can be null or have a default
/// value to avoid breaking changes. See [PlatformNavigationDelegateCreationParams] for
/// more information.
@immutable
class AndroidNavigationDelegateCreationParams extends PlatformNavigationDelegateCreationParams {
  /// Creates a new [AndroidNavigationDelegateCreationParams] instance.
  const AndroidNavigationDelegateCreationParams._() : super();

  /// Creates a [AndroidNavigationDelegateCreationParams] instance based on [PlatformNavigationDelegateCreationParams].
  factory AndroidNavigationDelegateCreationParams.fromPlatformNavigationDelegateCreationParams(
    // Recommended placeholder to prevent being broken by platform interface.
    // ignore: avoid_unused_constructor_parameters
    PlatformNavigationDelegateCreationParams params,
  ) {
    return const AndroidNavigationDelegateCreationParams._();
  }
}

/// Android details of the change to a web view's url.
class AndroidUrlChange extends UrlChange {
  /// Constructs an [AndroidUrlChange].
  const AndroidUrlChange({required super.url, required this.isReload});

  /// Whether the url is being reloaded.
  final bool isReload;
}

/// A place to register callback methods responsible to handle navigation events
/// triggered by the [android_webview.WebView].
class AndroidNavigationDelegate extends PlatformNavigationDelegate {
  /// Creates a new [AndroidNavigationDelegate].
  AndroidNavigationDelegate(PlatformNavigationDelegateCreationParams params)
    : super.implementation(
        params is AndroidNavigationDelegateCreationParams
            ? params
            : AndroidNavigationDelegateCreationParams.fromPlatformNavigationDelegateCreationParams(
                params,
              ),
      ) {
    final weakThis = WeakReference<AndroidNavigationDelegate>(this);

    _webViewClient = android_webview.WebViewClient(
      onPageFinished: (_, android_webview.WebView webView, String url) {
        final PageEventCallback? callback = weakThis.target?._onPageFinished;
        if (callback != null) {
          callback(url);
        }
      },
      onPageStarted: (_, android_webview.WebView webView, String url) {
        final PageEventCallback? callback = weakThis.target?._onPageStarted;
        if (callback != null) {
          callback(url);
        }
      },
      onReceivedHttpError:
          (
            _,
            android_webview.WebView webView,
            android_webview.WebResourceRequest request,
            android_webview.WebResourceResponse response,
          ) {
            if (weakThis.target?._onHttpError != null) {
              weakThis.target!._onHttpError!(
                HttpResponseError(
                  request: WebResourceRequest(uri: Uri.parse(request.url)),
                  response: WebResourceResponse(uri: null, statusCode: response.statusCode),
                ),
              );
            }
          },
      onReceivedRequestError:
          (
            _,
            android_webview.WebView webView,
            android_webview.WebResourceRequest request,
            android_webview.WebResourceError error,
          ) {
            final WebResourceErrorCallback? callback = weakThis.target?._onWebResourceError;
            if (callback != null) {
              callback(
                AndroidWebResourceError._(
                  errorCode: error.errorCode,
                  description: error.description,
                  url: request.url,
                  isForMainFrame: request.isForMainFrame,
                ),
              );
            }
          },
      onReceivedRequestErrorCompat:
          (
            _,
            android_webview.WebView webView,
            android_webview.WebResourceRequest request,
            android_webview.WebResourceErrorCompat error,
          ) {
            final WebResourceErrorCallback? callback = weakThis.target?._onWebResourceError;
            if (callback != null) {
              callback(
                AndroidWebResourceError._(
                  errorCode: error.errorCode,
                  description: error.description,
                  url: request.url,
                  isForMainFrame: request.isForMainFrame,
                ),
              );
            }
          },
      requestLoading:
          (_, android_webview.WebView webView, android_webview.WebResourceRequest request) {
            weakThis.target?._handleNavigation(
              request.url,
              headers:
                  request.requestHeaders?.map<String, String>((String? key, String? value) {
                    return MapEntry<String, String>(key!, value!);
                  }) ??
                  <String, String>{},
              isForMainFrame: request.isForMainFrame,
            );
          },
      urlLoading: (_, android_webview.WebView webView, String url) {
        weakThis.target?._handleNavigation(url, isForMainFrame: true);
      },
      doUpdateVisitedHistory: (_, android_webview.WebView webView, String url, bool isReload) {
        final UrlChangeCallback? callback = weakThis.target?._onUrlChange;
        if (callback != null) {
          callback(AndroidUrlChange(url: url, isReload: isReload));
        }
      },
      onReceivedHttpAuthRequest:
          (
            _,
            android_webview.WebView webView,
            android_webview.HttpAuthHandler httpAuthHandler,
            String host,
            String realm,
          ) {
            final void Function(HttpAuthRequest)? callback = weakThis.target?._onHttpAuthRequest;
            if (callback != null) {
              callback(
                HttpAuthRequest(
                  onProceed: (WebViewCredential credential) {
                    httpAuthHandler.proceed(credential.user, credential.password);
                  },
                  onCancel: () {
                    httpAuthHandler.cancel();
                  },
                  host: host,
                  realm: realm,
                ),
              );
            } else {
              httpAuthHandler.cancel();
            }
          },
      onFormResubmission: (_, _, android_webview.AndroidMessage dontResend, _) {
        dontResend.sendToTarget();
      },
      onReceivedClientCertRequest: (_, _, android_webview.ClientCertRequest request) {
        request.cancel();
      },
      onReceivedSslError:
          (_, _, android_webview.SslErrorHandler handler, android_webview.SslError error) async {
            final void Function(PlatformSslAuthError)? callback = weakThis.target?._onSslAuthError;

            if (callback != null) {
              final AndroidSslAuthError authError = await AndroidSslAuthError.fromNativeCallback(
                error: error,
                handler: handler,
              );

              callback(authError);
            } else {
              await handler.cancel();
            }
          },
    );

    _downloadListener = android_webview.DownloadListener(
      onDownloadStart:
          (
            _,
            String url,
            String userAgent,
            String contentDisposition,
            String mimetype,
            int contentLength,
          ) {
            if (weakThis.target != null) {
              weakThis.target?._handleNavigation(url, isForMainFrame: true);
            }
          },
    );
  }

  late final android_webview.WebChromeClient _webChromeClient = android_webview.WebChromeClient(
    onJsConfirm: (_, _, _, _) async => false,
    onShowFileChooser: (_, _, _) async => <String>[],
  );

  /// Gets the native [android_webview.WebChromeClient] that is bridged by this [AndroidNavigationDelegate].
  ///
  /// Used by the [AndroidWebViewController] to set the `android_webview.WebView.setWebChromeClient`.
  @Deprecated(
    'This value is not used by `AndroidWebViewController` and has no effect on the `WebView`.',
  )
  android_webview.WebChromeClient get androidWebChromeClient => _webChromeClient;

  late final android_webview.WebViewClient _webViewClient;

  /// Gets the native [android_webview.WebViewClient] that is bridged by this [AndroidNavigationDelegate].
  ///
  /// Used by the [AndroidWebViewController] to set the `android_webview.WebView.setWebViewClient`.
  android_webview.WebViewClient get androidWebViewClient => _webViewClient;

  late final android_webview.DownloadListener _downloadListener;

  /// Gets the native [android_webview.DownloadListener] that is bridged by this [AndroidNavigationDelegate].
  ///
  /// Used by the [AndroidWebViewController] to set the `android_webview.WebView.setDownloadListener`.
  android_webview.DownloadListener get androidDownloadListener => _downloadListener;

  PageEventCallback? _onPageFinished;
  PageEventCallback? _onPageStarted;
  HttpResponseErrorCallback? _onHttpError;
  ProgressCallback? _onProgress;
  WebResourceErrorCallback? _onWebResourceError;
  NavigationRequestCallback? _onNavigationRequest;
  LoadRequestCallback? _onLoadRequest;
  UrlChangeCallback? _onUrlChange;
  HttpAuthRequestCallback? _onHttpAuthRequest;
  SslAuthErrorCallback? _onSslAuthError;

  void _handleNavigation(
    String url, {
    required bool isForMainFrame,
    Map<String, String> headers = const <String, String>{},
  }) {
    final LoadRequestCallback? onLoadRequest = _onLoadRequest;
    final NavigationRequestCallback? onNavigationRequest = _onNavigationRequest;

    // The client is only allowed to stop navigations that target the main frame because
    // overridden URLs are passed to `loadUrl` and `loadUrl` cannot load a subframe.
    if (!isForMainFrame || onNavigationRequest == null || onLoadRequest == null) {
      return;
    }

    final FutureOr<NavigationDecision> returnValue = onNavigationRequest(
      NavigationRequest(url: url, isMainFrame: isForMainFrame),
    );

    if (returnValue is NavigationDecision && returnValue == NavigationDecision.navigate) {
      onLoadRequest(LoadRequestParams(uri: Uri.parse(url), headers: headers));
    } else if (returnValue is Future<NavigationDecision>) {
      returnValue.then((NavigationDecision shouldLoadUrl) {
        if (shouldLoadUrl == NavigationDecision.navigate) {
          onLoadRequest(LoadRequestParams(uri: Uri.parse(url), headers: headers));
        }
      });
    }
  }

  /// Invoked when loading the url after a navigation request is approved.
  Future<void> setOnLoadRequest(LoadRequestCallback onLoadRequest) async {
    _onLoadRequest = onLoadRequest;
  }

  @override
  Future<void> setOnNavigationRequest(NavigationRequestCallback onNavigationRequest) async {
    _onNavigationRequest = onNavigationRequest;
    return _webViewClient.setSynchronousReturnValueForShouldOverrideUrlLoading(true);
  }

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {
    _onPageStarted = onPageStarted;
  }

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {
    _onPageFinished = onPageFinished;
  }

  @override
  Future<void> setOnHttpError(HttpResponseErrorCallback onHttpError) async {
    _onHttpError = onHttpError;
  }

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {
    _onProgress = onProgress;
  }

  @override
  Future<void> setOnWebResourceError(WebResourceErrorCallback onWebResourceError) async {
    _onWebResourceError = onWebResourceError;
  }

  @override
  Future<void> setOnUrlChange(UrlChangeCallback onUrlChange) async {
    _onUrlChange = onUrlChange;
  }

  @override
  Future<void> setOnHttpAuthRequest(HttpAuthRequestCallback onHttpAuthRequest) async {
    _onHttpAuthRequest = onHttpAuthRequest;
  }

  @override
  Future<void> setOnSSlAuthError(SslAuthErrorCallback onSslAuthError) async {
    _onSslAuthError = onSslAuthError;
  }
}
