// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'web_webview_controller.dart';

/// An implementation of [WebViewPlatform] using Flutter for Web API.
class WebWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return WebWebViewController(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return WebWebViewWidget(params);
  }

  /// Gets called when the plugin is registered.
  static void registerWith(Registrar registrar) {
    WebViewPlatform.instance = WebWebViewPlatform();
  }
}
