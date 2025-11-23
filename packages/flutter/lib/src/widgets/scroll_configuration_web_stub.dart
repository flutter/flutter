// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Stub implementation for non-web platforms.
///
/// This file provides empty implementations for web-specific browser scrolling
/// features on non-web platforms.
library;

import 'package:flutter/foundation.dart';

import 'framework.dart';
import 'scroll_controller.dart';
import 'scroll_physics.dart';

/// Always returns false on non-web platforms.
bool get kDefaultBrowserScrollingEnabled => false;

/// No-op on non-web platforms.
void setBrowserScrollingDefault(bool enabled) {
  // No-op on non-web platforms
}

/// Always returns false on non-web platforms.
bool shouldUseBrowserScrolling({
  bool? explicitSetting,
  ScrollPhysics? physics,
}) {
  return false;
}

/// Stub interface for external scrollers on non-web platforms.
abstract class ExternalScroller {
  void setup();
  Object computeVisibleRect();  // Returns ui.Rect on web
  void addScrollListener(VoidCallback listener);
  void removeScrollListener(VoidCallback listener);
  void updateHeight(double height);
  void enableBoundaryDetection(ScrollController controller);
  void disableBoundaryDetection();
  void dispose();
}

/// Stub widget for non-web platforms.
class BrowserScrollView extends StatelessWidget {
  const BrowserScrollView({
    super.key,
    required this.child,
    this.scrollController,
  });

  final Widget child;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Throws an error on non-web platforms.
///
/// Browser scrolling is only available on web.
ExternalScroller createBrowserScrollStrategy(int viewId) {
  throw UnsupportedError(
    'Browser scrolling is only supported on web platforms. '
    'This method should never be called on non-web platforms.'
  );
}

