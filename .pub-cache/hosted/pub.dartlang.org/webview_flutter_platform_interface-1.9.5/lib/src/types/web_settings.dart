// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'javascript_mode.dart';

/// A single setting for configuring a WebViewPlatform which may be absent.
@immutable
class WebSetting<T> {
  /// Constructs an absent setting instance.
  ///
  /// The [isPresent] field for the instance will be false.
  ///
  /// Accessing [value] for an absent instance will throw.
  const WebSetting.absent()
      : _value = null,
        isPresent = false;

  /// Constructs a setting of the given `value`.
  ///
  /// The [isPresent] field for the instance will be true.
  const WebSetting.of(T value)
      : _value = value,
        isPresent = true;

  final T? _value;

  /// The setting's value.
  ///
  /// Throws if [WebSetting.isPresent] is false.
  T get value {
    if (!isPresent) {
      throw StateError('Cannot access a value of an absent WebSetting');
    }
    assert(isPresent);
    // The intention of this getter is to return T whether it is nullable or
    // not whereas _value is of type T? since _value can be null even when
    // T is not nullable (when isPresent == false).
    //
    // We promote _value to T using `as T` instead of `!` operator to handle
    // the case when _value is legitimately null (and T is a nullable type).
    // `!` operator would always throw if _value is null.
    return _value as T;
  }

  /// True when this web setting instance contains a value.
  ///
  /// When false the [WebSetting.value] getter throws.
  final bool isPresent;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is WebSetting<T> &&
        other.isPresent == isPresent &&
        other._value == _value;
  }

  @override
  int get hashCode => Object.hash(_value, isPresent);
}

/// Settings for configuring a WebViewPlatform.
///
/// Initial settings are passed as part of [CreationParams], settings updates are sent with
/// [WebViewPlatform#updateSettings].
///
/// The `userAgent` parameter must not be null.
class WebSettings {
  /// Construct an instance with initial settings. Future setting changes can be
  /// sent with [WebviewPlatform#updateSettings].
  ///
  /// The `userAgent` parameter must not be null.
  WebSettings({
    this.javascriptMode,
    this.hasNavigationDelegate,
    this.hasProgressTracking,
    this.debuggingEnabled,
    this.gestureNavigationEnabled,
    this.allowsInlineMediaPlayback,
    this.zoomEnabled,
    required this.userAgent,
  }) : assert(userAgent != null);

  /// The JavaScript execution mode to be used by the webview.
  final JavascriptMode? javascriptMode;

  /// Whether the [WebView] has a [NavigationDelegate] set.
  final bool? hasNavigationDelegate;

  /// Whether the [WebView] should track page loading progress.
  /// See also: [WebViewPlatformCallbacksHandler.onProgress] to get the progress.
  final bool? hasProgressTracking;

  /// Whether to enable the platform's webview content debugging tools.
  ///
  /// See also: [WebView.debuggingEnabled].
  final bool? debuggingEnabled;

  /// Whether to play HTML5 videos inline or use the native full-screen controller on iOS.
  ///
  /// This will have no effect on Android.
  final bool? allowsInlineMediaPlayback;

  /// The value used for the HTTP `User-Agent:` request header.
  ///
  /// If [userAgent.value] is null the platform's default user agent should be used.
  ///
  /// An absent value ([userAgent.isPresent] is false) represents no change to this setting from the
  /// last time it was set.
  ///
  /// See also [WebView.userAgent].
  final WebSetting<String?> userAgent;

  /// Sets whether the WebView should support zooming using its on-screen zoom controls and gestures.
  final bool? zoomEnabled;

  /// Whether to allow swipe based navigation in iOS.
  ///
  /// See also: [WebView.gestureNavigationEnabled]
  final bool? gestureNavigationEnabled;

  @override
  String toString() {
    return 'WebSettings(javascriptMode: $javascriptMode, hasNavigationDelegate: $hasNavigationDelegate, hasProgressTracking: $hasProgressTracking, debuggingEnabled: $debuggingEnabled, gestureNavigationEnabled: $gestureNavigationEnabled, userAgent: $userAgent, allowsInlineMediaPlayback: $allowsInlineMediaPlayback)';
  }
}
