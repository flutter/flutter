// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'basic_types.dart';
import 'borders.dart';
import 'edge_insets.dart';

/// Creates a continuous cornered rounded rectangle.
///
/// A shape similar to a rounded rectangle, but with a smoother transition from
/// the sides to the rounded corners.
///
/// The rendered shape roughly approximates that of a super ellipse. In this
/// shape, the curvature of each corner over the arc is approximately a gaussian
/// curve instead of a step function as with a traditional quarter circle round.
/// The rendered rectangle in dynamic radius mode is roughly a super ellipse with
/// an n value of 5.
///
/// In an attempt to keep the shape of the rectangle the same regardless of its
/// dimension, the radius will automatically be lessened to maximize the
/// roundness of the resulting rectangle if its width or height is less than
/// ~3x the radius.
///
/// This option is best used in scenarios where a rectangle is not static and
/// will be animated between various different dimensions.
///
/// This shape will always have 4 linear edges and 4 90º curves. However, at
/// small extent values (ie.  <20 lpx), the rendered shape will appear to have
/// just 2 edges and 2 180º curves.
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
class ContinuousRectangleBorder extends ShapeBorder {
  /// Creates a Continuous Cornered Rectangle Border.
  ///
  /// The [side], [mode] and [borderRadius] arguments must not be null.
  const ContinuousRectangleBorder({
    this.side = BorderSide.none,
    this.borderRadius = 1.0,
  }) : assert(side != null),
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

  Path _getPath(RRect rrect) {
    // The radius multiplier where the resulting shape will perfectly concave at
    // with a height and width of any value.
    const double maxMultiplier = 3.0573;

    double limitedRadius;
    final double width = rrect.width;
    final double height = rrect.height;
    final double centerX = rrect.center.dx;
    final double centerY = rrect.center.dy;
    final double radius = math.max(1, borderRadius);

    // These equations give the x and y values for each of the 8 mid and corner
    // points on a rectangle.
    double leftX(double x) { return centerX + x * limitedRadius - width / 2; }
    double rightX(double x) { return centerX - x * limitedRadius + width / 2; }
    double topY(double y) { return centerY + y * limitedRadius - height / 2; }
    double bottomY(double y) { return centerY - y * limitedRadius + height / 2; }

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

    // The multiplier of the radius in comparison to the smallest edge length
    // used to describe the minimum radius for the dynamic radius round option.
    const double dynamicRadiusMinMultiplier = 2.0;

    // The edge length at which the corner radius multiplier must be at its
    // maximum so as to maintain a the appearance of a perfectly concave,
    // non-lozenge shape.
    const double minRadiusEdgeLength = 200.0;

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
    return ContinuousRectangleBorder(
      side: side.scale(t),
      borderRadius: borderRadius * t,
    );
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    assert(t != null);
    if (a is ContinuousRectangleBorder) {
      return ContinuousRectangleBorder(
        side: BorderSide.lerp(a.side, side, t),
        borderRadius: ui.lerpDouble(a.borderRadius, borderRadius, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    assert(t != null);
    if (b is ContinuousRectangleBorder) {
      return ContinuousRectangleBorder(
        side: BorderSide.lerp(side, b.side, t),
        borderRadius: ui.lerpDouble(borderRadius, b.borderRadius, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  bool operator == (dynamic other) {
    if (runtimeType != other.runtimeType)
      return false;
    final ContinuousRectangleBorder typedOther = other;
    return side == typedOther.side && borderRadius == typedOther.borderRadius;
  }

  @override
  int get hashCode => hashValues(side, borderRadius, mode);

  @override
  String toString() {
    return '$runtimeType($side, $borderRadius, $mode)';
  }
}