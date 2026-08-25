// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:ui/src/engine/dom.dart';
import 'package:ui/src/engine/view_embedder/display_dpr_stream.dart';
import 'package:ui/src/engine/window.dart';
import 'package:ui/ui.dart' as ui show Size;

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
      return CustomElementDimensionsProvider(
        hostElement,
        onDprChange: DisplayDprStream.instance.dprChanged,
      );
    } else {
      return FullPageDimensionsProvider();
    }
  }

  /// Returns the [ui.Size] of the "viewport".
  ///
  /// This function is expensive. It triggers browser layout if there are
  /// pending DOM writes.
  ui.Size computePhysicalSize();

  /// Returns the [ViewPadding] of the keyboard insets (if present).
  ViewPadding computeKeyboardInsets(double physicalHeight, bool isEditingOnMobile);

  /// Returns the [ViewPadding] of the safe area insets (if any), in physical
  /// pixels.
  ///
  /// The safe area is the part of the viewport that is not obstructed by the
  /// device itself: display cutouts, rounded corners, or a home indicator.
  ///
  /// On the web these insets come from the CSS `env(safe-area-inset-*)`
  /// environment variables, and only apply to a page that opted into laying
  /// itself out underneath those obstructions, by declaring
  /// `viewport-fit=cover` in the viewport meta tag of its `index.html`. A page
  /// that didn't opt in is laid out within the safe area by the browser, and
  /// gets no insets. This is a stricter rule than what the browser
  /// applies to `env()` itself: iOS Safari reports a non-zero
  /// `env(safe-area-inset-bottom)` for the home indicator even for a viewport
  /// it keeps clear of it, and reporting that would move the content of apps
  /// that never asked for a full-bleed layout.
  ///
  /// Only [FullPageDimensionsProvider] reports a non-zero value. A view that is
  /// embedded in a custom element is positioned by the host application, which
  /// is therefore the one that knows how that element overlaps the obstructions
  /// of the screen.
  ///
  /// The value is only guaranteed to be up to date right after the view is
  /// resized. A change to the safe area that doesn't resize the viewport, such
  /// as the taller status bar that iOS shows during a call, isn't observed.
  ViewPadding computeSafeAreaInsets();

  /// Returns a Stream with the changes to [ui.Size] (when cheap to get).
  ///
  /// Currently this Stream always returns `null` measurements because the
  /// resize event that we use for [FullPageDimensionsProvider] does not contain
  /// the new size, so users of this Stream everywhere immediately retrieve the
  /// new `physicalSize` from the window.
  ///
  /// The [CustomElementDimensionsProvider] *could* broadcast the new size, but
  /// to keep both implementations consistent (and their consumers), for now all
  /// events from this Stream are going to be `null` (until we find a performant
  /// way to retrieve the dimensions in full-page mode).
  Stream<ui.Size?> get onResize;

  /// Whether the [DimensionsProvider] instance has been closed or not.
  @visibleForTesting
  bool isClosed = false;

  /// Clears any resources grabbed by the DimensionsProvider instance.
  ///
  /// All internal event handlers will be disconnected, and the [onResize] Stream
  /// will be closed.
  @mustCallSuper
  void close() {
    isClosed = true;
  }
}
