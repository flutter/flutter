// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'types.dart';

/// Configuration to use when creating a new [WebViewPlatformController].
///
/// The `autoMediaPlaybackPolicy` parameter must not be null.
class CreationParams {
  /// Constructs an instance to use when creating a new
  /// [WebViewPlatformController].
  ///
  /// The `autoMediaPlaybackPolicy` parameter must not be null.
  CreationParams({
    this.initialUrl,
    this.webSettings,
    this.javascriptChannelNames = const <String>{},
    this.userAgent,
    this.autoMediaPlaybackPolicy =
        AutoMediaPlaybackPolicy.require_user_action_for_all_media_types,
    this.backgroundColor,
    this.cookies = const <WebViewCookie>[],
  });

  /// The initialUrl to load in the webview.
  ///
  /// When null the webview will be created without loading any page.
  final String? initialUrl;

  /// The initial [WebSettings] for the new webview.
  ///
  /// This can later be updated with [WebViewPlatformController.updateSettings].
  final WebSettings? webSettings;

  /// The initial set of JavaScript channels that are configured for this webview.
  ///
  /// For each value in this set the platform's webview should make sure that a corresponding
  /// property with a postMessage method is set on `window`. For example for a JavaScript channel
  /// named `Foo` it should be possible for JavaScript code executing in the webview to do
  ///
  /// ```javascript
  /// Foo.postMessage('hello');
  /// ```
  // TODO(amirh): describe what should happen when postMessage is called once that code is migrated
  // to PlatformWebView.
  final Set<String> javascriptChannelNames;

  /// The value used for the HTTP User-Agent: request header.
  ///
  /// When null the platform's webview default is used for the User-Agent header.
  final String? userAgent;

  /// Which restrictions apply on automatic media playback.
  final AutoMediaPlaybackPolicy autoMediaPlaybackPolicy;

  /// The background color of the webview.
  ///
  /// When null the platform's webview default background color is used.
  final Color? backgroundColor;

  /// The initial set of cookies to set before the webview does its first load.
  final List<WebViewCookie> cookies;

  @override
  String toString() {
    return 'CreationParams(initialUrl: $initialUrl, settings: $webSettings, javascriptChannelNames: $javascriptChannelNames, UserAgent: $userAgent, backgroundColor: $backgroundColor, cookies: $cookies)';
  }
}
