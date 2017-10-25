// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic_types.dart';
import 'borders.dart';
import 'edge_insets.dart';

/// A border that fits a stadium-shaped border (a box with semicircles on the ends)
/// within the rectangle of the widget it is applied to.
///
/// Typically used with [ShapeDecoration] to draw a stadium border.
///
/// If the rectangle is taller than it is wide, then the semicircles will be on the
/// top and bottom, and on the left and right otherwise.
///
/// See also:
///
///  * [BorderSide], which is used to describe the border of the stadium.
class StadiumBorder extends ShapeBorder {
  /// Create a stadium border.
  ///
  /// The [side] argument must not be null.
  const StadiumBorder([this.side = BorderSide.none])
      : assert(side != null);

  /// The style of this border.
  final BorderSide side;

  @override
  EdgeInsetsGeometry get dimensions {
    return new EdgeInsets.all(side.width);
  }

  @override
  ShapeBorder scale(double t) => new StadiumBorder(side.scale(t));

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    if (a is StadiumBorder)
      return new StadiumBorder(BorderSide.lerp(a.side, side, t));
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    if (b is StadiumBorder)
      return new StadiumBorder(BorderSide.lerp(side, b.side, t));
    return super.lerpTo(b, t);
  }

  @override
  Path getInnerPath(Rect rect, { TextDirection textDirection }) {
    final Radius radius = new Radius.circular(rect.shortestSide - side.width);
    return new Path()
      ..addRRect(new RRect.fromRectAndRadius(rect, radius));
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection textDirection }) {
    final Radius radius = new Radius.circular(rect.shortestSide);
    return new Path()
      ..addRRect(new RRect.fromRectAndRadius(rect, radius));
  }

  @override
  void paint(Canvas canvas, Rect rect, { TextDirection textDirection }) {
    switch (side.style) {
      case BorderStyle.none:
        break;
      case BorderStyle.solid:
        final Radius radius = new Radius.circular(rect.shortestSide);
        canvas.drawRRect(new RRect.fromRectAndRadius(rect, radius), side.toPaint());
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (runtimeType != other.runtimeType)
      return false;
    final StadiumBorder typedOther = other;
    return side == typedOther.side;
  }

  @override
  int get hashCode => side.hashCode;

  @override
  String toString() {
    return '$runtimeType($side)';
  }
}
