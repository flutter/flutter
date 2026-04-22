// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show FlutterView;

/// Web implementation of browser scroll view bindings.
///
/// On web, [FlutterView] is backed by `EngineFlutterView` which provides
/// browser scroll methods via the dart:ui API surface. This class uses
/// dynamic dispatch to call those methods, since the native dart:ui
/// `FlutterView` class does not declare them.
class BrowserScrollViewBinding {
  /// Creates a binding for the given [FlutterView].
  BrowserScrollViewBinding(this.view);

  /// The [FlutterView] this binding is associated with.
  final FlutterView view;

  // Use dynamic to call web-only FlutterView methods that the native
  // analyzer cannot resolve.
  dynamic get _webView => view;

  /// Enables browser-driven scrolling on the view.
  // ignore: avoid_dynamic_calls
  void enableBrowserScrolling() => _webView.enableBrowserScrolling();

  /// Disables browser-driven scrolling on the view.
  // ignore: avoid_dynamic_calls
  void disableBrowserScrolling() => _webView.disableBrowserScrolling();

  /// Instantly scrolls the browser to the given offset.
  // ignore: avoid_dynamic_calls
  void browserScrollTo(double offset) => _webView.browserScrollTo(offset);

  /// Smoothly scrolls the browser to the given offset.
  // ignore: avoid_dynamic_calls
  void browserSmoothScrollTo(double offset) => _webView.browserSmoothScrollTo(offset);

  /// Scrolls the browser by the given delta.
  // ignore: avoid_dynamic_calls
  void browserScrollBy(double delta) => _webView.browserScrollBy(delta);

  /// Updates the browser scroll content height.
  void updateBrowserScrollContentHeight(double height) =>
      // ignore: avoid_dynamic_calls
      _webView.updateBrowserScrollContentHeight(height);

  /// The callback invoked when the browser reports a scroll position change.
  void Function(double offset)? get onBrowserScroll =>
      // ignore: avoid_dynamic_calls
      _webView.onBrowserScroll as void Function(double)?;

  set onBrowserScroll(void Function(double offset)? callback) {
    _webView.onBrowserScroll = callback; // ignore: avoid_dynamic_calls
  }
}
