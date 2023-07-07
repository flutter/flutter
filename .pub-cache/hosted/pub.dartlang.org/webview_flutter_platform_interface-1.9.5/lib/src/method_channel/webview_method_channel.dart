// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';

import '../platform_interface/platform_interface.dart';
import '../types/types.dart';

/// A [WebViewPlatformController] that uses a method channel to control the webview.
class MethodChannelWebViewPlatform implements WebViewPlatformController {
  /// Constructs an instance that will listen for webviews broadcasting to the
  /// given [id], using the given [WebViewPlatformCallbacksHandler].
  MethodChannelWebViewPlatform(
    int id,
    this._platformCallbacksHandler,
    this._javascriptChannelRegistry,
  )   : assert(_platformCallbacksHandler != null),
        _channel = MethodChannel('plugins.flutter.io/webview_$id') {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  final JavascriptChannelRegistry _javascriptChannelRegistry;

  final WebViewPlatformCallbacksHandler _platformCallbacksHandler;

  final MethodChannel _channel;

  static const MethodChannel _cookieManagerChannel =
      MethodChannel('plugins.flutter.io/cookie_manager');

  Future<bool?> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'javascriptChannelMessage':
        final String channel = call.arguments['channel']! as String;
        final String message = call.arguments['message']! as String;
        _javascriptChannelRegistry.onJavascriptChannelMessage(channel, message);
        return true;
      case 'navigationRequest':
        return await _platformCallbacksHandler.onNavigationRequest(
          url: call.arguments['url']! as String,
          isForMainFrame: call.arguments['isForMainFrame']! as bool,
        );
      case 'onPageFinished':
        _platformCallbacksHandler
            .onPageFinished(call.arguments['url']! as String);
        return null;
      case 'onProgress':
        _platformCallbacksHandler.onProgress(call.arguments['progress'] as int);
        return null;
      case 'onPageStarted':
        _platformCallbacksHandler
            .onPageStarted(call.arguments['url']! as String);
        return null;
      case 'onWebResourceError':
        _platformCallbacksHandler.onWebResourceError(
          WebResourceError(
            errorCode: call.arguments['errorCode']! as int,
            description: call.arguments['description']! as String,
            // iOS doesn't support `failingUrl`.
            failingUrl: call.arguments['failingUrl'] as String?,
            domain: call.arguments['domain'] as String?,
            errorType: call.arguments['errorType'] == null
                ? null
                : WebResourceErrorType.values.firstWhere(
                    (WebResourceErrorType type) {
                      return type.toString() ==
                          '$WebResourceErrorType.${call.arguments['errorType']}';
                    },
                  ),
          ),
        );
        return null;
    }

    throw MissingPluginException(
      '${call.method} was invoked but has no handler',
    );
  }

  @override
  Future<void> loadFile(String absoluteFilePath) async {
    assert(absoluteFilePath != null);

    try {
      return await _channel.invokeMethod<void>('loadFile', absoluteFilePath);
    } on PlatformException catch (ex) {
      if (ex.code == 'loadFile_failed') {
        throw ArgumentError(ex.message);
      }

      rethrow;
    }
  }

  @override
  Future<void> loadFlutterAsset(String key) async {
    assert(key.isNotEmpty);

    try {
      return await _channel.invokeMethod<void>('loadFlutterAsset', key);
    } on PlatformException catch (ex) {
      if (ex.code == 'loadFlutterAsset_invalidKey') {
        throw ArgumentError(ex.message);
      }

      rethrow;
    }
  }

  @override
  Future<void> loadHtmlString(
    String html, {
    String? baseUrl,
  }) async {
    assert(html != null);
    return _channel.invokeMethod<void>('loadHtmlString', <String, dynamic>{
      'html': html,
      'baseUrl': baseUrl,
    });
  }

  @override
  Future<void> loadUrl(
    String url,
    Map<String, String>? headers,
  ) async {
    assert(url != null);
    return _channel.invokeMethod<void>('loadUrl', <String, dynamic>{
      'url': url,
      'headers': headers,
    });
  }

  @override
  Future<void> loadRequest(WebViewRequest request) async {
    assert(request != null);
    return _channel.invokeMethod<void>('loadRequest', <String, dynamic>{
      'request': request.toJson(),
    });
  }

  @override
  Future<String?> currentUrl() => _channel.invokeMethod<String>('currentUrl');

  @override
  Future<bool> canGoBack() =>
      _channel.invokeMethod<bool>('canGoBack').then((bool? result) => result!);

  @override
  Future<bool> canGoForward() => _channel
      .invokeMethod<bool>('canGoForward')
      .then((bool? result) => result!);

  @override
  Future<void> goBack() => _channel.invokeMethod<void>('goBack');

  @override
  Future<void> goForward() => _channel.invokeMethod<void>('goForward');

  @override
  Future<void> reload() => _channel.invokeMethod<void>('reload');

  @override
  Future<void> clearCache() => _channel.invokeMethod<void>('clearCache');

  @override
  Future<void> updateSettings(WebSettings settings) async {
    final Map<String, dynamic> updatesMap = _webSettingsToMap(settings);
    if (updatesMap.isNotEmpty) {
      await _channel.invokeMethod<void>('updateSettings', updatesMap);
    }
  }

  @override
  Future<String> evaluateJavascript(String javascript) {
    return _channel
        .invokeMethod<String>('evaluateJavascript', javascript)
        .then((String? result) => result!);
  }

  @override
  Future<void> runJavascript(String javascript) async {
    await _channel.invokeMethod<String>('runJavascript', javascript);
  }

  @override
  Future<String> runJavascriptReturningResult(String javascript) {
    return _channel
        .invokeMethod<String>('runJavascriptReturningResult', javascript)
        .then((String? result) => result!);
  }

  @override
  Future<void> addJavascriptChannels(Set<String> javascriptChannelNames) {
    return _channel.invokeMethod<void>(
        'addJavascriptChannels', javascriptChannelNames.toList());
  }

  @override
  Future<void> removeJavascriptChannels(Set<String> javascriptChannelNames) {
    return _channel.invokeMethod<void>(
        'removeJavascriptChannels', javascriptChannelNames.toList());
  }

  @override
  Future<String?> getTitle() => _channel.invokeMethod<String>('getTitle');

  @override
  Future<void> scrollTo(int x, int y) {
    return _channel.invokeMethod<void>('scrollTo', <String, int>{
      'x': x,
      'y': y,
    });
  }

  @override
  Future<void> scrollBy(int x, int y) {
    return _channel.invokeMethod<void>('scrollBy', <String, int>{
      'x': x,
      'y': y,
    });
  }

  @override
  Future<int> getScrollX() =>
      _channel.invokeMethod<int>('getScrollX').then((int? result) => result!);

  @override
  Future<int> getScrollY() =>
      _channel.invokeMethod<int>('getScrollY').then((int? result) => result!);

  /// Method channel implementation for [WebViewPlatform.clearCookies].
  static Future<bool> clearCookies() {
    return _cookieManagerChannel
        .invokeMethod<bool>('clearCookies')
        .then<bool>((dynamic result) => result! as bool);
  }

  /// Method channel implementation for [WebViewPlatform.setCookie].
  static Future<void> setCookie(WebViewCookie cookie) {
    return _cookieManagerChannel.invokeMethod<void>(
        'setCookie', cookie.toJson());
  }

  static Map<String, dynamic> _webSettingsToMap(WebSettings? settings) {
    final Map<String, dynamic> map = <String, dynamic>{};
    void addIfNonNull(String key, dynamic value) {
      if (value == null) {
        return;
      }
      map[key] = value;
    }

    void addSettingIfPresent<T>(String key, WebSetting<T> setting) {
      if (!setting.isPresent) {
        return;
      }
      map[key] = setting.value;
    }

    addIfNonNull('jsMode', settings!.javascriptMode?.index);
    addIfNonNull('hasNavigationDelegate', settings.hasNavigationDelegate);
    addIfNonNull('hasProgressTracking', settings.hasProgressTracking);
    addIfNonNull('debuggingEnabled', settings.debuggingEnabled);
    addIfNonNull('gestureNavigationEnabled', settings.gestureNavigationEnabled);
    addIfNonNull(
        'allowsInlineMediaPlayback', settings.allowsInlineMediaPlayback);
    addSettingIfPresent('userAgent', settings.userAgent);
    addIfNonNull('zoomEnabled', settings.zoomEnabled);
    return map;
  }

  /// Converts a [CreationParams] object to a map as expected by `platform_views` channel.
  ///
  /// This is used for the `creationParams` argument of the platform views created by
  /// [AndroidWebViewBuilder] and [CupertinoWebViewBuilder].
  static Map<String, dynamic> creationParamsToMap(
    CreationParams creationParams, {
    bool usesHybridComposition = false,
  }) {
    return <String, dynamic>{
      'initialUrl': creationParams.initialUrl,
      'settings': _webSettingsToMap(creationParams.webSettings),
      'javascriptChannelNames': creationParams.javascriptChannelNames.toList(),
      'userAgent': creationParams.userAgent,
      'autoMediaPlaybackPolicy': creationParams.autoMediaPlaybackPolicy.index,
      'usesHybridComposition': usesHybridComposition,
      'backgroundColor': creationParams.backgroundColor?.value,
      'cookies': creationParams.cookies
          .map((WebViewCookie cookie) => cookie.toJson())
          .toList()
    };
  }
}
