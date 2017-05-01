// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// A description of a [Scrollable]'s contents, useful for modelling the state
/// of its viewport.
///
/// This class defines a current position, [pixels], and a range of values
/// considered "in bounds" for that position. The range has a minimum value at
/// [minScrollExtent] and a maximum value at [maxScrollExtent] (inclusive). The
/// viewport scrolls in the direction and axis described by [axisDirection]
/// and [axis].
///
/// The [outOfRange] getter will return true if [pixels] is outside this defined
/// range. The [atEdge] getter will return true if the [pixels] position equals
/// either the [minScrollExtent] or the [maxScrollExtent].
///
/// The dimensions of the viewport in the given [axis] are described by
/// [viewportDimension].
///
/// The above values are also exposed in terms of [extentBefore],
/// [extentInside], and [extentAfter], which may be more useful for use cases
/// such as scroll bars; for example, see [Scrollbar].
///
/// See also:
///
///  * [FixedScrollMetrics], which is an immutable object that implements this
///    interface.
abstract class ScrollMetrics {
  /// Creates a [ScrollMetrics] that has the same properties as this object.
  ///
  /// This is useful if this object is mutable, but you want to get a snapshot
  /// of the current state.
  ScrollMetrics cloneMetrics() => new FixedScrollMetrics.clone(this);

  /// The minimum in-range value for [pixels].
  ///
  /// The actual [pixels] value might be [outOfRange].
  double get minScrollExtent;

  /// The maximum in-range value for [pixels].
  ///
  /// The actual [pixels] value might be [outOfRange].
  double get maxScrollExtent;

  /// The current scroll position, in logical pixels along the [axisDirection].
  double get pixels;

  /// The extent of the viewport along the [axisDirection].
  double get viewportDimension;

  /// The direction in which the scroll view scrolls.
  AxisDirection get axisDirection;

  /// The axis in which the scroll view scrolls.
  Axis get axis => axisDirectionToAxis(axisDirection);

  /// Whether the [pixels] value is outside the [minScrollExtent] and
  /// [maxScrollExtent].
  bool get outOfRange => pixels < minScrollExtent || pixels > maxScrollExtent;

  /// Whether the [pixels] value is exactly at the [minScrollExtent] or the
  /// [maxScrollExtent].
  bool get atEdge => pixels == minScrollExtent || pixels == maxScrollExtent;

  /// The quantity of content conceptually "above" the currently visible content
  /// of the viewport in the scrollable. This is the content above the content
  /// described by [extentInside].
  double get extentBefore => math.max(pixels - minScrollExtent, 0.0);

  /// The quantity of visible content.
  ///
  /// If [extentBefore] and [extentAfter] are non-zero, then this is typically
  /// the height of the viewport. It could be less if there is less content
  /// visible than the size of the viewport.
  double get extentInside {
    return math.min(pixels, maxScrollExtent) -
           math.max(pixels, minScrollExtent) +
           math.min(viewportDimension, maxScrollExtent - minScrollExtent);
  }

  /// The quantity of content conceptually "below" the currently visible content
  /// of the viewport in the scrollable. This is the content below the content
  /// described by [extentInside].
  double get extentAfter => math.max(maxScrollExtent - pixels, 0.0);
}

/// An immutable snapshot of values associated with a [Scrollable] viewport.
///
/// For details, see [ScrollMetrics], which defines this object's interfaces.
@immutable
class FixedScrollMetrics extends ScrollMetrics {
  /// Creates an immutable snapshot of values associated with a [Scrollable] viewport.
  FixedScrollMetrics({
    @required this.minScrollExtent,
    @required this.maxScrollExtent,
    @required this.pixels,
    @required this.viewportDimension,
    @required this.axisDirection,
  });

  /// Creates an immutable snapshot of the given metrics.
  FixedScrollMetrics.clone(ScrollMetrics parent) :
    minScrollExtent = parent.minScrollExtent,
    maxScrollExtent = parent.maxScrollExtent,
    pixels = parent.pixels,
    viewportDimension = parent.viewportDimension,
    axisDirection = parent.axisDirection;

  @override
  final double minScrollExtent;

  @override
  final double maxScrollExtent;

  @override
  final double pixels;

  @override
  final double viewportDimension;

  @override
  final AxisDirection axisDirection;

  @override
  String toString() {
    return '$runtimeType(${extentBefore.toStringAsFixed(1)}..[${extentInside.toStringAsFixed(1)}]..${extentAfter.toStringAsFixed(1)})';
  }
}