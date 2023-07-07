// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
// ignore: implementation_imports
import 'package:webview_flutter_platform_interface/src/webview_flutter_platform_interface_legacy.dart';
import 'http_request_factory.dart';
import 'shims/dart_ui.dart' as ui;

/// Builds an iframe based WebView.
///
/// This is used as the default implementation for [WebView.platform] on web.
class WebWebViewPlatform implements WebViewPlatform {
  /// Constructs a new instance of [WebWebViewPlatform].
  WebWebViewPlatform() {
    ui.platformViewRegistry.registerViewFactory(
        'webview-iframe',
        (int viewId) => IFrameElement()
          ..id = 'webview-$viewId'
          ..width = '100%'
          ..height = '100%'
          ..style.border = 'none');
  }

  @override
  Widget build({
    required BuildContext context,
    required CreationParams creationParams,
    required WebViewPlatformCallbacksHandler webViewPlatformCallbacksHandler,
    required JavascriptChannelRegistry? javascriptChannelRegistry,
    WebViewPlatformCreatedCallback? onWebViewPlatformCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  }) {
    return HtmlElementView(
      viewType: 'webview-iframe',
      onPlatformViewCreated: (int viewId) {
        if (onWebViewPlatformCreated == null) {
          return;
        }
        final IFrameElement element =
            document.getElementById('webview-$viewId')! as IFrameElement;
        if (creationParams.initialUrl != null) {
          // ignore: unsafe_html
          element.src = creationParams.initialUrl;
        }
        onWebViewPlatformCreated(WebWebViewPlatformController(
          element,
        ));
      },
    );
  }

  @override
  Future<bool> clearCookies() async => false;

  /// Gets called when the plugin is registered.
  static void registerWith(Registrar registrar) {}
}

/// Implementation of [WebViewPlatformController] for web.
class WebWebViewPlatformController implements WebViewPlatformController {
  /// Constructs a [WebWebViewPlatformController].
  WebWebViewPlatformController(this._element);

  final IFrameElement _element;
  HttpRequestFactory _httpRequestFactory = const HttpRequestFactory();

  /// Setter for setting the HttpRequestFactory, for testing purposes.
  @visibleForTesting
  // ignore: avoid_setters_without_getters
  set httpRequestFactory(HttpRequestFactory factory) {
    _httpRequestFactory = factory;
  }

  @override
  Future<void> addJavascriptChannels(Set<String> javascriptChannelNames) {
    throw UnimplementedError();
  }

  @override
  Future<bool> canGoBack() {
    throw UnimplementedError();
  }

  @override
  Future<bool> canGoForward() {
    throw UnimplementedError();
  }

  @override
  Future<void> clearCache() {
    throw UnimplementedError();
  }

  @override
  Future<String?> currentUrl() {
    throw UnimplementedError();
  }

  @override
  Future<String> evaluateJavascript(String javascript) {
    throw UnimplementedError();
  }

  @override
  Future<int> getScrollX() {
    throw UnimplementedError();
  }

  @override
  Future<int> getScrollY() {
    throw UnimplementedError();
  }

  @override
  Future<String?> getTitle() {
    throw UnimplementedError();
  }

  @override
  Future<void> goBack() {
    throw UnimplementedError();
  }

  @override
  Future<void> goForward() {
    throw UnimplementedError();
  }

  @override
  Future<void> loadUrl(String url, Map<String, String>? headers) async {
    // ignore: unsafe_html
    _element.src = url;
  }

  @override
  Future<void> reload() {
    throw UnimplementedError();
  }

  @override
  Future<void> removeJavascriptChannels(Set<String> javascriptChannelNames) {
    throw UnimplementedError();
  }

  @override
  Future<void> runJavascript(String javascript) {
    throw UnimplementedError();
  }

  @override
  Future<String> runJavascriptReturningResult(String javascript) {
    throw UnimplementedError();
  }

  @override
  Future<void> scrollBy(int x, int y) {
    throw UnimplementedError();
  }

  @override
  Future<void> scrollTo(int x, int y) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateSettings(WebSettings setting) {
    throw UnimplementedError();
  }

  @override
  Future<void> loadFile(String absoluteFilePath) {
    throw UnimplementedError();
  }

  @override
  Future<void> loadHtmlString(
    String html, {
    String? baseUrl,
  }) async {
    // ignore: unsafe_html
    _element.src = Uri.dataFromString(
      html,
      mimeType: 'text/html',
      encoding: utf8,
    ).toString();
  }

  @override
  Future<void> loadRequest(WebViewRequest request) async {
    if (!request.uri.hasScheme) {
      throw ArgumentError('WebViewRequest#uri is required to have a scheme.');
    }
    final HttpRequest httpReq = await _httpRequestFactory.request(
        request.uri.toString(),
        method: request.method.serialize(),
        requestHeaders: request.headers,
        sendData: request.body);
    final String contentType =
        httpReq.getResponseHeader('content-type') ?? 'text/html';
    // ignore: unsafe_html
    _element.src = Uri.dataFromString(
      httpReq.responseText ?? '',
      mimeType: contentType,
      encoding: utf8,
    ).toString();
  }

  @override
  Future<void> loadFlutterAsset(String key) {
    throw UnimplementedError();
  }
}
