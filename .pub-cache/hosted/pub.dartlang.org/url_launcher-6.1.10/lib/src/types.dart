// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// The desired mode to launch a URL.
///
/// Support for these modes varies by platform. Platforms that do not support
/// the requested mode may substitute another mode. See [launchUrl] for more
/// details.
enum LaunchMode {
  /// Leaves the decision of how to launch the URL to the platform
  /// implementation.
  platformDefault,

  /// Loads the URL in an in-app web view (e.g., Safari View Controller).
  inAppWebView,

  /// Passes the URL to the OS to be handled by another application.
  externalApplication,

  /// Passes the URL to the OS to be handled by another non-browser application.
  externalNonBrowserApplication,
}

/// Additional configuration options for [LaunchMode.inAppWebView].
@immutable
class WebViewConfiguration {
  /// Creates a new WebViewConfiguration with the given settings.
  const WebViewConfiguration({
    this.enableJavaScript = true,
    this.enableDomStorage = true,
    this.headers = const <String, String>{},
  });

  /// Whether or not JavaScript is enabled for the web content.
  ///
  /// Disabling this may not be supported on all platforms.
  final bool enableJavaScript;

  /// Whether or not DOM storage is enabled for the web content.
  ///
  /// Disabling this may not be supported on all platforms.
  final bool enableDomStorage;

  /// Additional headers to pass in the load request.
  ///
  /// On Android, this may work even when not loading in an in-app web view.
  /// When loading in an external browsers, this sets
  /// [Browser.EXTRA_HEADERS](https://developer.android.com/reference/android/provider/Browser#EXTRA_HEADERS)
  /// Not all browsers support this, so it is not guaranteed to be honored.
  final Map<String, String> headers;
}
