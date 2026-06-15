// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:ui/src/engine/address_bar_controller.dart';
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
        // Chrome on iOS reports an incorrect viewport.width when the app
        // starts in portrait orientation and the phone is rotated to
        // landscape, so the width is read from documentElement's clientWidth.
        windowInnerWidth = domDocument.documentElement!.clientWidth * devicePixelRatio;
      } else {
        windowInnerWidth = viewport.width! * devicePixelRatio;
      }

      windowInnerHeight = _physicalInnerHeight(
        viewport,
        devicePixelRatio,
        preferInnerHeight: AddressBarController.isSupportedOperatingSystem,
      );
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
      // Match computePhysicalSize; while editing, the visual viewport shrinks
      // for the keyboard, so its height is used instead of innerHeight.
      windowInnerHeight = _physicalInnerHeight(
        viewport,
        devicePixelRatio,
        preferInnerHeight: AddressBarController.isSupportedOperatingSystem && !isEditingOnMobile,
      );
    } else {
      windowInnerHeight = domWindow.innerHeight! * devicePixelRatio;
    }
    // The address bar can collapse while editing, growing the viewport past
    // the preserved physical height.
    final double bottomPadding = math.max(0.0, physicalHeight - windowInnerHeight);

    return ViewPadding(bottom: bottomPadding, left: 0, right: 0, top: 0);
  }

  /// The physical height of the view, read from either `window.innerHeight` or
  /// the visual viewport.
  ///
  /// On mobile, `innerHeight` tracks the address bar collapse without firing the
  /// intermediate values that `visualViewport.height` produces during the
  /// animation, so it is preferred when [preferInnerHeight] is true. The visual
  /// viewport height is used otherwise (e.g. while editing, when it shrinks for
  /// the on-screen keyboard).
  double _physicalInnerHeight(
    DomVisualViewport viewport,
    double devicePixelRatio, {
    required bool preferInnerHeight,
  }) {
    final double height = preferInnerHeight ? domWindow.innerHeight! : viewport.height!;
    return height * devicePixelRatio;
  }
}
