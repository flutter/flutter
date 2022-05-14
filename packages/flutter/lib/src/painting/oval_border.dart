// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic_types.dart';
import 'borders.dart';
import 'edge_insets.dart';

/// A border that fits an ellipitical shape.
///
/// Typically used with [ShapeDecoration] to draw an oval.
/// Instead of centering the [Border] to a square, like [CircleBorder],
/// it fills the available space, like a "flattened circle".
///
/// See also:
///
///  * [CircleBorder], which draws a circle based on a rectangle's size.
///  * [BorderSide], which is used to describe each side of the box.
///  * [Border], which, when used with [BoxDecoration], can also
///    describe a circle.
class OvalBorder extends OutlinedBorder {
  /// Create an oval border.
  ///
  /// The [side] argument must not be null.
  const OvalBorder({ super.side }) : assert(side != null);

  @override
  EdgeInsetsGeometry get dimensions {
    return EdgeInsets.all(side.width);
  }

  @override
  ShapeBorder scale(double t) => OvalBorder(side: side.scale(t));

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is OvalBorder)
      return OvalBorder(side: BorderSide.lerp(a.side, side, t));
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is OvalBorder)
      return OvalBorder(side: BorderSide.lerp(side, b.side, t));
    return super.lerpTo(b, t);
  }

  @override
  Path getInnerPath(Rect rect, { TextDirection? textDirection }) {
    return Path()..addOval(rect.deflate(side.width));
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection? textDirection }) {
    return Path()..addOval(rect);
  }

  @override
  OvalBorder copyWith({ BorderSide? side }) {
    return OvalBorder(side: side ?? this.side);
  }

  @override
  void paint(Canvas canvas, Rect rect, { TextDirection? textDirection }) {
    switch (side.style) {
      case BorderStyle.none:
        break;
      case BorderStyle.solid:
        canvas.drawOval(rect.deflate(side.width / 2), side.toPaint());
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is OvalBorder
        && other.side == side;
  }

  @override
  int get hashCode => side.hashCode;

  @override
  String toString() {
    return '${objectRuntimeType(this, 'OvalBorder')}($side)';
  }
}
