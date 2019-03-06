// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'basic_types.dart';
import 'borders.dart';
import 'edge_insets.dart';

/// A stadium border with continuous corners.
///
/// A shape similar to a stadium, but with a smoother transition from
/// each linear edge to its 180º curves. Each 180º curve is approximately half
/// an ellipse.
///
/// In this shape, the curvature of each 180º curve around the length of the arc
/// is approximately a gaussian curve instead of a step function as with a
/// traditional half circle round.
///
/// The ~3 represents twice the ratio (ie. ~3/2) of a corner's declared radius
/// and the actual height and width of pixels that are manipulated to render it.
/// For example, if a rectangle had dimensions 80px x 100px, and a corner radius
/// of 25, in reality ~38 pixels in each dimension would be used to render a
/// corner and so ~76px x ~38px would be used to render both corners on a given
/// side.
///
/// The two 180º arcs will always be positioned on the shorter side of the
/// rectangle like with the traditional [StadiumBorder] shape.
///
/// {@tool sample}
/// ```dart
/// Widget build(BuildContext context) {
///   return Material(
///     color: Colors.blueAccent[400],
///     shape: const ContinuousStadiumBorder(),
///     child: const SizedBox(
///       height: 100.0,
///       width: 200.0,
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// The image below depicts a [ContinuousStadiumBorder] with a width of 200
/// and a height of 100.
///
/// ![](https://flutter.github.io/assets-for-api-docs/assets/painting/Shape.continuous_stadium.png)
///
/// See also:
///
/// * [RoundedRectangleBorder], which is a rectangle whose corners are
///   precisely quarter circles.
/// * [ContinuousRectangleBorder], which is a rectangle whose 4 edges have
///   a continuous transition into each of its four corners.
/// * [StadiumBorder], which is a rectangle with semi-circles on two parallel
///   edges.
class ContinuousStadiumBorder extends ShapeBorder {
  /// Creates a continuous stadium border.
  ///
  /// The [side], argument must not be null.
  const ContinuousStadiumBorder({
    this.side = BorderSide.none,
  }) : assert(side != null);

  /// The style of this border.
  ///
  /// If the border side width is larger than 1/10 the length of the smallest
  /// dimension, the interior shape's corners will no longer resemble those of
  /// the exterior shape. If concentric corners are desired for a stroke width
  /// greater than 1/10 the length of the smallest rectangle dimension, it is
  /// recommended to use a [Stack] widget, placing a smaller
  /// [ContinuousStadiumBorder] with the on top of a
  /// larger one.
  ///
  /// By default this value is [BorderSide.none]. It also must not be null.
  final BorderSide side;

  Path _getPath(Rect rect) {
    // The two 180º arcs will always be positioned on the shorter side of the
    // rectangle like with the traditional stadium border shape.
    final double sideWidth = side.width;

    // The side width that is capped by the smallest dimension of the rectangle.
    // It represents the side width value used to render the stroke.
    final double actualSideWidth = math.min(side.width, math.min(rect.width, rect.height) / 2.0);

    // We need to change the dimensions of the rect in the event that the
    // shape has a side width as the stroke is drawn centered on the border of
    // the shape instead of inside as with the rounded rect and stadium.
    if (sideWidth > 0.0)
      rect = rect.deflate(actualSideWidth / 2.0);

    // The ratio of the declared corner radius to the total affected pixels
    // along each axis to render the corner. For example if the declared radius
    // were 25px then totalAffectedCornerPixelRatio * 25 (~38) pixels would be
    // affected along each axis.
    //
    // It is also the multiplier where the resulting shape will be convex with
    // a height and width of any value. Below this value, noticeable clipping
    // will be seen at large rectangle dimensions.
    //
    // If the shortest side length to radius ratio drops below this value, the
    // radius must be lessened to avoid clipping (ie. concavity) of the shape.
    //
    // This value comes from the website where the other equations and curves
    // were found
    // (https://www.paintcodeapp.com/news/code-for-ios-7-rounded-rectangles).
    const double totalAffectedCornerPixelRatio = 1.52865;

    // The ratio of the radius to the magnitude of pixels on a given side that
    // are used to construct the two corners.
    const double minimalUnclippedSideToCornerRadiusRatio = 2.0 * totalAffectedCornerPixelRatio;

    const double minimalEdgeLengthSideToCornerRadiusRatio = 1.0 / minimalUnclippedSideToCornerRadiusRatio;

    // The maximum aspect ratio of the width and height of the given rect before
    // clamping on one dimension will occur. Roughly 0.68.
    const double maxEdgeLengthAspectRatio = 1.0 - minimalEdgeLengthSideToCornerRadiusRatio;

    final double rectWidth = rect.width;
    final double rectHeight = rect.height;
    final bool widthLessThanHeight = rectWidth < rectHeight;
    final double width =
      widthLessThanHeight ?
        rectWidth.clamp(
          0.0,
          maxEdgeLengthAspectRatio * (rectHeight + actualSideWidth) - actualSideWidth
        ) : rectWidth;
    final double height =
      widthLessThanHeight ?
        rectHeight :
        rectHeight.clamp(
          0.0,
          maxEdgeLengthAspectRatio * (rectWidth + actualSideWidth) - actualSideWidth
        );

    final double centerX = rect.center.dx;
    final double centerY = rect.center.dy;
    final double originX = centerX - width / 2.0;
    final double originY = centerY - height / 2.0;
    final double minDimension = math.min(width, height);
    final double radius = minDimension * minimalEdgeLengthSideToCornerRadiusRatio;

    // These equations give the x and y values for each of the 8 mid and corner
    // points on a rectangle.
    //
    // For example, leftX(k) will give the x value on the left side of the shape
    // that is precisely `k` distance from the left edge of the shape for the
    // predetermined 'limitedRadius' value.
    double leftX(double x) { return centerX + x * radius - width / 2; }
    double rightX(double x) { return centerX - x * radius + width / 2; }
    double topY(double y) { return centerY + y * radius - height / 2; }
    double bottomY(double y) { return centerY - y * radius + height / 2; }
    double bottomMidY(double y) { return originY + height - y * radius; }
    double leftMidX(double x) { return originX + x * height; }
    double rightMidX(double x) { return originX + width - x * radius; }

    // An elliptical shape with 2 straight edges and two 180º curves. The width
    // is greater than the height.
    //
    // Code was inspired from the code listed on this website:
    // https://www.paintcodeapp.com/news/code-for-ios-7-rounded-rectangles
    //
    // The shape is drawn from the top midpoint to the upper right hand corner
    // in a clockwise fashion around to the upper left hand corner.
    Path bezierStadiumHorizontal () {
      return Path()
        ..moveTo(leftX(2.00593972), topY(0.0))
        ..lineTo(originX + width - 1.52866483 * radius, originY)
        ..cubicTo(rightX(1.63527834), topY(0.0),
            rightX(1.29884040), topY(0.0),
            rightX(0.99544263), topY(0.10012127))
        ..lineTo(rightX(0.93667978), topY(0.11451437))
        ..cubicTo(rightX(0.37430558), topY(0.31920183),
            rightX(0.00000051), topY(0.85376567),
            rightX(0.00000051), topY(1.45223188))
        ..cubicTo(rightMidX(0.0), centerY,
            rightMidX(0.0), centerY,
            rightMidX(0.0), centerY)
        ..lineTo(rightMidX(0.0), centerY)
        ..cubicTo(rightMidX(0.0), centerY,
            rightMidX(0.0), centerY,
            rightMidX(0.0), centerY)
        ..lineTo(rightX(0.0), bottomY(1.45223165))
        ..cubicTo(rightX(0.0), bottomY(0.85376561),
            rightX(0.37430558), bottomY(0.31920174),
            rightX(0.93667978), bottomY(0.11451438))
        ..cubicTo(rightX(1.29884040), bottomY(0.0),
            rightX(1.63527834), bottomY(0.0),
            rightX(2.30815363), bottomY(0.0))
        ..lineTo(originX + 1.52866483 * radius, originY + height)
        ..cubicTo(leftX(1.63527822), bottomY(0.0),
            leftX(1.29884040), bottomY(0.0),
            leftX(0.99544257), bottomY(0.10012124))
        ..lineTo(leftX(0.93667972), bottomY(0.11451438))
        ..cubicTo(leftX(0.37430549), bottomY(0.31920174),
            leftX(-0.00000007), bottomY(0.85376561),
            leftX(-0.00000001), bottomY(1.45223176))
        ..cubicTo(leftMidX(0.0), centerY,
            leftMidX(0.0), centerY,
            leftMidX(0.0), centerY)
        ..lineTo(leftMidX(0.0), centerY)
        ..cubicTo(leftMidX(0.0), centerY,
            leftMidX(0.0), centerY,
            leftMidX(0.0), centerY)
        ..lineTo(leftX(-0.00000001), topY(1.45223153))
        ..cubicTo(leftX(0.00000004), topY(0.85376537),
            leftX(0.37430561), topY(0.31920177),
            leftX(0.93667978), topY(0.11451436))
        ..cubicTo(leftX(1.29884040), topY(0.0),
            leftX(1.63527822), topY(0.0),
            leftX(2.30815363), topY(0.0))
        ..lineTo(leftX(2.00593972), topY(0.0))
        ..close();
    }

    // An elliptical shape which has 2 straight edges and two 180º curves. The
    // height is greater than the width.
    //
    // Code was inspired from the code listed on this website:
    // https://www.paintcodeapp.com/news/code-for-ios-7-rounded-rectangles
    //
    // The shape is drawn from the top midpoint to the upper right hand corner
    // in a clockwise fashion around to the upper left hand corner.
    Path bezierStadiumVertical () {
      return Path()
        ..moveTo(centerX, topY(0.0))
        ..lineTo(centerX, topY(0.0))
        ..cubicTo(centerX, topY(0.0),
            centerX, topY(0.0),
            centerX, topY(0.0))
        ..lineTo(rightX(1.45223153), topY(0.0))
        ..cubicTo(rightX(0.85376573), topY(0.00000001),
            rightX(0.31920189), topY(0.37430537),
            rightX(0.11451442), topY(0.93667936))
        ..cubicTo(rightX(0.0), topY(1.29884040),
            rightX(0.0), topY(1.63527822),
            rightX(0.0), topY(2.30815387))
        ..lineTo(originX + width, originY + height - 1.52866483 * radius)
        ..cubicTo(rightX(0.0), bottomY(1.63527822),
            rightX(0.0), bottomY(1.29884028),
            rightX(0.10012137), bottomY(0.99544269))
        ..lineTo(rightX(0.11451442), bottomY(0.93667972))
        ..cubicTo(rightX(0.31920189), bottomY(0.37430552),
            rightX(0.85376549), bottomY(0.0),
            rightX(1.45223165), bottomY(0.0))
        ..cubicTo(centerX, bottomMidY(0.0),
            centerX, bottomMidY(0.0),
            centerX, bottomMidY(0.0))
        ..lineTo(centerX, bottomMidY(0.0))
        ..cubicTo(centerX, bottomMidY(0.0),
            centerX, bottomMidY(0.0),
            centerX, bottomMidY(0.0))
        ..lineTo(leftX(1.45223141), bottomY(0.0))
        ..cubicTo(leftX(0.85376543), bottomY(0.0),
            leftX(0.31920192), bottomY(0.37430552),
            leftX(0.11451446), bottomY(0.93667972))
        ..cubicTo(leftX(0.0), bottomY(1.29884028),
            leftX(0.0), bottomY(1.63527822),
            leftX(0.0), bottomY(2.30815387))
        ..lineTo(originX, originY + 1.52866483 * radius)
        ..cubicTo(leftX(0.0), topY(1.63527822),
            leftX(0.0), topY(1.29884040),
            leftX(0.10012126), topY(0.99544257))
        ..lineTo(leftX(0.11451443), topY(0.93667966))
        ..cubicTo(leftX(0.31920189), topY(0.37430552),
            leftX(0.85376549), topY(0.0),
            leftX(1.45223153), topY(0.0))
        ..cubicTo(centerX, topY(0.0),
            centerX, topY(0.0),
            centerX, topY(0.0))
        ..lineTo(centerX, topY(0.0))
        ..close();
    }

    return width > minimalUnclippedSideToCornerRadiusRatio * radius ? bezierStadiumHorizontal() : bezierStadiumVertical();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {
    if (rect.isEmpty)
      return;
    switch (side.style) {
      case BorderStyle.none:
        break;
      case BorderStyle.solid:
        final double width = side.width;
        if (width != 0.0) {
          final Path path = getOuterPath(rect, textDirection: textDirection);
          final Paint paint = side.toPaint();
          paint.strokeWidth = math.min(width, math.min(rect.width, rect.height) / 2);
          paint.strokeJoin = StrokeJoin.round;
          canvas.drawPath(path, paint);
        }
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
  bool operator ==(dynamic other) {
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