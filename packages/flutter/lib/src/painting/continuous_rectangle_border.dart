// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'basic_types.dart';
import 'borders.dart';
import 'edge_insets.dart';

/// A continuous corner rounded rectangle.
///
/// A shape similar to a rounded rectangle, but with a smoother transition from
/// the sides to the rounded corners.
///
/// The rendered shape roughly approximates that of a superellipse. In this
/// shape, the curvature of each corner over the arc is approximately a gaussian
/// curve instead of a step function as with a traditional quarter circle round.
/// The rendered rectangle is roughly a superellipse with an n value of 5.
///
/// In an attempt to keep the shape of the rectangle the same regardless of its
/// dimension (and to avoid clipping of the shape), the radius will
/// automatically be lessened if its width or height is less than ~3x the radius.
/// The new resulting radius will always be maximal in respect to the dimensions
/// of the given rectangle.
///
/// This shape will always have 4 linear edges and 4 90º curves. However, for
/// rectangles with small values of width or height (ie.  <20 lpx) and a low
/// aspect ratio (ie. <0.3), the rendered shape will appear to have just 2
/// linear edges and 2 180º curves.
///
/// The example below shows how to render a continuous rectangle on screen.
///
/// {@tool sample}
/// ```dart
/// Widget build(BuildContext context) {
///   return Container(
///     alignment: Alignment.center,
///     child: Material(
///       color: Colors.blueAccent[400],
///       shape: const ContinuousRectangleBorder(borderRadius: 75.0),
///       child: const SizedBox(
///         height: 200,
///         width: 200,
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
/// * [RoundedRectangleBorder], which is a rectangle whose corners are
///   precisely quarter circles.
/// * [ContinuousStadiumBorder], which is a stadium whose two edges have a
///   continuous transition into its two 180º curves.
/// * [StadiumBorder], which is a rectangle with semi-circles on two parallel
///   edges.
class ContinuousRectangleBorder extends ShapeBorder {
  /// Creates a continuous cornered rectangle border.
  ///
  /// The [side] and [borderRadius] arguments must not be null.
  const ContinuousRectangleBorder({
    this.side = BorderSide.none,
    this.borderRadius = 0.0,
  }) : assert(side != null),
       assert(borderRadius != null);

  /// The radius for each corner.
  ///
  /// The radius will be clamped to 0 if a value less than 0 is entered as the
  /// radius.
  ///
  /// By default the radius is 0.0. This value must not be null.
  ///
  /// Unlike [RoundedRectangleBorder], there is only a single border radius used
  /// to describe the radius for every corner.
  final double borderRadius;

  /// The style of this border.
  ///
  /// If the border side width is larger than 1/10 the length of the smallest
  /// dimension, the interior shape's corners will no longer resemble those of
  /// the exterior shape. If concentric corners are desired for a stroke width
  /// greater than 1/10 the length of the smallest dimension, it is recommended
  /// to use a [Stack] widget, placing a smaller [ContinuousRectangleBorder] with
  /// the same 'borderRadius' on top of a larger one.
  ///
  /// By default this value is [BorderSide.none]. It must not be null.
  final BorderSide side;

  Path _getPath(Rect rect) {
    // We need to change the dimensions of the rect in the event that the
    // shape has a side width as the stroke is drawn centered on the border of
    // the shape instead of inside as with the rounded rect and stadium.
    if (side.width > 0)
      rect = rect.deflate(side.width / 2);

    double limitedRadius;
    final double width = rect.width;
    final double height = rect.height;
    final double centerX = rect.center.dx;
    final double centerY = rect.center.dy;
    final double radius = math.max(1, borderRadius);

    // These equations give the x and y values for each of the 8 mid and corner
    // points on a rectangle.
    //
    // For example, leftX(k) will give the x value on the left side of the shape
    // that is precisely `k` distance from the left edge of the shape for the
    // predetermined radius value.
    double leftX(double x) { return centerX + x * limitedRadius - width / 2; }
    double rightX(double x) { return centerX - x * limitedRadius + width / 2; }
    double topY(double y) { return centerY + y * limitedRadius - height / 2; }
    double bottomY(double y) { return centerY - y * limitedRadius + height / 2; }

    // Renders the default superelliptical rounded rect shape where there are
    // 4 straight edges and 4 90º corners. Approximately renders a superellipse
    // with n value of 5.
    //
    // Code was inspired from the code listed on this website:
    // https://www.paintcodeapp.com/news/code-for-ios-7-rounded-rectangles
    //
    // Roughly the code draws the shape from the upper right hand corner in a
    // clockwise fashion around to the upper left hand corner.
    Path bezierRoundedRect () {
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

    // The radius multiplier where the resulting shape will concave with a
    // height and width of any value.
    //
    // If the shortest side length to radius ratio drops below this value, the
    // radius must be lessened to avoid clipping (ie. concavity) of the shape.
    const double maxMultiplier = 3.0573;

    // The multiplier of the radius in comparison to the smallest edge length
    // used to describe the minimum radius for this shape.
    //
    // This is multiplier used in the case of an extreme aspect ratio and a
    // small extent value. It can be less than 'maxMultiplier' because there
    // are not enough pixels to render the clipping of the shape at this size so
    // it appears to still be concave (whereas mathematically it's convex).
    const double minMultiplier = 2.2;

    // The minimum edge length at which the corner radius multiplier must be at
    // its maximum so as to maintain the appearance of a perfectly concave,
    // non-lozenge shape.
    //
    // If the smallest edge length is less than this value, the dynamic radius
    // value can be made smaller than the 'maxMultiplier' while the rendered
    // shape still does not visually clip.
    const double minRadiusEdgeLength = 200.0;

    final double minSideLength = math.min(rect.width, rect.height);

    // As the minimum side edge length (where the round is occurring)
    // approaches 0, the limitedRadius approaches 2.0 so as to maximize
    // roundness (to make the shape with the largest radius that doesn't clip).
    // As the edge length approaches 200, the limitedRadius approaches ~3 –- the
    // multiplier of the radius value where the resulting shape is concave (ie.
    // does not visually clip) at any dimension.
    final double multiplier = ui.lerpDouble(
        minMultiplier,
        maxMultiplier,
        minSideLength / minRadiusEdgeLength
    );
    limitedRadius = math.min(radius, minSideLength / multiplier);
    return bezierRoundedRect();
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
        final Paint paint = side.toPaint();
        if (width != 0.0){
          canvas.drawPath(getOuterPath(rect), paint);
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
  bool operator ==(dynamic other) {
    if (runtimeType != other.runtimeType)
      return false;
    final ContinuousRectangleBorder typedOther = other;
    return side == typedOther.side && borderRadius == typedOther.borderRadius;
  }

  @override
  int get hashCode => hashValues(side, borderRadius);

  @override
  String toString() {
    return '$runtimeType($side, $borderRadius)';
  }
}