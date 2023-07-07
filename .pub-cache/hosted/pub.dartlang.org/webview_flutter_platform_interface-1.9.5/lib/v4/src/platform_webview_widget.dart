// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'webview_platform.dart';

/// Interface for a platform implementation of a web view widget.
abstract class PlatformWebViewWidget extends PlatformInterface {
  /// Creates a new [PlatformWebViewWidget]
  factory PlatformWebViewWidget(PlatformWebViewWidgetCreationParams params) {
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
