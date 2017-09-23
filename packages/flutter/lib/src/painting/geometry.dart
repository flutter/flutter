// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'basic_types.dart';

const double _kScreenEdgeMargin = 10.0;

/// Position a box either above or below a target box specified in the global
/// coordinate system.
///
/// The target box is specified by `size` and `target` and the box being
/// positioned is specified by `childSize`. `verticalOffset` is the amount of
/// vertical distance between the boxes.
///
/// Used by [Tooltip] to position a tooltip relative to its parent.
///
/// The arguments must not be null.
Offset positionDependentBox({
  @required Size size,
  @required Size childSize,
  @required Offset target,
  @required double verticalOffset,
  @required bool preferBelow,
}) {
  assert(size != null);
  assert(childSize != null);
  assert(target != null);
  assert(verticalOffset != null);
  assert(preferBelow != null);
  // VERTICAL DIRECTION
  final bool fitsBelow = target.dy + verticalOffset + childSize.height <= size.height - _kScreenEdgeMargin;
  final bool fitsAbove = target.dy - verticalOffset - childSize.height >= _kScreenEdgeMargin;
  final bool tooltipBelow = preferBelow ? fitsBelow || !fitsAbove : !(fitsAbove || !fitsBelow);
  double y;
  if (tooltipBelow)
    y = math.min(target.dy + verticalOffset, size.height - _kScreenEdgeMargin);
  else
    y = math.max(target.dy - verticalOffset - childSize.height, _kScreenEdgeMargin);
  // HORIZONTAL DIRECTION
  final double normalizedTargetX = target.dx.clamp(_kScreenEdgeMargin, size.width - _kScreenEdgeMargin);
  double x;
  if (normalizedTargetX < _kScreenEdgeMargin + childSize.width / 2.0) {
    x = _kScreenEdgeMargin;
  } else if (normalizedTargetX > size.width - _kScreenEdgeMargin - childSize.width / 2.0) {
    x = size.width - _kScreenEdgeMargin - childSize.width;
  } else {
    x = normalizedTargetX - childSize.width / 2.0;
  }
  return new Offset(x, y);
}
