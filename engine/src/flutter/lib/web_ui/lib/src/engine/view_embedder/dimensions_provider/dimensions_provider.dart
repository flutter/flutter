// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:ui/src/engine/window.dart';
import 'package:ui/ui.dart' as ui show Size;

import '../../display.dart';
import '../../dom.dart';
import 'custom_element_dimensions_provider.dart';
import 'full_page_dimensions_provider.dart';

/// This class provides the dimensions of the "viewport" in which the app is rendered.
///
/// Similarly to the `EmbeddingStrategy`, this class is specialized to handle
/// different sources of information:
///
/// * [FullPageDimensionsProvider] - The default behavior, uses the VisualViewport
///   API to measure, and react to, the dimensions of the full browser window.
/// * [CustomElementDimensionsProvider] - Uses a custom html Element as the source
///   of dimensions, and the ResizeObserver to notify the app of changes.
///
/// All the measurements returned from this class are potentially *expensive*,
/// and should be cached as needed. Every call to every method on this class
/// WILL perform actual DOM measurements.
abstract class DimensionsProvider {
  DimensionsProvider();

  /// Creates the appropriate DimensionsProvider depending on the incoming [hostElement].
  factory DimensionsProvider.create({DomElement? hostElement}) {
    if (hostElement != null) {
      return CustomElementDimensionsProvider(hostElement);
    } else {
      return FullPageDimensionsProvider();
    }
  }

  /// Returns the DPI reported by the browser.
  double getDevicePixelRatio() {
    // This is overridable in tests.
    return EngineFlutterDisplay.instance.devicePixelRatio;
  }

  /// Returns the [ui.Size] of the "viewport".
  ///
  /// This function is expensive. It triggers browser layout if there are
  /// pending DOM writes.
  ui.Size computePhysicalSize();

  /// Returns the [ViewPadding] of the keyboard insets (if present).
  ViewPadding computeKeyboardInsets(
    double physicalHeight,
    bool isEditingOnMobile,
  );

  /// Returns a Stream with the changes to [ui.Size] (when cheap to get).
  Stream<ui.Size?> get onResize;

  /// Clears any resources grabbed by the DimensionsProvider instance.
  ///
  /// All internal event handlers will be disconnected, and the [onResize] Stream
  /// will be closed.
  void close();
}
