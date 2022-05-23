// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show lerpDouble;

import 'package:flutter/foundation.dart';

import 'borders.dart';
import 'circle_border.dart';

/// A border that fits an elliptical shape.
///
/// Typically used with [ShapeDecoration] to draw an oval.
/// Instead of centering the [Border] to a square, like [CircleBorder],
/// it fills the available space, such that it touches the edges of the box.
/// There is no difference between `CircleBorder(ovalness = 1.0)` and `OvalBorder()`.
/// [OvalBorder] works as an alias for users to discover this feature.
///
/// See also:
///
///  * [CircleBorder], which draws a circle, centering when the box is rectangular.
///  * [Border], which, when used with [BoxDecoration], can also describe an oval.
class OvalBorder extends CircleBorder {
  /// Create an oval border.
  const OvalBorder({ super.side, super.ovalness = 1.0});

  @override
  ShapeBorder scale(double t) => OvalBorder(side: side.scale(t), ovalness: ovalness);

  @override
  OvalBorder copyWith({ BorderSide? side, double? ovalness }) {
    return OvalBorder(side: side ?? this.side, ovalness: ovalness ?? this.ovalness);
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is CircleBorder) {
      return OvalBorder(
        side: BorderSide.lerp(a.side, side, t),
        ovalness: ui.lerpDouble(a.ovalness, ovalness, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  String toString() {
    if (ovalness != 1.0) {
      return '${objectRuntimeType(this, 'OvalBorder')}($side, ovalness: $ovalness)';
    }
    return '${objectRuntimeType(this, 'OvalBorder')}($side)';
  }
}
