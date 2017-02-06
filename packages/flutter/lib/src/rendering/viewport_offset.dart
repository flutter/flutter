// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

/// The direction of a scroll, relative to the positive scroll offset axis given
/// by an [AxisDirection] and a [GrowthDirection].
///
/// This contrasts to [GrowthDirection] in that it has a third value, [idle],
/// for the case where no scroll is occurring.
///
/// This is used by [RenderSliverFloatingPersistentHeader] to only expand when
/// the user is scrolling in the same direction as the detected scroll offset
/// change.
enum ScrollDirection {
  /// No scrolling is underway.
  idle,

  /// Scrolling is happening in the positive scroll offset direction.
  ///
  /// For example, for the [GrowthDirection.forward] part of a vertical
  /// [AxisDirection.down] list, this means the content is moving up, exposing
  /// lower content.
  forward,

  /// Scrolling is happening in the negative scroll offset direction.
  ///
  /// For example, for the [GrowthDirection.forward] part of a vertical
  /// [AxisDirection.down] list, this means the content is moving down, exposing
  /// earlier content.
  reverse,
}

abstract class ViewportOffset extends ChangeNotifier {
  ViewportOffset();
  factory ViewportOffset.fixed(double value) = _FixedViewportOffset;
  factory ViewportOffset.zero() = _FixedViewportOffset.zero;

  /// The number of pixels to offset the children in the opposite of the axis direction.
  ///
  /// For example, if the axis direction is down, then the pixel value
  /// represents the number of logical pixels to move the children _up_ the
  /// screen. Similarly, if the axis direction is left, then the pixels value
  /// represents the number of logical pixesl to move the children to _right_.
  double get pixels;

  /// Called when the viewport's extents are established.
  ///
  /// The argument is the dimension of the [RenderViewport2] in the main axis
  /// (e.g. the height, for a vertical viewport).
  ///
  /// This may be called redundantly, with the same value, each frame. This is
  /// called during layout for the [RenderViewport2]. If the viewport is
  /// configured to shrink-wrap its contents, it may be called several times,
  /// since the layout is repeated each time the scroll offset is corrected.
  ///
  /// If this is called, it is called before [applyContentDimensions]. If this
  /// is called, [applyContentDimensions] will be called soon afterwards in the
  /// same layout phase. If the viewport is not configured to shrink-wrap its
  /// contents, then this will only be called when the viewport recomputes its
  /// size (i.e. when its parent lays out), and not during normal scrolling.
  void applyViewportDimension(double viewportDimension);

  /// Called when the viewport's content extents are established.
  ///
  /// The arguments are the minimum and maximum scroll extents respectively. The
  /// minimum will be equal to or less than zero, the maximum will be equal to
  /// or greater than zero.
  ///
  /// The maximum scroll extent has the viewport dimension subtracted from it.
  /// For instance, if there is 100.0 pixels of scrollable content, and the
  /// viewport is 80.0 pixels high, then the minimum scroll extent will
  /// typically be 0.0 and the maximum scroll extent will typically be 20.0,
  /// because there's only 20.0 pixels of actual scroll slack.
  ///
  /// If applying the content dimensions changes the scroll offset, return
  /// false. Otherwise, return true. If you return false, the [RenderViewport2]
  /// will be laid out again with the new scroll offset. This is expensive. (The
  /// return value is answering the question "did you accept these content
  /// dimensions unconditionally?"; if the new dimensions change the
  /// [ViewportOffset]'s actual [pixels] value, then the viewport will need to
  /// be laid out again.)
  ///
  /// This is called at least once each time the [RenderViewport2] is laid out,
  /// even if the values have not changed. It may be called many times if the
  /// scroll offset is corrected (if this returns false). This is always called
  /// after [applyViewportDimension], if that method is called.
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent);

  /// Apply a layout-time correction to the scroll offset.
  ///
  /// This method should change the [pixels] value by `correction`, but without
  /// calling [notifyListeners]. It is called during layout by the
  /// [RenderViewport2], before [applyContentDimensions]. After this method is
  /// called, the layout will be recomputed and that may result in this method
  /// being called again, though this should be very rare.
  void correctBy(double correction);

  /// The direction in which the user is trying to change [pixels], relative to
  /// the viewport's [RenderViewport2.axisDirection].
  ///
  /// This is used by some slivers to determine how to react to a change in
  /// scroll offset. For example, [RenderSliverFloatingPersistentHeader] will
  /// only expand a floating app bar when the [userScrollDirection] is in the
  /// positive scroll offset direction.
  ScrollDirection get userScrollDirection;

  @override
  String toString() {
    final List<String> description = <String>[];
    debugFillDescription(description);
    return '$runtimeType(${description.join(", ")})';
  }

  @mustCallSuper
  void debugFillDescription(List<String> description) {
    description.add('offset: ${pixels.toStringAsFixed(1)}');
  }
}

class _FixedViewportOffset extends ViewportOffset {
  _FixedViewportOffset(this._pixels);
  _FixedViewportOffset.zero() : _pixels = 0.0;

  double _pixels;

  @override
  double get pixels => _pixels;

  @override
  void applyViewportDimension(double viewportDimension) { }

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) => true;

  @override
  void correctBy(double correction) {
    _pixels += correction;
  }

  @override
  ScrollDirection get userScrollDirection => ScrollDirection.idle;
}
