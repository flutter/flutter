// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'basic_types.dart';
import 'border_radius.dart';
import 'borders.dart';
import 'edge_insets.dart';

/// A rectangular border with flattened or "beveled" corners.
///
/// The line segments that connect the rectangle's four sides will
/// begin and at locations offset by the corresponding border radius,
/// but not farther than the side's center. If all the border radii
/// exceed the sides' half widths/heights the resulting shape is
/// diamond made by connecting the centers of the sides.
class BeveledRectangleBorder extends ShapeBorder {
  /// Creates a border like a [RoundedRectangleBorder] except that the corners
  /// are joined by straight lines instead of arcs.
  ///
  /// The arguments must not be null.
  const BeveledRectangleBorder({
    this.side = BorderSide.none,
    this.borderRadius = BorderRadius.zero,
  }) : assert(side != null),
       assert(borderRadius != null);

  /// The style of this border.
  final BorderSide side;

  /// The radii for each corner.
  ///
  /// Each corner [Radius] defines the endpoints of a line segment that
  /// spans the corner. The endpoints are located in the same place as
  /// they would be for [RoundedRectangleBorder], but they're connected
  /// by a straight line instead of an arc.
  ///
  /// Negative radius values are clamped to 0.0 by [getInnerPath] and
  /// [getOuterPath].
  final BorderRadiusGeometry borderRadius;

  @override
  EdgeInsetsGeometry get dimensions {
    return EdgeInsets.all(side.width);
  }

  @override
  ShapeBorder scale(double t) {
    return BeveledRectangleBorder(
      side: side.scale(t),
      borderRadius: borderRadius * t,
    );
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    assert(t != null);
    if (a is BeveledRectangleBorder) {
      return BeveledRectangleBorder(
        side: BorderSide.lerp(a.side, side, t),
        borderRadius: BorderRadiusGeometry.lerp(a.borderRadius, borderRadius, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    assert(t != null);
    if (b is BeveledRectangleBorder) {
      return BeveledRectangleBorder(
        side: BorderSide.lerp(side, b.side, t),
        borderRadius: BorderRadiusGeometry.lerp(borderRadius, b.borderRadius, t),
      );
    }
    return super.lerpTo(b, t);
  }

  Path _getPath(RRect rrect) {
    final Offset centerLeft = Offset(rrect.left, rrect.center.dy);
    final Offset centerRight = Offset(rrect.right, rrect.center.dy);
    final Offset centerTop = Offset(rrect.center.dx, rrect.top);
    final Offset centerBottom = Offset(rrect.center.dx, rrect.bottom);

    final double tlRadiusX = math.max(0.0, rrect.tlRadiusX);
    final double tlRadiusY = math.max(0.0, rrect.tlRadiusY);
    final double trRadiusX = math.max(0.0, rrect.trRadiusX);
    final double trRadiusY = math.max(0.0, rrect.trRadiusY);
    final double blRadiusX = math.max(0.0, rrect.blRadiusX);
    final double blRadiusY = math.max(0.0, rrect.blRadiusY);
    final double brRadiusX = math.max(0.0, rrect.brRadiusX);
    final double brRadiusY = math.max(0.0, rrect.brRadiusY);

    final List<Offset> vertices = <Offset>[
      Offset(rrect.left, math.min(centerLeft.dy, rrect.top + tlRadiusY)),
      Offset(math.min(centerTop.dx, rrect.left + tlRadiusX), rrect.top),
      Offset(math.max(centerTop.dx, rrect.right -trRadiusX), rrect.top),
      Offset(rrect.right, math.min(centerRight.dy, rrect.top + trRadiusY)),
      Offset(rrect.right, math.max(centerRight.dy, rrect.bottom - brRadiusY)),
      Offset(math.max(centerBottom.dx, rrect.right - brRadiusX), rrect.bottom),
      Offset(math.min(centerBottom.dx, rrect.left + blRadiusX), rrect.bottom),
      Offset(rrect.left, math.max(centerLeft.dy, rrect.bottom  - blRadiusY)),
    ];

    return Path()..addPolygon(vertices, true);
  }

  @override
  Path getInnerPath(Rect rect, { TextDirection textDirection }) {
    return _getPath(borderRadius.resolve(textDirection).toRRect(rect).deflate(side.width));
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection textDirection }) {
    return _getPath(borderRadius.resolve(textDirection).toRRect(rect));
  }

  @override
  void paint(Canvas canvas, Rect rect, { TextDirection textDirection }) {
    if (rect.isEmpty)
      return;
    switch (side.style) {
      case BorderStyle.none:
        break;
      case BorderStyle.solid:
      final Path path = getOuterPath(rect, textDirection: textDirection)
          ..addPath(getInnerPath(rect, textDirection: textDirection), Offset.zero);
        canvas.drawPath(path, side.toPaint());
        break;
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (runtimeType != other.runtimeType)
      return false;
    final BeveledRectangleBorder typedOther = other;
    return side == typedOther.side
        && borderRadius == typedOther.borderRadius;
  }

  @override
  int get hashCode => hashValues(side, borderRadius);

  @override
  String toString() {
    return '$runtimeType($side, $borderRadius)';
  }
}
