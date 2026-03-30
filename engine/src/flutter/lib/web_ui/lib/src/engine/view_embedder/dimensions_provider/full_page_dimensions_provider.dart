// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:ui/src/engine/display.dart';
import 'package:ui/src/engine/dom.dart';
import 'package:ui/src/engine/window.dart';
import 'package:ui/ui.dart' as ui show Size;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import 'dimensions_provider.dart';

/// This class provides the real-time dimensions of a "full page" viewport.
///
/// All the measurements returned from this class are potentially *expensive*,
/// and should be cached as needed. Every call to every method on this class
/// WILL perform actual DOM measurements.
class FullPageDimensionsProvider extends DimensionsProvider {
  /// Constructs a global [FullPageDimensionsProvider].
  ///
  /// Doesn't need any parameters, because all the measurements come from the
  /// globally available [DomVisualViewport].
  FullPageDimensionsProvider() {
    // Determine what 'resize' event we'll be listening to.
    // This is needed for older browsers (Firefox < 91, Safari < 13)
    // TODO(dit): Clean this up, https://github.com/flutter/flutter/issues/117105
    final DomEventTarget resizeEventTarget = domWindow.visualViewport ?? domWindow;

    // Subscribe to the 'resize' event, and convert it to a ui.Size stream.
    _domResizeSubscription = DomSubscription(
      resizeEventTarget,
      'resize',
      createDomEventListener(_onVisualViewportResize),
    );
  }

  late DomSubscription _domResizeSubscription;
  final StreamController<ui.Size?> _onResizeStreamController =
      StreamController<ui.Size?>.broadcast();

  void _onVisualViewportResize(DomEvent event) {
    // `event` doesn't contain any size information (as opposed to the custom
    // element resize observer). If it did, we could broadcast the physical
    // dimensions here and never have to re-measure the app, until the next
    // resize event triggers.
    // Would it be too costly to broadcast the computed physical size from here,
    // and then never re-measure the app?
    // Related: https://github.com/flutter/flutter/issues/117036
    _onResizeStreamController.add(null);
  }

  @override
  void close() {
    super.close();
    _domResizeSubscription.cancel();
    _onResizeStreamController.close();
  }

  @override
  Stream<ui.Size?> get onResize => _onResizeStreamController.stream;

  @override
  ui.Size computePhysicalSize() {
    late double windowInnerWidth;
    late double windowInnerHeight;
    final DomVisualViewport? viewport = domWindow.visualViewport;
    final double devicePixelRatio = EngineFlutterDisplay.instance.devicePixelRatio;

    if (viewport != null) {
      if (ui_web.browser.operatingSystem == ui_web.OperatingSystem.iOs) {
        // Chrome on iOS reports incorrect viewport.width when the app starts
        // in portrait and is rotated to landscape.  clientWidth is reliable.
        // See: https://github.com/flutter/flutter/issues/81430
        windowInnerWidth = domDocument.documentElement!.clientWidth * devicePixelRatio;
      } else {
        windowInnerWidth = viewport.width! * devicePixelRatio;
      }

      if (ui_web.browser.isMobile) {
        // innerHeight tracks address bar collapse without firing
        // intermediate values during the animation, unlike viewport.height.
        // See: https://github.com/flutter/flutter/issues/69529
        windowInnerHeight = domWindow.innerHeight! * devicePixelRatio;
      } else {
        windowInnerHeight = viewport.height! * devicePixelRatio;
      }
    } else {
      windowInnerWidth = domWindow.innerWidth! * devicePixelRatio;
      windowInnerHeight = domWindow.innerHeight! * devicePixelRatio;
    }
    return ui.Size(windowInnerWidth, windowInnerHeight);
  }

  @override
  ViewPadding computeKeyboardInsets(double physicalHeight, bool isEditingOnMobile) {
    final double devicePixelRatio = EngineFlutterDisplay.instance.devicePixelRatio;
    final DomVisualViewport? viewport = domWindow.visualViewport;
    late double windowInnerHeight;

    if (viewport != null) {
      if (ui_web.browser.isMobile && !isEditingOnMobile) {
        // Match computePhysicalSize() which uses innerHeight on mobile.
        windowInnerHeight = domWindow.innerHeight! * devicePixelRatio;
      } else {
        windowInnerHeight = viewport.height! * devicePixelRatio;
      }
    } else {
      windowInnerHeight = domWindow.innerHeight! * devicePixelRatio;
    }
    final double bottomPadding = physicalHeight - windowInnerHeight;

    return ViewPadding(bottom: bottomPadding, left: 0, right: 0, top: 0);
  }
}
