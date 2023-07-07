// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../platform_interface/javascript_channel_registry.dart';
import '../types/types.dart';
import 'webview_platform_callbacks_handler.dart';
import 'webview_platform_controller.dart';

/// Signature for callbacks reporting that a [WebViewPlatformController] was created.
///
/// See also the `onWebViewPlatformCreated` argument for [WebViewPlatform.build].
typedef WebViewPlatformCreatedCallback = void Function(
    WebViewPlatformController? webViewPlatformController);

/// Interface for a platform implementation of a WebView.
///
/// [WebView.platform] controls the builder that is used by [WebView].
/// [AndroidWebViewPlatform] and [CupertinoWebViewPlatform] are the default implementations
/// for Android and iOS respectively.
abstract class WebViewPlatform {
  /// Builds a new WebView.
  ///
  /// Returns a Widget tree that embeds the created webview.
  ///
  /// `creationParams` are the initial parameters used to setup the webview.
  ///
  /// `webViewPlatformHandler` will be used for handling callbacks that are made by the created
  /// [WebViewPlatformController].
  ///
  /// `onWebViewPlatformCreated` will be invoked after the platform specific [WebViewPlatformController]
  /// implementation is created with the [WebViewPlatformController] instance as a parameter.
  ///
  /// `gestureRecognizers` specifies which gestures should be consumed by the web view.
  /// It is possible for other gesture recognizers to be competing with the web view on pointer
  /// events, e.g. if the web view is inside a [ListView] the [ListView] will want to handle
  /// vertical drags. The web view will claim gestures that are recognized by any of the
  /// recognizers on this list.
  /// When `gestureRecognizers` is empty or null, the web view will only handle pointer events for gestures that
  /// were not claimed by any other gesture recognizer.
  ///
  /// `webViewPlatformHandler` must not be null.
  Widget build({
    required BuildContext context,
    // TODO(amirh): convert this to be the actual parameters.
    // I'm starting without it as the PR is starting to become pretty big.
    // I'll followup with the conversion PR.
    required CreationParams creationParams,
    required WebViewPlatformCallbacksHandler webViewPlatformCallbacksHandler,
    required JavascriptChannelRegistry javascriptChannelRegistry,
    WebViewPlatformCreatedCallback? onWebViewPlatformCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  });

  /// Clears all cookies for all [WebView] instances.
  ///
  /// Returns true if cookies were present before clearing, else false.
  /// Soon to be deprecated. 'Use `WebViewCookieManagerPlatform.clearCookies` instead.
  Future<bool> clearCookies() {
    throw UnimplementedError(
        'WebView clearCookies is not implemented on the current platform');
  }
}
