// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:ui/src/engine/display.dart';
import 'package:ui/src/engine/dom.dart';
import 'package:ui/src/engine/safe_browser_api.dart';
import 'package:ui/src/engine/window.dart';
import 'package:ui/ui.dart' as ui show Size;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../viewport_fit.dart';
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

    // The probe goes on the page up front, so that reading the safe area later
    // is a pure measurement, and never a DOM mutation in the middle of a frame.
    // It is taken back off in `close()`, which the view calls when it is
    // disposed, including on hot restart.
    domDocument.body!.append(safeAreaProbe);
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

  /// The element that the `env(safe-area-inset-*)` values are read back from.
  ///
  /// Exposed so that tests can put values in it that a desktop browser would
  /// never report on its own.
  @visibleForTesting
  final DomHTMLDivElement safeAreaProbe = _createSafeAreaProbe();

  @override
  void close() {
    super.close();
    _domResizeSubscription.cancel();
    _onResizeStreamController.close();
    safeAreaProbe.remove();
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
        /// Chrome on iOS reports incorrect viewport.height when app
        /// starts in portrait orientation and the phone is rotated to
        /// landscape.
        ///
        /// We instead use documentElement clientWidth/Height to read
        /// accurate physical size. VisualViewport api is only used during
        /// text editing to make sure inset is correctly reported to
        /// framework.
        final double docWidth = domDocument.documentElement!.clientWidth;
        final double docHeight = domDocument.documentElement!.clientHeight;
        windowInnerWidth = docWidth * devicePixelRatio;
        windowInnerHeight = docHeight * devicePixelRatio;
      } else {
        windowInnerWidth = viewport.width! * devicePixelRatio;
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
      if (ui_web.browser.operatingSystem == ui_web.OperatingSystem.iOs && !isEditingOnMobile) {
        windowInnerHeight = domDocument.documentElement!.clientHeight * devicePixelRatio;
      } else {
        windowInnerHeight = viewport.height! * devicePixelRatio;
      }
    } else {
      windowInnerHeight = domWindow.innerHeight! * devicePixelRatio;
    }
    final double bottomPadding = physicalHeight - windowInnerHeight;

    return ViewPadding(bottom: bottomPadding, left: 0, right: 0, top: 0);
  }

  @override
  ViewPadding computeSafeAreaInsets() {
    if (!_isFullBleed) {
      // The page is laid out within the safe area, so there is nothing for the
      // app to inset itself by. Report zero rather than whatever `env()` says:
      // some browsers report a non-zero inset even for a viewport they keep
      // clear of the obstruction themselves, and taking that at face value
      // would move the content of apps that never opted into a full-bleed
      // layout. See https://github.com/flutter/flutter/issues/84833.
      return const ViewPadding(top: 0, right: 0, bottom: 0, left: 0);
    }

    if (safeAreaProbe.isConnected != true) {
      // The host page owns <body>, and is free to empty it, e.g. to take a
      // custom loading indicator down. `getComputedStyle` of a detached element
      // resolves to nothing, so put the probe back before measuring it.
      domDocument.body!.append(safeAreaProbe);
    }

    final double devicePixelRatio = EngineFlutterDisplay.instance.devicePixelRatio;
    final DomCSSStyleDeclaration probeStyle = domWindow.getComputedStyle(safeAreaProbe);

    double inset(String property) {
      // A browser that doesn't understand `env()` leaves the padding at its
      // initial value, which reads back as `0px`, so there is no separate code
      // path for it. `parseFloat` only returns null for an empty string, which
      // can't happen for an element that is in the document.
      return (parseFloat(probeStyle.getPropertyValue(property)) ?? 0.0) * devicePixelRatio;
    }

    return ViewPadding(
      top: inset('padding-top'),
      right: inset('padding-right'),
      bottom: inset('padding-bottom'),
      left: inset('padding-left'),
    );
  }

  // Whether the page is laid out underneath the parts of the screen that the
  // device obstructs, which is the only situation in which the app has to inset
  // its own content.
  //
  // The viewport meta tag written by `FullPageEmbeddingStrategy` is the
  // authority on this. It is the last viewport meta tag of the page, and it
  // carries over the `viewport-fit` that the app declared in its `index.html`,
  // if any. It is read back with the same function that wrote it, so that the
  // two sides cannot drift apart over the exact spelling of the descriptor.
  bool get _isFullBleed {
    final DomElement? viewportMeta = domDocument.head?.querySelector(
      'meta[name="viewport"][flt-viewport]',
    );
    return readViewportFit(viewportMeta?.getAttribute('content')) == ViewportFit.cover;
  }

  // Creates the element that the `env(safe-area-inset-*)` values are read back
  // from.
  //
  // The browser resolves `env()` into an absolute length at computed-value
  // time, so the insets can be read back from the probe with `getComputedStyle`
  // even though the probe is `display: none`, and therefore never laid out nor
  // painted.
  static DomHTMLDivElement _createSafeAreaProbe() {
    final DomHTMLDivElement probe = createDomHTMLDivElement()
      ..setAttribute('flt-safe-area-probe', '');
    // Every declaration is `important`, because an inline declaration that is
    // not loses to an `!important` rule of the app, and a stylesheet as ordinary
    // as `* { padding: 0 !important }` would then silently zero the measurement
    // (or, for `display`, put an element on the page that shouldn't be there).
    probe.style.setProperty('display', 'none', 'important');
    for (final side in <String>['top', 'right', 'bottom', 'left']) {
      probe.style.setProperty('padding-$side', 'env(safe-area-inset-$side, 0px)', 'important');
    }
    return probe;
  }
}
