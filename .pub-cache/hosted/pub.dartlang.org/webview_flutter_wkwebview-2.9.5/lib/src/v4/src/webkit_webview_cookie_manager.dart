// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:webview_flutter_platform_interface/v4/webview_flutter_platform_interface.dart';

import '../../foundation/foundation.dart';
import '../../web_kit/web_kit.dart';
import 'webkit_proxy.dart';

/// Object specifying creation parameters for a [WebKitWebViewCookieManager].
class WebKitWebViewCookieManagerCreationParams
    extends PlatformWebViewCookieManagerCreationParams {
  /// Constructs a [WebKitWebViewCookieManagerCreationParams].
  WebKitWebViewCookieManagerCreationParams({
    WebKitProxy? webKitProxy,
  }) : webKitProxy = webKitProxy ?? const WebKitProxy();

  /// Constructs a [WebKitWebViewCookieManagerCreationParams] using a
  /// [PlatformWebViewCookieManagerCreationParams].
  WebKitWebViewCookieManagerCreationParams.fromPlatformWebViewCookieManagerCreationParams(
    // Recommended placeholder to prevent being broken by platform interface.
    // ignore: avoid_unused_constructor_parameters
    PlatformWebViewCookieManagerCreationParams params, {
    @visibleForTesting WebKitProxy? webKitProxy,
  }) : this(webKitProxy: webKitProxy);

  /// Handles constructing objects and calling static methods for the WebKit
  /// native library.
  @visibleForTesting
  final WebKitProxy webKitProxy;

  /// Manages stored data for [WKWebView]s.
  late final WKWebsiteDataStore _websiteDataStore =
      webKitProxy.defaultWebsiteDataStore();
}

/// An implementation of [PlatformWebViewCookieManager] with the WebKit api.
class WebKitWebViewCookieManager extends PlatformWebViewCookieManager {
  /// Constructs a [WebKitWebViewCookieManager].
  WebKitWebViewCookieManager(PlatformWebViewCookieManagerCreationParams params)
      : super.implementation(
          params is WebKitWebViewCookieManagerCreationParams
              ? params
              : WebKitWebViewCookieManagerCreationParams
                  .fromPlatformWebViewCookieManagerCreationParams(params),
        );

  WebKitWebViewCookieManagerCreationParams get _webkitParams =>
      params as WebKitWebViewCookieManagerCreationParams;

  @override
  Future<bool> clearCookies() {
    return _webkitParams._websiteDataStore.removeDataOfTypes(
      <WKWebsiteDataType>{WKWebsiteDataType.cookies},
      DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  Future<void> setCookie(WebViewCookie cookie) {
    if (!_isValidPath(cookie.path)) {
      throw ArgumentError(
        'The path property for the provided cookie was not given a legal value.',
      );
    }

    return _webkitParams._websiteDataStore.httpCookieStore.setCookie(
      NSHttpCookie.withProperties(
        <NSHttpCookiePropertyKey, Object>{
          NSHttpCookiePropertyKey.name: cookie.name,
          NSHttpCookiePropertyKey.value: cookie.value,
          NSHttpCookiePropertyKey.domain: cookie.domain,
          NSHttpCookiePropertyKey.path: cookie.path,
        },
      ),
    );
  }

  bool _isValidPath(String path) {
    // Permitted ranges based on RFC6265bis: https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-rfc6265bis-02#section-4.1.1
    return !path.codeUnits.any(
      (int char) {
        return (char < 0x20 || char > 0x3A) && (char < 0x3C || char > 0x7E);
      },
    );
  }
}
