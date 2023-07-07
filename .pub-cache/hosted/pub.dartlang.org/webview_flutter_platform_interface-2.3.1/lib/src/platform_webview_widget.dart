// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'types/types.dart';
import 'webview_platform.dart' show WebViewPlatform;

/// Interface for a platform implementation of a web view widget.
abstract class PlatformWebViewWidget extends PlatformInterface {
  /// Creates a new [PlatformWebViewWidget]
  factory PlatformWebViewWidget(PlatformWebViewWidgetCreationParams params) {
    assert(
      WebViewPlatform.instance != null,
      'A platform implementation for `webview_flutter` has not been set. Please '
      'ensure that an implementation of `WebViewPlatform` has been set to '
      '`WebViewPlatform.instance` before use. For unit testing, '
      '`WebViewPlatform.instance` can be set with your own test implementation.',
    );
    final PlatformWebViewWidget webViewWidgetDelegate =
        WebViewPlatform.instance!.createPlatformWebViewWidget(params);
    PlatformInterface.verify(webViewWidgetDelegate, _token);
    return webViewWidgetDelegate;
  }

  /// Used by the platform implementation to create a new
  /// [PlatformWebViewWidget].
  ///
  /// Should only be used by platform implementations because they can't extend
  /// a class that only contains a factory constructor.
  @protected
  PlatformWebViewWidget.implementation(this.params) : super(token: _token);

  static final Object _token = Object();

  /// The parameters used to initialize the [PlatformWebViewWidget].
  final PlatformWebViewWidgetCreationParams params;

  /// Builds a new WebView.
  ///
  /// Returns a Widget tree that embeds the created web view.
  Widget build(BuildContext context);
}
