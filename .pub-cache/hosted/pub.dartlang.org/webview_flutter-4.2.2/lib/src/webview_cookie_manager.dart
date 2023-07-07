// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

/// Manages cookies pertaining to all WebViews.
///
/// ## Platform-Specific Features
/// This class contains an underlying implementation provided by the current
/// platform. Once a platform implementation is imported, the examples below
/// can be followed to use features provided by a platform's implementation.
///
/// {@macro webview_flutter.WebViewCookieManager.fromPlatformCreationParams}
///
/// Below is an example of accessing the platform-specific implementation for
/// iOS and Android:
///
/// ```dart
/// final WebViewCookieManager cookieManager = WebViewCookieManager();
///
/// if (WebViewPlatform.instance is WebKitWebViewPlatform) {
///   final WebKitWebViewCookieManager webKitManager =
///       cookieManager.platform as WebKitWebViewCookieManager;
/// } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
///   final AndroidWebViewCookieManager androidManager =
///       cookieManager.platform as AndroidWebViewCookieManager;
/// }
/// ```
class WebViewCookieManager {
  /// Constructs a [WebViewCookieManager].
  ///
  /// See [WebViewCookieManager.fromPlatformCreationParams] for setting
  /// parameters for a specific platform.
  WebViewCookieManager()
      : this.fromPlatformCreationParams(
          const PlatformWebViewCookieManagerCreationParams(),
        );

  /// Constructs a [WebViewCookieManager] from creation params for a specific
  /// platform.
  ///
  /// {@template webview_flutter.WebViewCookieManager.fromPlatformCreationParams}
  /// Below is an example of setting platform-specific creation parameters for
  /// iOS and Android:
  ///
  /// ```dart
  /// PlatformWebViewCookieManagerCreationParams params =
  ///     const PlatformWebViewCookieManagerCreationParams();
  ///
  /// if (WebViewPlatform.instance is WebKitWebViewPlatform) {
  ///   params = WebKitWebViewCookieManagerCreationParams
  ///       .fromPlatformWebViewCookieManagerCreationParams(
  ///     params,
  ///   );
  /// } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
  ///   params = AndroidWebViewCookieManagerCreationParams
  ///       .fromPlatformWebViewCookieManagerCreationParams(
  ///     params,
  ///   );
  /// }
  ///
  /// final WebViewCookieManager webViewCookieManager =
  ///     WebViewCookieManager.fromPlatformCreationParams(
  ///   params,
  /// );
  /// ```
  /// {@endtemplate}
  WebViewCookieManager.fromPlatformCreationParams(
    PlatformWebViewCookieManagerCreationParams params,
  ) : this.fromPlatform(PlatformWebViewCookieManager(params));

  /// Constructs a [WebViewCookieManager] from a specific platform
  /// implementation.
  WebViewCookieManager.fromPlatform(this.platform);

  /// Implementation of [PlatformWebViewCookieManager] for the current platform.
  final PlatformWebViewCookieManager platform;

  /// Clears all cookies for all WebViews.
  ///
  /// Returns true if cookies were present before clearing, else false.
  Future<bool> clearCookies() => platform.clearCookies();

  /// Sets a cookie for all WebView instances.
  ///
  /// This is a no op on iOS versions below 11.
  Future<void> setCookie(WebViewCookie cookie) => platform.setCookie(cookie);
}
