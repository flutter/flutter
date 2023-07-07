// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'foundation/foundation.dart';
import 'web_kit_webview_widget.dart';

/// Builds an iOS webview.
///
/// This is used as the default implementation for [WebView.platform] on iOS. It uses
/// a [UiKitView] to embed the webview in the widget hierarchy, and uses a method channel to
/// communicate with the platform code.
class CupertinoWebView implements WebViewPlatform {
  @override
  Widget build({
    required BuildContext context,
    required CreationParams creationParams,
    required WebViewPlatformCallbacksHandler webViewPlatformCallbacksHandler,
    required JavascriptChannelRegistry javascriptChannelRegistry,
    WebViewPlatformCreatedCallback? onWebViewPlatformCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  }) {
    return WebKitWebViewWidget(
      creationParams: creationParams,
      callbacksHandler: webViewPlatformCallbacksHandler,
      javascriptChannelRegistry: javascriptChannelRegistry,
      onBuildWidget: (WebKitWebViewPlatformController controller) {
        return UiKitView(
          viewType: 'plugins.flutter.io/webview',
          onPlatformViewCreated: (int id) {
            if (onWebViewPlatformCreated != null) {
              onWebViewPlatformCreated(controller);
            }
          },
          gestureRecognizers: gestureRecognizers,
          creationParams:
              NSObject.globalInstanceManager.getIdentifier(controller.webView),
          creationParamsCodec: const StandardMessageCodec(),
        );
      },
    );
  }

  @override
  Future<bool> clearCookies() {
    if (WebViewCookieManagerPlatform.instance == null) {
      throw Exception(
          'Could not clear cookies as no implementation for WebViewCookieManagerPlatform has been registered.');
    }
    return WebViewCookieManagerPlatform.instance!.clearCookies();
  }
}
