// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
// ignore: implementation_imports
import 'package:webview_flutter_platform_interface/src/webview_flutter_platform_interface_legacy.dart';

import '../android_webview.dart' as android_webview;

/// Handles all cookie operations for the current platform.
class WebViewAndroidCookieManager extends WebViewCookieManagerPlatform {
  /// Constructs a [WebViewAndroidCookieManager].
  WebViewAndroidCookieManager({
    @visibleForTesting android_webview.CookieManager? cookieManager,
  }) : _cookieManager = cookieManager ?? android_webview.CookieManager.instance;

  final android_webview.CookieManager _cookieManager;

  @override
  Future<bool> clearCookies() => _cookieManager.removeAllCookies();

  @override
  Future<void> setCookie(WebViewCookie cookie) {
    if (!_isValidPath(cookie.path)) {
      throw ArgumentError(
          'The path property for the provided cookie was not given a legal value.');
    }
    return _cookieManager.setCookie(
      cookie.domain,
      '${Uri.encodeComponent(cookie.name)}=${Uri.encodeComponent(cookie.value)}; path=${cookie.path}',
    );
  }

  bool _isValidPath(String path) {
    // Permitted ranges based on RFC6265bis: https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-rfc6265bis-02#section-4.1.1
    for (final int char in path.codeUnits) {
      if ((char < 0x20 || char > 0x3A) && (char < 0x3C || char > 0x7E)) {
        return false;
      }
    }
    return true;
  }
}
