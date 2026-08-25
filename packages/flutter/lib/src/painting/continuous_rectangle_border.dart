// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'rounded_rectangle_border.dart';
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'basic_types.dart';
import 'border_radius.dart';
import 'borders.dart';
import 'edge_insets.dart';

/// A rectangular border with smooth continuous transitions between the straight
/// sides and the rounded corners.
///
/// {@tool snippet}
/// ```dart
/// Widget build(BuildContext context) {
///   return Material(
///     shape: ContinuousRectangleBorder(
///       borderRadius: BorderRadius.circular(28.0),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [RoundedRectangleBorder] Which creates rectangles with rounded corners,
///    however its straight sides change into a rounded corner with a circular
///    radius in a step function instead of gradually like the
///    [ContinuousRectangleBorder].
class ContinuousRectangleBorder extends OutlinedBorder {
  /// Creates a [ContinuousRectangleBorder].
  const ContinuousRectangleBorder({super.side, this.borderRadius = BorderRadius.zero});

  /// The radius for each corner.
  ///
  /// Negative radius values are clamped to 0.0 by [getInnerPath] and
  /// [getOuterPath].
  final BorderRadiusGeometry borderRadius;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) {
    return ContinuousRectangleBorder(side: side.scale(t), borderRadius: borderRadius * t);
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is ContinuousRectangleBorder) {
      return ContinuousRectangleBorder(
        side: BorderSide.lerp(a.side, side, t),
        borderRadius: BorderRadiusGeometry.lerp(a.borderRadius, borderRadius, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is ContinuousRectangleBorder) {
      return ContinuousRectangleBorder(
        side: BorderSide.lerp(side, b.side, t),
        borderRadius: BorderRadiusGeometry.lerp(borderRadius, b.borderRadius, t)!,
      );
    }
    return super.lerpTo(b, t);
  }

  // Returns `scale`, further reduced if needed so that `radius1 + radius2` fits
  // within `limit`. Mirrors the scaling that `RRect.scaleRadii` applies.
  static double _scaleToFit(double scale, double radius1, double radius2, double limit) {
    final double sum = radius1 + radius2;
    if (sum > limit && sum > 0.0) {
      return math.min(scale, limit / sum);
    }
    return scale;
  }

  Path _getPath(RRect rrect) {
    final double left = rrect.left;
    final double right = rrect.right;
    final double top = rrect.top;
    final double bottom = rrect.bottom;

    // Negative radii are documented to behave like zero radii. Clamp them
    // before the scaling below rather than after it, because the scaling looks
    // at the sum of the two radii drawn along a side: a negative radius would
    // otherwise cancel out part of the radius of the corner it shares that side
    // with and let an overflowing corner through unscaled.
    double tlRadiusX = math.max(0.0, rrect.tlRadiusX);
    double tlRadiusY = math.max(0.0, rrect.tlRadiusY);
    double trRadiusX = math.max(0.0, rrect.trRadiusX);
    double trRadiusY = math.max(0.0, rrect.trRadiusY);
    double blRadiusX = math.max(0.0, rrect.blRadiusX);
    double blRadiusY = math.max(0.0, rrect.blRadiusY);
    double brRadiusX = math.max(0.0, rrect.brRadiusX);
    double brRadiusY = math.max(0.0, rrect.brRadiusY);

    // Every side is shared by two corners, and the curves below consume one
    // radius worth of that side at each of its ends. When those two radii do
    // not fit, the curves overshoot and the straight segment between them runs
    // backwards, so the contour crosses over itself. That stays invisible while
    // the shape is filled, but it is drawn as a tie-fighter shape as soon as
    // the shape is stroked. Shrink every radius by the same factor until each
    // side fits, the way `RRect.scaleRadii` does for rounded rectangles.
    //
    // Note that this shape has always spent the x radii along the vertical
    // sides and the y radii along the horizontal ones, so the pairs below are
    // matched to the sides the path actually walks rather than to the pairs
    // `RRect.scaleRadii` would use.
    final double width = math.max(0.0, right - left);
    final double height = math.max(0.0, bottom - top);
    var scale = 1.0;
    scale = _scaleToFit(scale, tlRadiusY, trRadiusX, width); // Top side.
    scale = _scaleToFit(scale, trRadiusY, brRadiusX, height); // Right side.
    scale = _scaleToFit(scale, brRadiusY, blRadiusX, width); // Bottom side.
    scale = _scaleToFit(scale, blRadiusY, tlRadiusX, height); // Left side.
    if (scale < 1.0) {
      tlRadiusX *= scale;
      tlRadiusY *= scale;
      trRadiusX *= scale;
      trRadiusY *= scale;
      blRadiusX *= scale;
      blRadiusY *= scale;
      brRadiusX *= scale;
      brRadiusY *= scale;
    }

    return Path()
      ..moveTo(left, top + tlRadiusX)
      ..cubicTo(left, top, left, top, left + tlRadiusY, top)
      ..lineTo(right - trRadiusX, top)
      ..cubicTo(right, top, right, top, right, top + trRadiusY)
      ..lineTo(right, bottom - brRadiusX)
      ..cubicTo(right, bottom, right, bottom, right - brRadiusY, bottom)
      ..lineTo(left + blRadiusX, bottom)
      ..cubicTo(left, bottom, left, bottom, left, bottom - blRadiusY)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return _getPath(borderRadius.resolve(textDirection).toRRect(rect).deflate(side.width));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _getPath(borderRadius.resolve(textDirection).toRRect(rect));
  }

  @override
  ContinuousRectangleBorder copyWith({BorderSide? side, BorderRadiusGeometry? borderRadius}) {
    return ContinuousRectangleBorder(
      side: side ?? this.side,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (rect.isEmpty) {
      return;
    }
    switch (side.style) {
      case BorderStyle.none:
        break;
      case BorderStyle.solid:
        canvas.drawPath(getOuterPath(rect, textDirection: textDirection), side.toPaint());
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ContinuousRectangleBorder &&
        other.side == side &&
        other.borderRadius == borderRadius;
  }

  @override
  int get hashCode => Object.hash(side, borderRadius);

  @override
  String toString() {
    return '${objectRuntimeType(this, 'ContinuousRectangleBorder')}($side, $borderRadius)';
  }
}
