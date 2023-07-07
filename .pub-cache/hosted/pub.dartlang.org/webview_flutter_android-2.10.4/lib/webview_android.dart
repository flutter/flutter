// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'src/android_webview.dart';
import 'webview_android_widget.dart';

/// Builds an Android webview.
///
/// This is used as the default implementation for [WebView.platform] on Android. It uses
/// an [AndroidView] to embed the webview in the widget hierarchy, and uses a method channel to
/// communicate with the platform code.
class AndroidWebView implements WebViewPlatform {
  @override
  Widget build({
    required BuildContext context,
    required CreationParams creationParams,
    required WebViewPlatformCallbacksHandler webViewPlatformCallbacksHandler,
    required JavascriptChannelRegistry javascriptChannelRegistry,
    WebViewPlatformCreatedCallback? onWebViewPlatformCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  }) {
    return WebViewAndroidWidget(
      useHybridComposition: false,
      creationParams: creationParams,
      callbacksHandler: webViewPlatformCallbacksHandler,
      javascriptChannelRegistry: javascriptChannelRegistry,
      onBuildWidget: (WebViewAndroidPlatformController controller) {
        return GestureDetector(
          // We prevent text selection by intercepting the long press event.
          // This is a temporary stop gap due to issues with text selection on Android:
          // https://github.com/flutter/flutter/issues/24585 - the text selection
          // dialog is not responding to touch events.
          // https://github.com/flutter/flutter/issues/24584 - the text selection
          // handles are not showing.
          // TODO(amirh): remove this when the issues above are fixed.
          onLongPress: () {},
          excludeFromSemantics: true,
          child: AndroidView(
            viewType: 'plugins.flutter.io/webview',
            onPlatformViewCreated: (int id) {
              if (onWebViewPlatformCreated != null) {
                onWebViewPlatformCreated(controller);
              }
            },
            gestureRecognizers: gestureRecognizers,
            layoutDirection:
                Directionality.maybeOf(context) ?? TextDirection.rtl,
            creationParams: JavaObject.globalInstanceManager
                .getIdentifier(controller.webView),
            creationParamsCodec: const StandardMessageCodec(),
          ),
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
