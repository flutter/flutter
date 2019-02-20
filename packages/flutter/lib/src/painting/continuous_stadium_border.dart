// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'basic_types.dart';
import 'borders.dart';
import 'edge_insets.dart';

/// The corner mode for a [ContinuousCornerRectangleBorder].
///
/// Creates a continuous cornered rounded rectangle.
///
/// A shape similar to a rounded rectangle, but with a smoother transition from
/// the sides to the rounded corners.
///
/// The rendered shape roughly approximates that of a super ellipse. In this
/// shape, the curvature of each corner over the arc is approximately a gaussian
/// curve instead of a step function as with a traditional quarter circle round.
/// The rendered rectangle is roughly a super ellipse with an n value of 2.
///
/// In the event that the height or width of the rectangle is less than ~3x its
/// radius, the corner radius will become smaller to keep the shape from
/// becoming a louzenge
///
/// {@tool sample}
/// ```dart
/// Widget build(BuildContext context) {
///   return Material(
///     shape: SuperEllipseRoundedRectangleBorder(
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
class ContinuousStadiumBorder extends ShapeBorder {
  /// Creates a Continuous Cornered Rectangle Border.
  ///
  /// The [side], [mode] and [borderRadius] arguments must not be null.
  const ContinuousStadiumBorder({
    this.side = BorderSide.none,
    this.borderRadius = 1.0,
    this.mode = RoundedRectCornerMode.dynamicShape,
  }) : assert(side != null),
       assert(mode != null),
       assert(borderRadius != null);

  /// The radius for each corner.
  ///
  /// The radius will be clamped to 1 if a value less than 1 is entered as the
  /// radius.
  ///
  /// By default the radius is 1.0. This value must not be null.
  ///
  /// Unlike [RoundedRectangleBorder], there is only a single border radius used
  /// to describe the radius for every corner.
  final double borderRadius;

  /// The style of this border.
  ///
  /// By default this value is [BorderSide.none]. It also must not be null.
  final BorderSide side;

  /// The corner mode of the rectangle.
  ///
  /// Whether or not the shape or radius will by dynamic in the event that the
  /// width or height is smaller than 3x the radius.
  ///
  /// By default, this value is [RoundedRectCornerMode.dynamicShape]. It also
  /// must not be null.
  final RoundedRectCornerMode mode;

  Path _getPath(RRect rrect) {
    // The radius multiplier where the resulting shape will perfectly concave at
    // with a height and width of any value.
    const double maxMultiplier = 3.0573;

    double limitedRadius;
    final double width = rrect.width;
    final double height = rrect.height;
    final double centerX = rrect.center.dx;
    final double centerY = rrect.center.dy;
    final double originX = centerX - width / 2;
    final double originY = centerY - height / 2;
    final double radius = math.max(1, borderRadius);

    // These equations give the x and y values for each of the 8 mid and corner
    // points on a rectangle.
    double leftX(double x) { return centerX + x * limitedRadius - width / 2; }
    double rightX(double x) { return centerX - x * limitedRadius + width / 2; }
    double topY(double y) { return centerY + y * limitedRadius - height / 2; }
    double bottomY(double y) { return centerY - y * limitedRadius + height / 2; }
    double topMidY(double y) { return originY + y * width; }
    double bottomMidY(double y) { return originY + height - y * limitedRadius; }
    double leftMidX(double x) { return originX + x * height; }
    double rightMidX(double x) { return originX + width - x * limitedRadius; }

    // Renders the default super elliptical rounded rect shape where there are
    // 4 straight edges and 4 90º corners. Approximately renders a super ellipse
    // with n value of 5.
    Path roundedRect1 () {
      return Path()
        ..moveTo(leftX(1.52866483), topY(0))
        ..lineTo(rightX(1.52866471), topY(0))
        ..cubicTo(rightX(1.08849323), topY(0),
            rightX(0.86840689), topY(0),
            rightX(0.66993427), topY(0.06549600))
        ..lineTo(rightX(0.63149399), topY(0.07491100))
        ..cubicTo(rightX(0.37282392), topY(0.16905899),
            rightX(0.16906013), topY(0.37282401),
            rightX(0.07491176), topY(0.63149399))
        ..cubicTo(rightX(0), topY(0.86840701),
            rightX(0), topY(1.08849299),
            rightX(0), topY(1.52866483))
        ..lineTo(rightX(0), bottomY(1.52866471))
        ..cubicTo(rightX(0), bottomY(1.08849323),
            rightX(0), bottomY(0.86840689),
            rightX(0.06549600), bottomY(0.66993427))
        ..lineTo(rightX(0.07491100), bottomY(0.63149399))
        ..cubicTo(rightX(0.16905899), bottomY(0.37282392),
            rightX(0.37282401), bottomY(0.16906013),
            rightX(0.63149399), bottomY(0.07491176))
        ..cubicTo(rightX(0.86840701), bottomY(0),
            rightX(1.08849299), bottomY(0),
            rightX(1.52866483), bottomY(0))
        ..lineTo(leftX(1.52866483), bottomY(0))
        ..cubicTo(leftX(1.08849323), bottomY(0),
            leftX(0.86840689), bottomY(0),
            leftX(0.66993427), bottomY(0.06549600))
        ..lineTo(leftX(0.63149399), bottomY(0.07491100))
        ..cubicTo(leftX(0.37282392), bottomY(0.16905899),
            leftX(0.16906013), bottomY(0.37282401),
            leftX(0.07491176), bottomY(0.63149399))
        ..cubicTo(leftX(0), bottomY(0.86840701),
            leftX(0), bottomY(1.08849299),
            leftX(0), bottomY(1.52866483))
        ..lineTo(leftX(0), topY(1.52866471))
        ..cubicTo(leftX(0), topY(1.08849323),
            leftX(0), topY(0.86840689),
            leftX(0.06549600), topY(0.66993427))
        ..lineTo(leftX(0.07491100), topY(0.63149399))
        ..cubicTo(leftX(0.16905899), topY(0.37282392),
            leftX(0.37282401), topY(0.16906013),
            leftX(0.63149399), topY(0.07491176))
        ..cubicTo(leftX(0.86840701), topY(0),
            leftX(1.08849299), topY(0),
            leftX(1.52866483), topY(0))
        ..close();
    }

    // The secondary super elliptical shape where there are only 2 straight edges
    // and two 180º curves. The width is greater than the height. Approximately
    // renders a super ellipse with an n value of 2.
    Path roundedRect2a () {
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
    Path roundedRect2b () {
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

    // The third super elliptical shape where there are only 2 straight edges
    // and two 180º curves. The height is greater than the width. Approximately
    // renders a super ellipse with an n value of 2. Only used in cases where
    // the width:height aspect ratio is close to 1.
    Path roundedRect3a () {
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
    Path roundedRect3b () {
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


    // The multiplier of the radius in comparison to the smallest edge length
    // used to describe the minimum radius for the dynamic shape option.
    const double dynamicShapeMinMultiplier = 0.32708;

    // The multiplier of the radius in comparison to the smallest edge length
    // used to describe the minimum radius for the dynamic radius round option.
    const double dynamicRadiusMinMultiplier = 2.0;

    // The edge length at which the corner radius multiplier must be at its
    // maximum so as to maintain a the appearance of a perfectly concave,
    // non-lozenge shape.
    const double minRadiusEdgeLength = 200.0;

    // The maximum difference of the aspect ratio of the width and height of
    // the rectangle and 1 before shape 3 is rendered.
    const double maxAspectRatioDifferenceForShape2 = 0.3;

    switch(mode) {
      case RoundedRectCornerMode.dynamicShape:
        final double aspectRatio = width / height;
        final bool aspectRatioInRangeForShape2 = (aspectRatio - 1).abs() > maxAspectRatioDifferenceForShape2;
        limitedRadius = math.min(radius, math.min(rrect.width, rrect.height) * dynamicShapeMinMultiplier);
        if (width > maxMultiplier * radius && height > maxMultiplier * radius)
          return roundedRect1();
        else if (width > maxMultiplier * radius || (width > height && aspectRatioInRangeForShape2))
          return roundedRect2a();
        else if (height > maxMultiplier * radius || (height > width && aspectRatioInRangeForShape2))
          return roundedRect2b();
        else if (height > width)
          return roundedRect3a();
        return roundedRect3b();

      case RoundedRectCornerMode.dynamicRadius:
        final double min = math.min(rrect.width, rrect.height);

        // As the minimum side edge length (where the round is occurring)
        // approaches 0, the limitedRadius approaches 2.0 so as to maximize
        // roundness. As the edge length approaches 200, the limitedRadius
        // approaches ~3 –- the multiplier of the radius value where the
        // resulting shape is perfectly concave at any dimension.
        final double multiplier = ui.lerpDouble(
          dynamicRadiusMinMultiplier,
          maxMultiplier,
          min / minRadiusEdgeLength
        );
        limitedRadius = math.min(radius, min / multiplier);
        return roundedRect1();
    }
    return Path();
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
    return _getPath(RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)).deflate(side.width));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    return _getPath(RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)));
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) {
    return ContinuousStadiumBorder(
      side: side.scale(t),
      borderRadius: borderRadius * t,
      mode: mode,
    );
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    assert(t != null);
    if (a is ContinuousStadiumBorder) {
      return ContinuousStadiumBorder(
        side: BorderSide.lerp(a.side, side, t),
        borderRadius: ui.lerpDouble(a.borderRadius, borderRadius, t),
        mode: a.mode,
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
        borderRadius: ui.lerpDouble(borderRadius, b.borderRadius, t),
        mode: b.mode,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  bool operator == (dynamic other) {
    if (runtimeType != other.runtimeType)
      return false;
    final ContinuousStadiumBorder typedOther = other;
    return side == typedOther.side && borderRadius == typedOther.borderRadius &&
           typedOther.mode == mode;
  }

  @override
  int get hashCode => hashValues(side, borderRadius, mode);

  @override
  String toString() {
    return '$runtimeType($side, $borderRadius, $mode)';
  }
}