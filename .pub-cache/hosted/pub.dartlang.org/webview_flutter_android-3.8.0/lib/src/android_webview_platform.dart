// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'android_webview_controller.dart';
import 'android_webview_cookie_manager.dart';

/// Implementation of [WebViewPlatform] using the WebKit API.
class AndroidWebViewPlatform extends WebViewPlatform {
  /// Registers this class as the default instance of [WebViewPlatform].
  static void registerWith() {
    WebViewPlatform.instance = AndroidWebViewPlatform();
  }

  @override
  AndroidWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return AndroidWebViewController(params);
  }

  @override
  AndroidNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return AndroidNavigationDelegate(params);
  }

  @override
  AndroidWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return AndroidWebViewWidget(params);
  }

  @override
  AndroidWebViewCookieManager createPlatformCookieManager(
    PlatformWebViewCookieManagerCreationParams params,
  ) {
    return AndroidWebViewCookieManager(params);
  }
}
