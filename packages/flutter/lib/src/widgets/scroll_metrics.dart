// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// A description of a [Scrollable]'s contents, useful for modelling the state
/// of the viewport, for example by a [Scrollbar].
///
/// The units used by the [extentBefore], [extentInside], and [extentAfter] are
/// not defined, but must be consistent. For example, they could be in pixels,
/// or in percentages, or in units of the [extentInside] (in the latter case,
/// [extentInside] would always be 1.0).
@immutable
class ScrollMetrics {
  /// Create a description of the metrics of a [Scrollable]'s contents.
  ///
  /// The three arguments must be present, non-null, finite, and non-negative.
  const ScrollMetrics({
    @required this.extentBefore,
    @required this.extentInside,
    @required this.extentAfter,
    @required this.viewportDimension,
  });

  /// Creates a [ScrollMetrics] that has the same properties as the given
  /// [ScrollMetrics].
  ScrollMetrics.clone(ScrollMetrics other)
    : extentBefore = other.extentBefore,
      extentInside = other.extentInside,
      extentAfter = other.extentAfter,
      viewportDimension = other.viewportDimension;

  /// The quantity of content conceptually "above" the currently visible content
  /// of the viewport in the scrollable. This is the content above the content
  /// described by [extentInside].
  final double extentBefore;

  /// The quantity of visible content.
  ///
  /// If [extentBefore] and [extentAfter] are non-zero, then this is typically
  /// the height of the viewport. It could be less if there is less content
  /// visible than the size of the viewport.
  final double extentInside;

  /// The quantity of content conceptually "below" the currently visible content
  /// of the viewport in the scrollable. This is the content below the content
  /// described by [extentInside].
  final double extentAfter;

  final double viewportDimension;

  @override
  String toString() {
    return '$runtimeType(${extentBefore.toStringAsFixed(1)}..[${extentInside.toStringAsFixed(1)}]..${extentAfter.toStringAsFixed(1)}})';
  }
}
