// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

/// Default value for browser scrolling enabled on non-web platforms.
const bool _kDefaultBrowserScrollingEnabled = false;

/// Public getter for the default browser scrolling enabled value.
bool get kDefaultBrowserScrollingEnabled => _kDefaultBrowserScrollingEnabled;

/// Creates a browser scroll strategy for the given view ID.
///
/// This is a stub for non-web platforms and should never be called.
ExternalScroller createBrowserScrollStrategy(int viewId) {
  throw UnsupportedError(
    'Browser scrolling is only supported on web platforms. '
    'This method should never be called on non-web platforms.',
  );
}

/// Callback for visible rect changes.
typedef RectCallback = void Function(Object);

/// Interface for external scrollers that control scrolling via the browser DOM.
///
/// This is a stub for non-web platforms.
abstract class ExternalScroller {
  /// The current scroll position from the top.
  double get scrollTop;

  /// Computes the currently visible rectangle.
  ///
  /// Returns [Object] instead of [ui.Rect] to avoid web-specific imports.
  Object computeVisibleRect();

  /// Sets up the scroller (creates DOM elements, etc.).
  void setup();

  /// Adds a listener for scroll events.
  void addScrollListener(ui.VoidCallback callback);

  /// Adds a listener for visible rect changes.
  void addVisibleRectListener(RectCallback callback);

  /// Updates the total content height.
  void updateHeight(double height);

  /// Disposes of the scroller and cleans up resources.
  void dispose();
}

