// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

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
/// In the event that the height or width of the bounding rectangle is less than
/// 2x its radius, the curve radius will become smaller to keep the shape from
/// becoming a lozenge.
///
/// {@tool sample}
/// ```dart
/// Widget build(BuildContext context) {
///   return Material(
///     shape: ContinuousStadiumBorder(
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
/// * [ContinuousRectangleBorder] which creates a rectangle whose 4 edges have
///   a continuous transition into each of its four corners.
class ContinuousStadiumBorder extends ShapeBorder {
  /// Creates a Continuous Stadium Border.
  ///
  /// The [side], and [borderRadius] arguments must not be null.
  const ContinuousStadiumBorder({
    this.side = BorderSide.none,
  }) : assert(side != null);

  /// The style of this border.
  ///
  /// By default this value is [BorderSide.none]. It also must not be null.
  final BorderSide side;

  Path _getPath(Rect rect) {
    // The radius multiplier where the resulting shape will perfectly concave at
    // with a height and width of any value.
    const double maxMultiplier = 3.0573;

    // The multiplier of the radius in comparison to the smallest edge length
    // used to describe the minimum radius for this shape.
    const double dynamicShapeMinMultiplier = 1 / maxMultiplier;

    // The maximum aspect ratio of the width and height of the given rect before
    // clamping on one dimension will occur.
    const double maxAspectRatio = 1 - dynamicShapeMinMultiplier;

    final double rectWidth = rect.width;
    final double rectHeight = rect.height;
    final bool widthLessThanHeight = rectWidth < rectHeight;
    final double width = widthLessThanHeight ? rectWidth.clamp(0.0, maxAspectRatio * rectHeight) : rectWidth;
    final double height = widthLessThanHeight ? rectHeight : rectHeight.clamp(0.0, maxAspectRatio * rectWidth);
    final double centerX = rect.center.dx;
    final double centerY = rect.center.dy;
    final double originX = centerX - width / 2;
    final double originY = centerY - height / 2;
    final double minDimension = math.min(width, height);
    final double radius = minDimension * dynamicShapeMinMultiplier;
    final double limitedRadius = math.min(radius, minDimension * dynamicShapeMinMultiplier);

    // These equations give the x and y values for each of the 8 mid and corner
    // points on a rectangle.
    double leftX(double x) { return centerX + x * limitedRadius - width / 2; }
    double rightX(double x) { return centerX - x * limitedRadius + width / 2; }
    double topY(double y) { return centerY + y * limitedRadius - height / 2; }
    double bottomY(double y) { return centerY - y * limitedRadius + height / 2; }
    double bottomMidY(double y) { return originY + height - y * limitedRadius; }
    double leftMidX(double x) { return originX + x * height; }
    double rightMidX(double x) { return originX + width - x * limitedRadius; }

    // The secondary super elliptical shape where there are only 2 straight edges
    // and two 180º curves. The width is greater than the height. Approximately
    // renders a super ellipse with an n value of 2.
    Path roundedRectHorizontal () {
      return Path()
        ..moveTo(leftX(2.00593972), topY(0))
        ..lineTo(originX + width - 1.52866483 * radius, originY)
        ..cubicTo(rightX(1.63527834), topY(0),
            rightX(1.29884040), topY(0),
            rightX(0.99544263), topY(0.10012127))
        ..lineTo(rightX(0.93667978), topY(0.11451437))
        ..cubicTo(rightX(0.37430558), topY(0.31920183),
            rightX(0.00000051), topY(0.85376567),
            rightX(0.00000051), topY(1.45223188))
        ..cubicTo(rightMidX(0), centerY,
            rightMidX(0), centerY,
            rightMidX(0), centerY)
        ..lineTo(rightMidX(0), centerY)
        ..cubicTo(rightMidX(0), centerY,
            rightMidX(0), centerY,
            rightMidX(0), centerY)
        ..lineTo(rightX(0), bottomY(1.45223165))
        ..cubicTo(rightX(0), bottomY(0.85376561),
            rightX(0.37430558), bottomY(0.31920174),
            rightX(0.93667978), bottomY(0.11451438))
        ..cubicTo(rightX(1.29884040), bottomY(0),
            rightX(1.63527834), bottomY(0),
            rightX(2.30815363), bottomY(0))
        ..lineTo(originX + 1.52866483 * radius, originY + height)
        ..cubicTo(leftX(1.63527822), bottomY(0),
            leftX(1.29884040), bottomY(0),
            leftX(0.99544257), bottomY(0.10012124))
        ..lineTo(leftX(0.93667972), bottomY(0.11451438))
        ..cubicTo(leftX(0.37430549), bottomY(0.31920174),
            leftX(-0.00000007), bottomY(0.85376561),
            leftX(-0.00000001), bottomY(1.45223176))
        ..cubicTo(leftMidX(0), centerY,
            leftMidX(0), centerY,
            leftMidX(0), centerY)
        ..lineTo(leftMidX(0), centerY)
        ..cubicTo(leftMidX(0), centerY,
            leftMidX(0), centerY,
            leftMidX(0), centerY)
        ..lineTo(leftX(-0.00000001), topY(1.45223153))
        ..cubicTo(leftX(0.00000004), topY(0.85376537),
            leftX(0.37430561), topY(0.31920177),
            leftX(0.93667978), topY(0.11451436))
        ..cubicTo(leftX(1.29884040), topY(0),
            leftX(1.63527822), topY(0),
            leftX(2.30815363), topY(0))
        ..lineTo(originX + 1.52866483 * radius, originY)
        ..lineTo(leftX(2.00593972), topY(0))
        ..close();
    }

    // The secondary super elliptical shape where there are only 2 straight edges
    // and two 180º curves. The height is greater than the width. Approximately
    // renders a super ellipse with an n value of 2.
    Path roundedRectVertical () {
      return Path()
        ..moveTo(centerX, topY(0))
        ..lineTo(centerX, topY(0))
        ..cubicTo(centerX, topY(0),
            centerX, topY(0),
            centerX, topY(0))
        ..lineTo(rightX(1.45223153), topY(0))
        ..cubicTo(rightX(0.85376573), topY(0.00000001),
            rightX(0.31920189), topY(0.37430537),
            rightX(0.11451442), topY(0.93667936))
        ..cubicTo(rightX(0), topY(1.29884040),
            rightX(0), topY(1.63527822),
            rightX(0), topY(2.30815387))
        ..lineTo(originX + width, originY + height - 1.52866483 * radius)
        ..cubicTo(rightX(0), bottomY(1.63527822),
            rightX(0), bottomY(1.29884028),
            rightX(0.10012137), bottomY(0.99544269))
        ..lineTo(rightX(0.11451442), bottomY(0.93667972))
        ..cubicTo(rightX(0.31920189), bottomY(0.37430552),
            rightX(0.85376549), bottomY(0),
            rightX(1.45223165), bottomY(0))
        ..cubicTo(centerX, bottomMidY(0),
            centerX, bottomMidY(0),
            centerX, bottomMidY(0))
        ..lineTo(centerX, bottomMidY(0))
        ..cubicTo(centerX, bottomMidY(0),
            centerX, bottomMidY(0),
            centerX, bottomMidY(0))
        ..lineTo(leftX(1.45223141), bottomY(0))
        ..cubicTo(leftX(0.85376543), bottomY(0),
            leftX(0.31920192), bottomY(0.37430552),
            leftX(0.11451446), bottomY(0.93667972))
        ..cubicTo(leftX(0), bottomY(1.29884028),
            leftX(0), bottomY(1.63527822),
            leftX(0), bottomY(2.30815387))
        ..lineTo(originX, originY + 1.52866483 * radius)
        ..cubicTo(leftX(0), topY(1.63527822),
            leftX(0), topY(1.29884040),
            leftX(0.10012126), topY(0.99544257))
        ..lineTo(leftX(0.11451443), topY(0.93667966))
        ..cubicTo(leftX(0.31920189), topY(0.37430552),
            leftX(0.85376549), topY(0),
            leftX(1.45223153), topY(0))
        ..cubicTo(centerX, topY(0),
            centerX, topY(0),
            centerX, topY(0))
        ..lineTo(centerX, topY(0))
        ..close();
    }

    return width > maxMultiplier * radius ? roundedRectHorizontal() : roundedRectVertical();
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
    return ContinuousStadiumBorder(
      side: side.scale(t),
    );
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    assert(t != null);
    if (a is ContinuousStadiumBorder) {
      return ContinuousStadiumBorder(
        side: BorderSide.lerp(a.side, side, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    assert(t != null);
    if (b is ContinuousStadiumBorder) {
      return ContinuousStadiumBorder(
        side: BorderSide.lerp(side, b.side, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  bool operator == (dynamic other) {
    if (runtimeType != other.runtimeType)
      return false;
    final ContinuousStadiumBorder typedOther = other;
    return side == typedOther.side;
  }

  @override
  int get hashCode => side.hashCode;

  @override
  String toString() {
    return '$runtimeType($side)';
  }
}