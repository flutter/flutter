// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show FlutterView;

import 'package:flutter/foundation.dart';

/// Non-web implementation of browser scroll view bindings.
///
/// On non-web platforms, browser scrolling is not available. All methods
/// record their calls so tests can verify outbound communication. The
/// [onBrowserScroll] callback is stored locally so tests can simulate
/// browser scroll events.
class BrowserScrollViewBinding {
  /// Creates a binding for the given [FlutterView].
  BrowserScrollViewBinding(this.view);

  /// The [FlutterView] this binding is associated with.
  final FlutterView view;

  /// Whether the engine supports browser-driven scrolling for this view.
  ///
  /// Always false on non-web platforms in production, so apps that ship
  /// to iOS/Android/desktop don't accidentally engage [BrowserScrollPhysics]
  /// against a binding the engine cannot drive. Tests can flip
  /// [debugForceSupportedForTests] to true to exercise the browser-scroll
  /// code path against the recording stub.
  bool get supported => debugForceSupportedForTests;

  /// Test-only override that makes [supported] return true on non-web.
  /// Reset to false in tearDown to avoid leaking across tests.
  @visibleForTesting
  static bool debugForceSupportedForTests = false;

  /// Recorded method calls for test assertions.
  ///
  /// Each entry is a map with `method` and optional `args` keys.
  final List<Map<String, Object?>> calls = <Map<String, Object?>>[];

  /// Records a method call.
  void _record(String method, [Object? args]) {
    calls.add(<String, Object?>{'method': method, if (args != null) 'args': args});
  }

  /// No-op on non-web platforms. Records the call.
  void enableBrowserScrolling() => _record('enableBrowserScrolling');

  /// No-op on non-web platforms. Records the call.
  void disableBrowserScrolling() => _record('disableBrowserScrolling');

  /// No-op on non-web platforms. Records the call.
  void browserScrollTo(double offset) => _record('browserScrollTo', offset);

  /// No-op on non-web platforms. Records the call.
  void browserSmoothScrollTo(double offset) => _record('browserSmoothScrollTo', offset);

  /// No-op on non-web platforms. Records the call.
  void browserScrollBy(double delta) => _record('browserScrollBy', delta);

  /// No-op on non-web platforms. Records the call.
  void updateBrowserScrollContentHeight(double height) =>
      _record('updateBrowserScrollContentHeight', height);

  /// The callback invoked when the browser reports a scroll position change.
  ///
  /// On non-web platforms, this callback is stored locally so tests can
  /// simulate browser scroll events.
  void Function(double offset)? onBrowserScroll;
}
