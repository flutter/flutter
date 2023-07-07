// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(a14n): remove this import once Flutter 3.1 or later reaches stable (including flutter/flutter#106316)
// ignore: unnecessary_import
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/services.dart' show BinaryMessenger;

import 'android_webview.dart';
import 'android_webview.g.dart';
import 'instance_manager.dart';

export 'android_webview.g.dart' show FileChooserMode;

/// Converts [WebResourceRequestData] to [WebResourceRequest]
WebResourceRequest _toWebResourceRequest(WebResourceRequestData data) {
  return WebResourceRequest(
    url: data.url,
    isForMainFrame: data.isForMainFrame,
    isRedirect: data.isRedirect,
    hasGesture: data.hasGesture,
    method: data.method,
    requestHeaders: data.requestHeaders.cast<String, String>(),
  );
}

/// Converts [WebResourceErrorData] to [WebResourceError].
WebResourceError _toWebResourceError(WebResourceErrorData data) {
  return WebResourceError(
    errorCode: data.errorCode,
    description: data.description,
  );
}

/// Handles initialization of Flutter APIs for Android WebView.
class AndroidWebViewFlutterApis {
  /// Creates a [AndroidWebViewFlutterApis].
  AndroidWebViewFlutterApis({
    JavaObjectFlutterApiImpl? javaObjectFlutterApi,
    DownloadListenerFlutterApiImpl? downloadListenerFlutterApi,
    WebViewClientFlutterApiImpl? webViewClientFlutterApi,
    WebChromeClientFlutterApiImpl? webChromeClientFlutterApi,
    JavaScriptChannelFlutterApiImpl? javaScriptChannelFlutterApi,
    FileChooserParamsFlutterApiImpl? fileChooserParamsFlutterApi,
    GeolocationPermissionsCallbackFlutterApiImpl?
        geolocationPermissionsCallbackFlutterApi,
    WebViewFlutterApiImpl? webViewFlutterApi,
    PermissionRequestFlutterApiImpl? permissionRequestFlutterApi,
  }) {
    this.javaObjectFlutterApi =
        javaObjectFlutterApi ?? JavaObjectFlutterApiImpl();
    this.downloadListenerFlutterApi =
        downloadListenerFlutterApi ?? DownloadListenerFlutterApiImpl();
    this.webViewClientFlutterApi =
        webViewClientFlutterApi ?? WebViewClientFlutterApiImpl();
    this.webChromeClientFlutterApi =
        webChromeClientFlutterApi ?? WebChromeClientFlutterApiImpl();
    this.javaScriptChannelFlutterApi =
        javaScriptChannelFlutterApi ?? JavaScriptChannelFlutterApiImpl();
    this.fileChooserParamsFlutterApi =
        fileChooserParamsFlutterApi ?? FileChooserParamsFlutterApiImpl();
    this.geolocationPermissionsCallbackFlutterApi =
        geolocationPermissionsCallbackFlutterApi ??
            GeolocationPermissionsCallbackFlutterApiImpl();
    this.webViewFlutterApi = webViewFlutterApi ?? WebViewFlutterApiImpl();
    this.permissionRequestFlutterApi =
        permissionRequestFlutterApi ?? PermissionRequestFlutterApiImpl();
  }

  static bool _haveBeenSetUp = false;

  /// Mutable instance containing all Flutter Apis for Android WebView.
  ///
  /// This should only be changed for testing purposes.
  static AndroidWebViewFlutterApis instance = AndroidWebViewFlutterApis();

  /// Handles callbacks methods for the native Java Object class.
  late final JavaObjectFlutterApi javaObjectFlutterApi;

  /// Flutter Api for [DownloadListener].
  late final DownloadListenerFlutterApiImpl downloadListenerFlutterApi;

  /// Flutter Api for [WebViewClient].
  late final WebViewClientFlutterApiImpl webViewClientFlutterApi;

  /// Flutter Api for [WebChromeClient].
  late final WebChromeClientFlutterApiImpl webChromeClientFlutterApi;

  /// Flutter Api for [JavaScriptChannel].
  late final JavaScriptChannelFlutterApiImpl javaScriptChannelFlutterApi;

  /// Flutter Api for [FileChooserParams].
  late final FileChooserParamsFlutterApiImpl fileChooserParamsFlutterApi;

  /// Flutter Api for [GeolocationPermissionsCallback].
  late final GeolocationPermissionsCallbackFlutterApiImpl
      geolocationPermissionsCallbackFlutterApi;

  /// Flutter Api for [WebView].
  late final WebViewFlutterApiImpl webViewFlutterApi;

  /// Flutter Api for [PermissionRequest].
  late final PermissionRequestFlutterApiImpl permissionRequestFlutterApi;

  /// Ensures all the Flutter APIs have been setup to receive calls from native code.
  void ensureSetUp() {
    if (!_haveBeenSetUp) {
      JavaObjectFlutterApi.setup(javaObjectFlutterApi);
      DownloadListenerFlutterApi.setup(downloadListenerFlutterApi);
      WebViewClientFlutterApi.setup(webViewClientFlutterApi);
      WebChromeClientFlutterApi.setup(webChromeClientFlutterApi);
      JavaScriptChannelFlutterApi.setup(javaScriptChannelFlutterApi);
      FileChooserParamsFlutterApi.setup(fileChooserParamsFlutterApi);
      GeolocationPermissionsCallbackFlutterApi.setup(
          geolocationPermissionsCallbackFlutterApi);
      WebViewFlutterApi.setup(webViewFlutterApi);
      PermissionRequestFlutterApi.setup(permissionRequestFlutterApi);
      _haveBeenSetUp = true;
    }
  }
}

/// Handles methods calls to the native Java Object class.
class JavaObjectHostApiImpl extends JavaObjectHostApi {
  /// Constructs a [JavaObjectHostApiImpl].
  JavaObjectHostApiImpl({
    this.binaryMessenger,
    InstanceManager? instanceManager,
  })  : instanceManager = instanceManager ?? JavaObject.globalInstanceManager,
        super(binaryMessenger: binaryMessenger);

  /// Receives binary data across the Flutter platform barrier.
  ///
  /// If it is null, the default BinaryMessenger will be used which routes to
  /// the host platform.
  final BinaryMessenger? binaryMessenger;

  /// Maintains instances stored to communicate with native language objects.
  final InstanceManager instanceManager;
}

/// Handles callbacks methods for the native Java Object class.
class JavaObjectFlutterApiImpl implements JavaObjectFlutterApi {
  /// Constructs a [JavaObjectFlutterApiImpl].
  JavaObjectFlutterApiImpl({InstanceManager? instanceManager})
      : instanceManager = instanceManager ?? JavaObject.globalInstanceManager;

  /// Maintains instances stored to communicate with native language objects.
  final InstanceManager instanceManager;

  @override
  void dispose(int identifier) {
    instanceManager.remove(identifier);
  }
}

/// Host api implementation for [WebView].
class WebViewHostApiImpl extends WebViewHostApi {
  /// Constructs a [WebViewHostApiImpl].
  WebViewHostApiImpl({
    super.binaryMessenger,
    InstanceManager? instanceManager,
  }) : instanceManager = instanceManager ?? JavaObject.globalInstanceManager;

  /// Maintains instances stored to communicate with java objects.
  final InstanceManager instanceManager;

  /// Helper method to convert instances ids to objects.
  Future<void> createFromInstance(WebView instance) {
    return create(instanceManager.addDartCreatedInstance(instance));
  }

  /// Helper method to convert the instances ids to objects.
  Future<void> loadDataFromInstance(
    WebView instance,
    String data,
    String? mimeType,
    String? encoding,
  ) {
    return loadData(
      instanceManager.getIdentifier(instance)!,
      data,
      mimeType,
      encoding,
    );
  }

  /// Helper method to convert instances ids to objects.
  Future<void> loadDataWithBaseUrlFromInstance(
    WebView instance,
    String? baseUrl,
    String data,
    String? mimeType,
    String? encoding,
    String? historyUrl,
  ) {
    return loadDataWithBaseUrl(
      instanceManager.getIdentifier(instance)!,
      baseUrl,
      data,
      mimeType,
      encoding,
      historyUrl,
    );
  }

  /// Helper method to convert instances ids to objects.
  Future<void> loadUrlFromInstance(
    WebView instance,
    String url,
    Map<String, String> headers,
  ) {
    return loadUrl(instanceManager.getIdentifier(instance)!, url, headers);
  }

  /// Helper method to convert instances ids to objects.
  Future<void> postUrlFromInstance(
    WebView instance,
    String url,
    Uint8List data,
  ) {
    return postUrl(instanceManager.getIdentifier(instance)!, url, data);
  }

  /// Helper method to convert instances ids to objects.
  Future<String?> getUrlFromInstance(WebView instance) {
    return getUrl(instanceManager.getIdentifier(instance)!);
  }

  /// Helper method to convert instances ids to objects.
  Future<bool> canGoBackFromInstance(WebView instance) {
    return canGoBack(instanceManager.getIdentifier(instance)!);
  }

  /// Helper method to convert instances ids to objects.
  Future<bool> canGoForwardFromInstance(WebView instance) {
    return canGoForward(instanceManager.getIdentifier(instance)!);
  }

  /// Helper method to convert instances ids to objects.
  Future<void> goBackFromInstance(WebView instance) {
    return goBack(instanceManager.getIdentifier(instance)!);
  }

  /// Helper method to convert instances ids to objects.
  Future<void> goForwardFromInstance(WebView instance) {
    return goForward(instanceManager.getIdentifier(instance)!);
  }

  /// Helper method to convert instances ids to objects.
  Future<void> reloadFromInstance(WebView instance) {
    return reload(instanceManager.getIdentifier(instance)!);
  }

  /// Helper method to convert instances ids to objects.
  Future<void> clearCacheFromInstance(WebView instance, bool includeDiskFiles) {
    return clearCache(
      instanceManager.getIdentifier(instance)!,
      includeDiskFiles,
    );
  }

  /// Helper method to convert instances ids to objects.
  Future<String?> evaluateJavascriptFromInstance(
    WebView instance,
    String javascriptString,
  ) {
    return evaluateJavascript(
      instanceManager.getIdentifier(instance)!,
      javascriptString,
    );
  }

  /// Helper method to convert instances ids to objects.
  Future<String?> getTitleFromInstance(WebView instance) {
    return getTitle(instanceManager.getIdentifier(instance)!);
  }

  /// Helper method to convert instances ids to objects.
  Future<void> scrollToFromInstance(WebView instance, int x, int y) {
    return scrollTo(instanceManager.getIdentifier(instance)!, x, y);
  }

  /// Helper method to convert instances ids to objects.
  Future<void> scrollByFromInstance(WebView instance, int x, int y) {
    return scrollBy(instanceManager.getIdentifier(instance)!, x, y);
  }

  /// Helper method to convert instances ids to objects.
  Future<int> getScrollXFromInstance(WebView instance) {
    return getScrollX(instanceManager.getIdentifier(instance)!);
  }

  /// Helper method to convert instances ids to objects.
  Future<int> getScrollYFromInstance(WebView instance) {
    return getScrollY(instanceManager.getIdentifier(instance)!);
  }

  /// Helper method to convert instances ids to objects.
  Future<Offset> getScrollPositionFromInstance(WebView instance) async {
    final WebViewPoint position =
        await getScrollPosition(instanceManager.getIdentifier(instance)!);
    return Offset(position.x.toDouble(), position.y.toDouble());
  }

  /// Helper method to convert instances ids to objects.
  Future<void> setWebViewClientFromInstance(
    WebView instance,
    WebViewClient webViewClient,
  ) {
    return setWebViewClient(
      instanceManager.getIdentifier(instance)!,
      instanceManager.getIdentifier(webViewClient)!,
    );
  }

  /// Helper method to convert instances ids to objects.
  Future<void> addJavaScriptChannelFromInstance(
    WebView instance,
    JavaScriptChannel javaScriptChannel,
  ) {
    return addJavaScriptChannel(
      instanceManager.getIdentifier(instance)!,
      instanceManager.getIdentifier(javaScriptChannel)!,
    );
  }

  /// Helper method to convert instances ids to objects.
  Future<void> removeJavaScriptChannelFromInstance(
    WebView instance,
    JavaScriptChannel javaScriptChannel,
  ) {
    return removeJavaScriptChannel(
      instanceManager.getIdentifier(instance)!,
      instanceManager.getIdentifier(javaScriptChannel)!,
    );
  }

  /// Helper method to convert instances ids to objects.
  Future<void> setDownloadListenerFromInstance(
    WebView instance,
    DownloadListener? listener,
  ) {
    return setDownloadListener(
      instanceManager.getIdentifier(instance)!,
      listener != null ? instanceManager.getIdentifier(listener) : null,
    );
  }

  /// Helper method to convert instances ids to objects.
  Future<void> setWebChromeClientFromInstance(
    WebView instance,
    WebChromeClient? client,
  ) {
    return setWebChromeClient(
      instanceManager.getIdentifier(instance)!,
      client != null ? instanceManager.getIdentifier(client) : null,
    );
  }

  /// Helper method to convert instances ids to objects.
  Future<void> setBackgroundColorFromInstance(WebView instance, int color) {
    return setBackgroundColor(instanceManager.getIdentifier(instance)!, color);
  }
}

/// Flutter API implementation for [WebView].
///
/// This class may handle instantiating and adding Dart instances that are
/// attached to a native instance or receiving callback methods from an
/// overridden native class.
class WebViewFlutterApiImpl implements WebViewFlutterApi {
  /// Constructs a [WebViewFlutterApiImpl].
  WebViewFlutterApiImpl({
    this.binaryMessenger,
    InstanceManager? instanceManager,
  }) : instanceManager = instanceManager ?? JavaObject.globalInstanceManager;

  /// Receives binary data across the Flutter platform barrier.
  ///
  /// If it is null, the default BinaryMessenger will be used which routes to
  /// the host platform.
  final BinaryMessenger? binaryMessenger;

  /// Maintains instances stored to communicate with native language objects.
  final InstanceManager instanceManager;

  @override
  void create(int identifier) {
    instanceManager.addHostCreatedInstance(WebView.detached(), identifier);
  }
}

/// Host api implementation for [WebSettings].
class WebSettingsHostApiImpl extends WebSettingsHostApi {
  /// Constructs a [WebSettingsHostApiImpl].
  WebSettingsHostApiImpl({
    super.binaryMessenger,
    InstanceManager? instanceManager,
  }) : instanceManager = instanceManager ?? JavaObject.globalInstanceManager;

  /// Maintains instances stored to communicate with java objects.
  final InstanceManager instanceManager;

  /// Helper method to convert instances ids to objects.
  Future<void> createFromInstance(WebSettings instance, WebView webView) {
    return create(
      instanceManager.addDartCreatedInstance(instance),
      instanceManager.getIdentifier(webView)!,
    );
  }

  /// Helper method to convert instances ids to objects.
  Future<void> setDomStorageEnabledFromInstance(
    WebSettings instance,
    bool flag,
  ) {
    return setDomStorageEnabled(instanceManager.getIdentifier(instance)!, flag);
  }

  /// Helper method to convert instances ids to objects.
  Future<void> setJavaScriptCanOpenWindowsAutomaticallyFromInstance(
    WebSettings instance,
    bool flag,
  ) {
    return setJavaScriptCanOpenWindowsAutomatically(
      instanceManager.getIdentifier(instance)!,
      flag,
    );
  }

  /// Helper method to convert instances ids to objects.
  Future<void> setSupportMultipleWindowsFromInstance(
    WebSettings instance,
    bool support,
  ) {
    return setSupportMultipleWindows(
        instanceManager.getIdentifier(instance)!, support);
  }

  /// Helper method to convert instances ids to objects.
  Future<void> setJavaScriptEnabledFromInstance(
    WebSettings instance,
    bool flag,
  ) {
    return setJavaScriptEnabled(
      instanceManager.getIdentifier(instance)!,
      flag,
    );
  }

  /// Helper method to convert instances ids to objects.
  Future<void> setUserAgentStringFromInstance(
    WebSettings instance,
    String? userAgentString,
  ) {
    return setUserAgentString(
      instanceManager.getIdentifier(instance)!,
      userAgentString,
    );
  }

  /// Helper method to convert instances ids to objects.
  Future<void> setMediaPlaybackRequiresUserGestureFromInstance(
    WebSettings instance,
    bool require,
  ) {
    return setMediaPlaybackRequiresUserGesture(
      instanceManager.getIdentifier(instance)!,
      require,
    );
  }

  /// Helper method to convert instances ids to objects.
  Future<void> setSupportZoomFromInstance(
    WebSettings instance,
    bool support,
  ) {
    return setSupportZoom(instanceManager.getIdentifier(instance)!, support);
  }

  /// Helper method to convert instances ids to objects.
  Future<void> setSetTextZoomFromInstance(
    WebSettings instance,
    int textZoom,
  ) {
    return setTextZoom(instanceManager.getIdentifier(instance)!, textZoom);
  }

  /// Helper method to convert instances ids to objects.
  Future<void> setLoadWithOverviewModeFromInstance(
    WebSettings instance,
    bool overview,
  ) {
    return setLoadWithOverviewMode(
      instanceManager.getIdentifier(instance)!,
      overview,
    );
  }

  /// Helper method to convert instances ids to objects.
  Future<void> setUseWideViewPortFromInstance(
    WebSettings instance,
    bool use,
  ) {
    return setUseWideViewPort(instanceManager.getIdentifier(instance)!, use);
  }

  /// Helper method to convert instances ids to objects.
  Future<void> setDisplayZoomControlsFromInstance(
    WebSettings instance,
    bool enabled,
  ) {
    return setDisplayZoomControls(
      instanceManager.getIdentifier(instance)!,
      enabled,
    );
  }

  /// Helper method to convert instances ids to objects.
  Future<void> setBuiltInZoomControlsFromInstance(
    WebSettings instance,
    bool enabled,
  ) {
    return setBuiltInZoomControls(
      instanceManager.getIdentifier(instance)!,
      enabled,
    );
  }

  /// Helper method to convert instances ids to objects.
  Future<void> setAllowFileAccessFromInstance(
    WebSettings instance,
    bool enabled,
  ) {
    return setAllowFileAccess(
      instanceManager.getIdentifier(instance)!,
      enabled,
    );
  }
}

/// Host api implementation for [JavaScriptChannel].
class JavaScriptChannelHostApiImpl extends JavaScriptChannelHostApi {
  /// Constructs a [JavaScriptChannelHostApiImpl].
  JavaScriptChannelHostApiImpl({
    super.binaryMessenger,
    InstanceManager? instanceManager,
  }) : instanceManager = instanceManager ?? JavaObject.globalInstanceManager;

  /// Maintains instances stored to communicate with java objects.
  final InstanceManager instanceManager;

  /// Helper method to convert instances ids to objects.
  Future<void> createFromInstance(JavaScriptChannel instance) async {
    if (instanceManager.getIdentifier(instance) == null) {
      final int identifier = instanceManager.addDartCreatedInstance(instance);
      await create(
        identifier,
        instance.channelName,
      );
    }
  }
}

/// Flutter api implementation for [JavaScriptChannel].
class JavaScriptChannelFlutterApiImpl extends JavaScriptChannelFlutterApi {
  /// Constructs a [JavaScriptChannelFlutterApiImpl].
  JavaScriptChannelFlutterApiImpl({InstanceManager? instanceManager})
      : instanceManager = instanceManager ?? JavaObject.globalInstanceManager;

  /// Maintains instances stored to communicate with java objects.
  final InstanceManager instanceManager;

  @override
  void postMessage(int instanceId, String message) {
    final JavaScriptChannel? instance = instanceManager
        .getInstanceWithWeakReference(instanceId) as JavaScriptChannel?;
    assert(
      instance != null,
      'InstanceManager does not contain a JavaScriptChannel with instanceId: $instanceId',
    );
    instance!.postMessage(message);
  }
}

/// Host api implementation for [WebViewClient].
class WebViewClientHostApiImpl extends WebViewClientHostApi {
  /// Constructs a [WebViewClientHostApiImpl].
  WebViewClientHostApiImpl({
    super.binaryMessenger,
    InstanceManager? instanceManager,
  }) : instanceManager = instanceManager ?? JavaObject.globalInstanceManager;

  /// Maintains instances stored to communicate with java objects.
  final InstanceManager instanceManager;

  /// Helper method to convert instances ids to objects.
  Future<void> createFromInstance(WebViewClient instance) async {
    if (instanceManager.getIdentifier(instance) == null) {
      final int identifier = instanceManager.addDartCreatedInstance(instance);
      return create(identifier);
    }
  }

  /// Helper method to convert instances ids to objects.
  Future<void> setShouldOverrideUrlLoadingReturnValueFromInstance(
    WebViewClient instance,
    bool value,
  ) {
    return setSynchronousReturnValueForShouldOverrideUrlLoading(
      instanceManager.getIdentifier(instance)!,
      value,
    );
  }
}

/// Flutter api implementation for [WebViewClient].
class WebViewClientFlutterApiImpl extends WebViewClientFlutterApi {
  /// Constructs a [WebViewClientFlutterApiImpl].
  WebViewClientFlutterApiImpl({InstanceManager? instanceManager})
      : instanceManager = instanceManager ?? JavaObject.globalInstanceManager;

  /// Maintains instances stored to communicate with java objects.
  final InstanceManager instanceManager;

  @override
  void onPageFinished(int instanceId, int webViewInstanceId, String url) {
    final WebViewClient? instance = instanceManager
        .getInstanceWithWeakReference(instanceId) as WebViewClient?;
    final WebView? webViewInstance = instanceManager
        .getInstanceWithWeakReference(webViewInstanceId) as WebView?;
    assert(
      instance != null,
      'InstanceManager does not contain a WebViewClient with instanceId: $instanceId',
    );
    assert(
      webViewInstance != null,
      'InstanceManager does not contain a WebView with instanceId: $webViewInstanceId',
    );
    if (instance!.onPageFinished != null) {
      instance.onPageFinished!(webViewInstance!, url);
    }
  }

  @override
  void onPageStarted(int instanceId, int webViewInstanceId, String url) {
    final WebViewClient? instance = instanceManager
        .getInstanceWithWeakReference(instanceId) as WebViewClient?;
    final WebView? webViewInstance = instanceManager
        .getInstanceWithWeakReference(webViewInstanceId) as WebView?;
    assert(
      instance != null,
      'InstanceManager does not contain a WebViewClient with instanceId: $instanceId',
    );
    assert(
      webViewInstance != null,
      'InstanceManager does not contain a WebView with instanceId: $webViewInstanceId',
    );
    if (instance!.onPageStarted != null) {
      instance.onPageStarted!(webViewInstance!, url);
    }
  }

  @override
  void onReceivedError(
    int instanceId,
    int webViewInstanceId,
    int errorCode,
    String description,
    String failingUrl,
  ) {
    final WebViewClient? instance = instanceManager
        .getInstanceWithWeakReference(instanceId) as WebViewClient?;
    final WebView? webViewInstance = instanceManager
        .getInstanceWithWeakReference(webViewInstanceId) as WebView?;
    assert(
      instance != null,
      'InstanceManager does not contain a WebViewClient with instanceId: $instanceId',
    );
    assert(
      webViewInstance != null,
      'InstanceManager does not contain a WebView with instanceId: $webViewInstanceId',
    );
    // ignore: deprecated_member_use_from_same_package
    if (instance!.onReceivedError != null) {
      instance.onReceivedError!(
        webViewInstance!,
        errorCode,
        description,
        failingUrl,
      );
    }
  }

  @override
  void onReceivedRequestError(
    int instanceId,
    int webViewInstanceId,
    WebResourceRequestData request,
    WebResourceErrorData error,
  ) {
    final WebViewClient? instance = instanceManager
        .getInstanceWithWeakReference(instanceId) as WebViewClient?;
    final WebView? webViewInstance = instanceManager
        .getInstanceWithWeakReference(webViewInstanceId) as WebView?;
    assert(
      instance != null,
      'InstanceManager does not contain a WebViewClient with instanceId: $instanceId',
    );
    assert(
      webViewInstance != null,
      'InstanceManager does not contain a WebView with instanceId: $webViewInstanceId',
    );
    if (instance!.onReceivedRequestError != null) {
      instance.onReceivedRequestError!(
        webViewInstance!,
        _toWebResourceRequest(request),
        _toWebResourceError(error),
      );
    }
  }

  @override
  void requestLoading(
    int instanceId,
    int webViewInstanceId,
    WebResourceRequestData request,
  ) {
    final WebViewClient? instance = instanceManager
        .getInstanceWithWeakReference(instanceId) as WebViewClient?;
    final WebView? webViewInstance = instanceManager
        .getInstanceWithWeakReference(webViewInstanceId) as WebView?;
    assert(
      instance != null,
      'InstanceManager does not contain a WebViewClient with instanceId: $instanceId',
    );
    assert(
      webViewInstance != null,
      'InstanceManager does not contain a WebView with instanceId: $webViewInstanceId',
    );
    if (instance!.requestLoading != null) {
      instance.requestLoading!(
        webViewInstance!,
        _toWebResourceRequest(request),
      );
    }
  }

  @override
  void urlLoading(
    int instanceId,
    int webViewInstanceId,
    String url,
  ) {
    final WebViewClient? instance = instanceManager
        .getInstanceWithWeakReference(instanceId) as WebViewClient?;
    final WebView? webViewInstance = instanceManager
        .getInstanceWithWeakReference(webViewInstanceId) as WebView?;
    assert(
      instance != null,
      'InstanceManager does not contain a WebViewClient with instanceId: $instanceId',
    );
    assert(
      webViewInstance != null,
      'InstanceManager does not contain a WebView with instanceId: $webViewInstanceId',
    );
    if (instance!.urlLoading != null) {
      instance.urlLoading!(webViewInstance!, url);
    }
  }

  @override
  void doUpdateVisitedHistory(
    int instanceId,
    int webViewInstanceId,
    String url,
    bool isReload,
  ) {
    final WebViewClient? instance = instanceManager
        .getInstanceWithWeakReference(instanceId) as WebViewClient?;
    final WebView? webViewInstance = instanceManager
        .getInstanceWithWeakReference(webViewInstanceId) as WebView?;
    assert(
      instance != null,
      'InstanceManager does not contain an WebViewClient with instanceId: $instanceId',
    );
    assert(
      webViewInstance != null,
      'InstanceManager does not contain an WebView with instanceId: $webViewInstanceId',
    );
    if (instance!.doUpdateVisitedHistory != null) {
      instance.doUpdateVisitedHistory!(webViewInstance!, url, isReload);
    }
  }
}

/// Host api implementation for [DownloadListener].
class DownloadListenerHostApiImpl extends DownloadListenerHostApi {
  /// Constructs a [DownloadListenerHostApiImpl].
  DownloadListenerHostApiImpl({
    super.binaryMessenger,
    InstanceManager? instanceManager,
  }) : instanceManager = instanceManager ?? JavaObject.globalInstanceManager;

  /// Maintains instances stored to communicate with java objects.
  final InstanceManager instanceManager;

  /// Helper method to convert instances ids to objects.
  Future<void> createFromInstance(DownloadListener instance) async {
    if (instanceManager.getIdentifier(instance) == null) {
      final int identifier = instanceManager.addDartCreatedInstance(instance);
      return create(identifier);
    }
  }
}

/// Flutter api implementation for [DownloadListener].
class DownloadListenerFlutterApiImpl extends DownloadListenerFlutterApi {
  /// Constructs a [DownloadListenerFlutterApiImpl].
  DownloadListenerFlutterApiImpl({InstanceManager? instanceManager})
      : instanceManager = instanceManager ?? JavaObject.globalInstanceManager;

  /// Maintains instances stored to communicate with java objects.
  final InstanceManager instanceManager;

  @override
  void onDownloadStart(
    int instanceId,
    String url,
    String userAgent,
    String contentDisposition,
    String mimetype,
    int contentLength,
  ) {
    final DownloadListener? instance = instanceManager
        .getInstanceWithWeakReference(instanceId) as DownloadListener?;
    assert(
      instance != null,
      'InstanceManager does not contain a DownloadListener with instanceId: $instanceId',
    );
    instance!.onDownloadStart(
      url,
      userAgent,
      contentDisposition,
      mimetype,
      contentLength,
    );
  }
}

/// Host api implementation for [DownloadListener].
class WebChromeClientHostApiImpl extends WebChromeClientHostApi {
  /// Constructs a [WebChromeClientHostApiImpl].
  WebChromeClientHostApiImpl({
    super.binaryMessenger,
    InstanceManager? instanceManager,
  }) : instanceManager = instanceManager ?? JavaObject.globalInstanceManager;

  /// Maintains instances stored to communicate with java objects.
  final InstanceManager instanceManager;

  /// Helper method to convert instances ids to objects.
  Future<void> createFromInstance(WebChromeClient instance) async {
    if (instanceManager.getIdentifier(instance) == null) {
      final int identifier = instanceManager.addDartCreatedInstance(instance);
      return create(identifier);
    }
  }

  /// Helper method to convert instances ids to objects.
  Future<void> setSynchronousReturnValueForOnShowFileChooserFromInstance(
    WebChromeClient instance,
    bool value,
  ) {
    return setSynchronousReturnValueForOnShowFileChooser(
      instanceManager.getIdentifier(instance)!,
      value,
    );
  }
}

/// Flutter api implementation for [DownloadListener].
class WebChromeClientFlutterApiImpl extends WebChromeClientFlutterApi {
  /// Constructs a [DownloadListenerFlutterApiImpl].
  WebChromeClientFlutterApiImpl({InstanceManager? instanceManager})
      : instanceManager = instanceManager ?? JavaObject.globalInstanceManager;

  /// Maintains instances stored to communicate with java objects.
  final InstanceManager instanceManager;

  @override
  void onProgressChanged(int instanceId, int webViewInstanceId, int progress) {
    final WebChromeClient? instance = instanceManager
        .getInstanceWithWeakReference(instanceId) as WebChromeClient?;
    final WebView? webViewInstance = instanceManager
        .getInstanceWithWeakReference(webViewInstanceId) as WebView?;
    assert(
      instance != null,
      'InstanceManager does not contain a WebChromeClient with instanceId: $instanceId',
    );
    assert(
      webViewInstance != null,
      'InstanceManager does not contain a WebView with instanceId: $webViewInstanceId',
    );
    if (instance!.onProgressChanged != null) {
      instance.onProgressChanged!(webViewInstance!, progress);
    }
  }

  @override
  Future<List<String?>> onShowFileChooser(
    int instanceId,
    int webViewInstanceId,
    int paramsInstanceId,
  ) {
    final WebChromeClient instance =
        instanceManager.getInstanceWithWeakReference(instanceId)!;
    if (instance.onShowFileChooser != null) {
      return instance.onShowFileChooser!(
        instanceManager.getInstanceWithWeakReference(webViewInstanceId)!
            as WebView,
        instanceManager.getInstanceWithWeakReference(paramsInstanceId)!
            as FileChooserParams,
      );
    }

    return Future<List<String>>.value(const <String>[]);
  }

  @override
  void onGeolocationPermissionsShowPrompt(
      int instanceId, int paramsInstanceId, String origin) {
    final WebChromeClient instance =
        instanceManager.getInstanceWithWeakReference(instanceId)!;
    final GeolocationPermissionsCallback callback =
        instanceManager.getInstanceWithWeakReference(paramsInstanceId)!
            as GeolocationPermissionsCallback;
    final GeolocationPermissionsShowPrompt? onShowPrompt =
        instance.onGeolocationPermissionsShowPrompt;
    if (onShowPrompt != null) {
      onShowPrompt(origin, callback);
    }
  }

  @override
  void onGeolocationPermissionsHidePrompt(int identifier) {
    final WebChromeClient instance =
        instanceManager.getInstanceWithWeakReference(identifier)!;
    final GeolocationPermissionsHidePrompt? onHidePrompt =
        instance.onGeolocationPermissionsHidePrompt;
    if (onHidePrompt != null) {
      return onHidePrompt(instance);
    }
  }

  @override
  void onPermissionRequest(
    int instanceId,
    int requestInstanceId,
  ) {
    final WebChromeClient instance =
        instanceManager.getInstanceWithWeakReference(instanceId)!;
    if (instance.onPermissionRequest != null) {
      instance.onPermissionRequest!(
        instance,
        instanceManager.getInstanceWithWeakReference(requestInstanceId)!,
      );
    } else {
      // The method requires calling grant or deny if the Java method is
      // overridden, so this calls deny by default if `onPermissionRequest` is
      // null.
      final PermissionRequest request =
          instanceManager.getInstanceWithWeakReference(requestInstanceId)!;
      request.deny();
    }
  }
}

/// Host api implementation for [WebStorage].
class WebStorageHostApiImpl extends WebStorageHostApi {
  /// Constructs a [WebStorageHostApiImpl].
  WebStorageHostApiImpl({
    super.binaryMessenger,
    InstanceManager? instanceManager,
  }) : instanceManager = instanceManager ?? JavaObject.globalInstanceManager;

  /// Maintains instances stored to communicate with java objects.
  final InstanceManager instanceManager;

  /// Helper method to convert instances ids to objects.
  Future<void> createFromInstance(WebStorage instance) async {
    if (instanceManager.getIdentifier(instance) == null) {
      final int identifier = instanceManager.addDartCreatedInstance(instance);
      return create(identifier);
    }
  }

  /// Helper method to convert instances ids to objects.
  Future<void> deleteAllDataFromInstance(WebStorage instance) {
    return deleteAllData(instanceManager.getIdentifier(instance)!);
  }
}

/// Flutter api implementation for [FileChooserParams].
class FileChooserParamsFlutterApiImpl extends FileChooserParamsFlutterApi {
  /// Constructs a [FileChooserParamsFlutterApiImpl].
  FileChooserParamsFlutterApiImpl({
    this.binaryMessenger,
    InstanceManager? instanceManager,
  }) : instanceManager = instanceManager ?? JavaObject.globalInstanceManager;

  /// Receives binary data across the Flutter platform barrier.
  ///
  /// If it is null, the default BinaryMessenger will be used which routes to
  /// the host platform.
  final BinaryMessenger? binaryMessenger;

  /// Maintains instances stored to communicate with java objects.
  final InstanceManager instanceManager;

  @override
  void create(
    int instanceId,
    bool isCaptureEnabled,
    List<String?> acceptTypes,
    FileChooserModeEnumData mode,
    String? filenameHint,
  ) {
    instanceManager.addHostCreatedInstance(
      FileChooserParams.detached(
        isCaptureEnabled: isCaptureEnabled,
        acceptTypes: acceptTypes.cast(),
        mode: mode.value,
        filenameHint: filenameHint,
        binaryMessenger: binaryMessenger,
        instanceManager: instanceManager,
      ),
      instanceId,
    );
  }
}

/// Host api implementation for [GeolocationPermissionsCallback].
class GeolocationPermissionsCallbackHostApiImpl
    extends GeolocationPermissionsCallbackHostApi {
  /// Constructs a [GeolocationPermissionsCallbackHostApiImpl].
  GeolocationPermissionsCallbackHostApiImpl({
    this.binaryMessenger,
    InstanceManager? instanceManager,
  })  : instanceManager = instanceManager ?? JavaObject.globalInstanceManager,
        super(binaryMessenger: binaryMessenger);

  /// Sends binary data across the Flutter platform barrier.
  ///
  /// If it is null, the default BinaryMessenger will be used which routes to
  /// the host platform.
  final BinaryMessenger? binaryMessenger;

  /// Maintains instances stored to communicate with java objects.
  final InstanceManager instanceManager;

  /// Helper method to convert instances ids to objects.
  Future<void> invokeFromInstances(
    GeolocationPermissionsCallback instance,
    String origin,
    bool allow,
    bool retain,
  ) {
    return invoke(
      instanceManager.getIdentifier(instance)!,
      origin,
      allow,
      retain,
    );
  }
}

/// Flutter API implementation for [GeolocationPermissionsCallback].
///
/// This class may handle instantiating and adding Dart instances that are
/// attached to a native instance or receiving callback methods from an
/// overridden native class.
class GeolocationPermissionsCallbackFlutterApiImpl
    implements GeolocationPermissionsCallbackFlutterApi {
  /// Constructs a [GeolocationPermissionsCallbackFlutterApiImpl].
  GeolocationPermissionsCallbackFlutterApiImpl({
    this.binaryMessenger,
    InstanceManager? instanceManager,
  }) : instanceManager = instanceManager ?? JavaObject.globalInstanceManager;

  /// Receives binary data across the Flutter platform barrier.
  ///
  /// If it is null, the default BinaryMessenger will be used which routes to
  /// the host platform.
  final BinaryMessenger? binaryMessenger;

  /// Maintains instances stored to communicate with native language objects.
  final InstanceManager instanceManager;

  @override
  void create(int instanceId) {
    instanceManager.addHostCreatedInstance(
      GeolocationPermissionsCallback.detached(
        binaryMessenger: binaryMessenger,
        instanceManager: instanceManager,
      ),
      instanceId,
    );
  }
}

/// Host api implementation for [PermissionRequest].
class PermissionRequestHostApiImpl extends PermissionRequestHostApi {
  /// Constructs a [PermissionRequestHostApiImpl].
  PermissionRequestHostApiImpl({
    this.binaryMessenger,
    InstanceManager? instanceManager,
  })  : instanceManager = instanceManager ?? JavaObject.globalInstanceManager,
        super(binaryMessenger: binaryMessenger);

  /// Sends binary data across the Flutter platform barrier.
  ///
  /// If it is null, the default BinaryMessenger will be used which routes to
  /// the host platform.
  final BinaryMessenger? binaryMessenger;

  /// Maintains instances stored to communicate with native language objects.
  final InstanceManager instanceManager;

  /// Helper method to convert instance ids to objects.
  Future<void> grantFromInstances(
    PermissionRequest instance,
    List<String> resources,
  ) {
    return grant(instanceManager.getIdentifier(instance)!, resources);
  }

  /// Helper method to convert instance ids to objects.
  Future<void> denyFromInstances(PermissionRequest instance) {
    return deny(instanceManager.getIdentifier(instance)!);
  }
}

/// Flutter API implementation for [PermissionRequest].
///
/// This class may handle instantiating and adding Dart instances that are
/// attached to a native instance or receiving callback methods from an
/// overridden native class.
class PermissionRequestFlutterApiImpl implements PermissionRequestFlutterApi {
  /// Constructs a [PermissionRequestFlutterApiImpl].
  PermissionRequestFlutterApiImpl({
    this.binaryMessenger,
    InstanceManager? instanceManager,
  }) : instanceManager = instanceManager ?? JavaObject.globalInstanceManager;

  /// Receives binary data across the Flutter platform barrier.
  ///
  /// If it is null, the default BinaryMessenger will be used which routes to
  /// the host platform.
  final BinaryMessenger? binaryMessenger;

  /// Maintains instances stored to communicate with native language objects.
  final InstanceManager instanceManager;

  @override
  void create(
    int identifier,
    List<String?> resources,
  ) {
    instanceManager.addHostCreatedInstance(
      PermissionRequest.detached(
        resources: resources.cast<String>(),
        binaryMessenger: binaryMessenger,
        instanceManager: instanceManager,
      ),
      identifier,
    );
  }
}

/// Host api implementation for [CookieManager].
class CookieManagerHostApiImpl extends CookieManagerHostApi {
  /// Constructs a [CookieManagerHostApiImpl].
  CookieManagerHostApiImpl({
    this.binaryMessenger,
    InstanceManager? instanceManager,
  })  : instanceManager = instanceManager ?? JavaObject.globalInstanceManager,
        super(binaryMessenger: binaryMessenger);

  /// Sends binary data across the Flutter platform barrier.
  ///
  /// If it is null, the default BinaryMessenger will be used which routes to
  /// the host platform.
  final BinaryMessenger? binaryMessenger;

  /// Maintains instances stored to communicate with native language objects.
  final InstanceManager instanceManager;

  /// Helper method to convert instance ids to objects.
  CookieManager attachInstanceFromInstances(CookieManager instance) {
    attachInstance(instanceManager.addDartCreatedInstance(instance));
    return instance;
  }

  /// Helper method to convert instance ids to objects.
  Future<void> setCookieFromInstances(
    CookieManager instance,
    String url,
    String value,
  ) {
    return setCookie(
      instanceManager.getIdentifier(instance)!,
      url,
      value,
    );
  }

  /// Helper method to convert instance ids to objects.
  Future<bool> removeAllCookiesFromInstances(CookieManager instance) {
    return removeAllCookies(instanceManager.getIdentifier(instance)!);
  }

  /// Helper method to convert instance ids to objects.
  Future<void> setAcceptThirdPartyCookiesFromInstances(
    CookieManager instance,
    WebView webView,
    bool accept,
  ) {
    return setAcceptThirdPartyCookies(
      instanceManager.getIdentifier(instance)!,
      instanceManager.getIdentifier(webView)!,
      accept,
    );
  }
}
