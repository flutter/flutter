// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'webkit_webview_controller.dart';
import 'webkit_webview_cookie_manager.dart';

/// Implementation of [WebViewPlatform] using the WebKit API.
class WebKitWebViewPlatform extends WebViewPlatform {
  /// Registers this class as the default instance of [WebViewPlatform].
  static void registerWith() {
    WebViewPlatform.instance = WebKitWebViewPlatform();
  }

  @override
  WebKitWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return WebKitWebViewController(params);
  }

  @override
  WebKitNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return WebKitNavigationDelegate(params);
  }

  @override
  WebKitWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return WebKitWebViewWidget(params);
  }

  @override
  WebKitWebViewCookieManager createPlatformCookieManager(
    PlatformWebViewCookieManagerCreationParams params,
  ) {
    return WebKitWebViewCookieManager(params);
  }
}
