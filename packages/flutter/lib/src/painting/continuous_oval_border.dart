// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'basic_types.dart';
import 'borders.dart';
import 'edge_insets.dart';

/// Creates a continuous stadium shape.
///
/// A shape similar to a stadium, but with a smoother transition from
/// each linear edge to its 180º curves.
///
/// In this shape, the curvature of each 180º curve over the arc is
/// approximately a gaussian curve instead of a step function as with a
/// traditional half circle round.
///
/// In the event that this shape's height is equal to its width, this shape will
/// appear to be a circle. Increasing the height or width of the shape will then
/// allow for a smooth transition into a continuous stadium-esque shape.
///
/// {@tool sample}
/// ```dart
/// Widget build(BuildContext context) {
///   return Material(
///     shape: ContinuousOvalBorder(
///       borderRadius: 28.0,
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
/// * [RoundedRectangleBorder] which creates a rectangle whose corners are
///   precisely quarter circles.
class ContinuousOvalBorder extends ShapeBorder {
  /// Creates a Continuous Cornered Rectangle Border.
  ///
  /// The [side] and [borderRadius] arguments must not be null.
  const ContinuousOvalBorder({
    this.side = BorderSide.none,
  }) : assert(side != null);

  /// The style of this border.
  ///
  /// By default this value is [BorderSide.none]. It also must not be null.
  final BorderSide side;

  Path _getPath(Rect rect) {
    // The multiplier of the radius in comparison to the smallest edge length
    // used to describe the minimum radius for the dynamic shape option.
    const double dynamicShapeMinMultiplier = 0.32708;

    final double width = rect.width;
    final double height = rect.height;
    final double centerX = rect.center.dx;
    final double centerY = rect.center.dy;
    final double originX = centerX - width / 2;
    final double originY = centerY - height / 2;
    final double minDimension = math.min(rect.width, rect.height);
    final double radius = minDimension * dynamicShapeMinMultiplier;

    final double limitedRadius = math.min(radius, minDimension * dynamicShapeMinMultiplier);

    // These equations give the x and y values for each of the 8 mid and corner
    // points on a rectangle.
    double leftX(double x) { return centerX + x * limitedRadius - width / 2; }
    double rightX(double x) { return centerX - x * limitedRadius + width / 2; }
    double topY(double y) { return centerY + y * limitedRadius - height / 2; }
    double bottomY(double y) { return centerY - y * limitedRadius + height / 2; }
    double topMidY(double y) { return originY + y * width; }
    double leftMidX(double x) { return originX + x * height; }
    double rightMidX(double x) { return originX + width - x * limitedRadius; }

    // The third super elliptical shape where there are only 2 straight edges
    // and two 180º curves. The height is greater than the width. Approximately
    // renders a super ellipse with an n value of 2. Only used in cases where
    // the width:height aspect ratio is close to 1.
    Path roundedRectVertical () {
      return Path()
        ..moveTo(centerX, topMidY(0))
        ..lineTo(centerX, topMidY(0))
        ..cubicTo(centerX, topMidY(0),
            centerX, topMidY(0),
            centerX, topMidY(0))
        ..lineTo(centerX, topMidY(0))
        ..cubicTo(rightX(0.68440646), topY(0.00000001),
            rightX(0), topY(0.68440658),
            rightX(0), topY(1.52866483))
        ..cubicTo(rightX(0), topY(1.52866495),
            rightX(0), topY(1.52866495),
            rightX(0), topY(1.52866507))
        ..cubicTo(rightX(0), topY(1.52866483),
            rightX(0), topY(1.52866483),
            rightX(0), topY(1.52866483))
        ..lineTo(rightMidX(0), centerY)
        ..cubicTo(rightX(0), bottomY(1.52866471),
            rightX(0), bottomY(1.52866471),
            rightX(0), bottomY(1.52866471))
        ..lineTo(rightX(0), bottomY(1.52866471))
        ..cubicTo(rightX(0), bottomY(0.68440646),
            rightX(0.68440646), bottomY(0),
            centerX, bottomY(0))
        ..cubicTo(centerX, bottomY(0),
            centerX, bottomY(0),
            centerX, bottomY(0))
        ..cubicTo(centerX, bottomY(0),
            centerX, bottomY(0),
            centerX, bottomY(0))
        ..lineTo(centerX, bottomY(0))
        ..cubicTo(centerX, bottomY(0),
            centerX, bottomY(0),
            centerX, bottomY(0))
        ..lineTo(centerX, bottomY(0))
        ..cubicTo(leftX(0.68440646), bottomY(0),
            leftX(-0.00000004), bottomY(0.68440646),
            leftX(0), bottomY(1.52866471))
        ..cubicTo(leftX(0), bottomY(1.52866471),
            leftX(0), bottomY(1.52866495),
            leftX(0), bottomY(1.52866495))
        ..cubicTo(leftX(0), bottomY(1.52866471),
            leftX(0), bottomY(1.52866471),
            leftX(0), bottomY(1.52866471))
        ..lineTo(leftX(0), centerY)
        ..cubicTo(leftX(0), topY(1.52866483),
            leftX(0), topY(1.52866483),
            leftX(0), topY(1.52866483))
        ..lineTo(leftX(0), topY(1.52866471))
        ..cubicTo(leftX(0.00000007), topY(0.68440652),
            leftX(0.68440658), topY(-0.00000001),
            centerX, topMidY(0))
        ..cubicTo(centerX, topMidY(0),
            centerX, topMidY(0),
            centerX, topMidY(0))
        ..lineTo(centerX, topMidY(0))
        ..close();
    }

    // The third super elliptical shape where there are only 2 straight edges
    // and two 180º curves. The width is greater than the height. Approximately
    // renders a super ellipse with an n value of 2. Only used in cases where
    // the width:height aspect ratio is close to 1.
    Path roundedRectHorizontal () {
      return Path()
        ..moveTo(centerX, topMidY(0))
        ..lineTo(centerX, topMidY(0))
        ..cubicTo(rightX(1.52866495), topY(0),
            rightX(1.52866495), topY(0),
            rightX(1.52866495), topY(0))
        ..lineTo(rightX(1.52866495), topY(0))
        ..cubicTo(rightX(0.68440676), topY(0.00000001),
            rightX(0), topY(0.68440658),
            rightMidX(0), centerY)
        ..cubicTo(rightMidX(0), centerY,
            rightMidX(0), centerY,
            rightMidX(0), centerY)
        ..cubicTo(rightMidX(0), centerY,
            rightMidX(0), centerY,
            rightMidX(0), centerY)
        ..lineTo(rightMidX(0), centerY)
        ..cubicTo(rightMidX(0), centerY,
            rightMidX(0), centerY,
            rightMidX(0), centerY)
        ..lineTo(rightMidX(0), centerY)
        ..cubicTo(rightX(0), bottomY(0.68440652),
            rightX(0.68440676), bottomY(0),
            rightX(1.52866495), bottomY(0))
        ..cubicTo(rightX(1.52866495), bottomY(0),
            rightX(1.52866495), bottomY(0),
            rightX(1.52866495), bottomY(0))
        ..cubicTo(rightX(1.52866495), bottomY(0),
            rightX(1.52866495), bottomY(0),
            rightX(1.52866495), bottomY(0))
        ..lineTo(centerX, bottomY(0))
        ..cubicTo(leftX(1.52866483), bottomY(0),
            leftX(1.52866483), bottomY(0),
            leftX(1.52866483), bottomY(0))
        ..lineTo(leftX(1.52866471), bottomY(0))
        ..cubicTo(leftX(0.68440646), bottomY(0),
            leftX(-0.00000004), bottomY(0.68440676),
            leftMidX(0), centerY)
        ..cubicTo(leftMidX(0), centerY,
            leftMidX(0), centerY,
            leftMidX(0), centerY)
        ..cubicTo(leftMidX(0), centerY,
            leftMidX(0), centerY,
            leftMidX(0), centerY)
        ..lineTo(leftMidX(0), centerY)
        ..cubicTo(leftMidX(0), centerY,
            leftMidX(0), centerY,
            leftMidX(0), centerY)
        ..lineTo(leftMidX(0), centerY)
        ..cubicTo(leftX(0.00000007), topY(0.68440652),
            leftX(0.68440664), topY(-0.00000001),
            leftX(1.52866483), topY(0))
        ..cubicTo(leftX(1.52866483), topY(0),
            leftX(1.52866483), topY(0),
            leftX(1.52866483), topY(0))
        ..lineTo(centerX, topMidY(0))
        ..close();
    }

    return height > width ? roundedRectVertical() : roundedRectHorizontal();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {
    if (rect.isEmpty)
      return;
    switch (side.style) {
      case BorderStyle.none:
        break;
      case BorderStyle.solid:
        final Path path = getOuterPath(rect, textDirection: textDirection);
        final Paint paint = side.toPaint();
        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    return _getPath(rect.deflate(side.width));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    return _getPath(rect);
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) {
    return ContinuousOvalBorder(
      side: side.scale(t),
    );
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    assert(t != null);
    if (a is ContinuousOvalBorder) {
      return ContinuousOvalBorder(
        side: BorderSide.lerp(a.side, side, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    assert(t != null);
    if (b is ContinuousOvalBorder) {
      return ContinuousOvalBorder(
        side: BorderSide.lerp(side, b.side, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  bool operator == (dynamic other) {
    if (runtimeType != other.runtimeType)
      return false;
    final ContinuousOvalBorder typedOther = other;
    return side == typedOther.side;
  }

  @override
  int get hashCode => side.hashCode;

  @override
  String toString() {
    return '$runtimeType($side)';
  }
}