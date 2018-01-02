// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

/// Defines the appearance of an [InputDecorator]'s border.
///
/// An input decorator's border is specified by [InputDecoration.border].
///
/// The border is drawn relative to the input decorator's "container" which
/// is the optionally filled area above the decorator's helper, error,
/// and counter.
///
/// See also:
///
///  * [UnderlineInputBorder], the default [InputDecorator] border which
///    draws a horizontal line at the bottom of the input decorator's container.
///  * [OutlineInputBorder], an [InputDecorator] border which draws a
///    rounded rectangle around the input decorator's container.
///  * [InputDecoration], which is used to configure an [InputDecorator].
abstract class InputBorder extends ShapeBorder {
  /// Creates a border for an [InputDecorator].
  ///
  /// The [borderSide] parameter must not be null. Applications typically do
  /// not specify a [borderSide] parameter because the input decorator
  /// substitutes its own, using [copyWith], based on the current theme and
  /// [InputDecorator.isFocused].
  const InputBorder({
    this.borderSide: BorderSide.none,
  }) : assert(borderSide != null);

  /// Defines the border line's color and weight.
  ///
  /// The [InputDecorator] creates copies of its input border, using [copyWith],
  /// based on the current theme and [InputDecorator.isFocused].
  final BorderSide borderSide;

  /// Creates a copy of this input border with the specified `borderSide`.
  InputBorder copyWith({ BorderSide borderSide });
}

/// Draws a horizontal line at the bottom of an [InputDecorator]'s container.
///
/// The input decorator's "container" is the optionally filled area above the
/// decorator's helper, error, and counter.
///
/// See also:
///
///  * [OutlineInputBorder], an [InputDecorator] border which draws a
///    rounded rectangle around the input decorator's container.
///  * [InputDecoration], which is used to configure an [InputDecorator].
class UnderlineInputBorder extends InputBorder {
  /// Creates an underline border for an [InputDecorator].
  ///
  /// The [borderSide] parameter defaults to [BorderSide.none] (it must not be
  /// null). Applications typically do not specify a [borderSide] parameter
  /// because the input decorator substitutes its own, using [copyWith], based
  /// on the current theme and [InputDecorator.isFocused].
  const UnderlineInputBorder({
    BorderSide borderSide: BorderSide.none,
  }) : super(borderSide: borderSide);

  @override
  UnderlineInputBorder copyWith({ BorderSide borderSide }) {
    return new UnderlineInputBorder(borderSide: borderSide ?? this.borderSide);
  }

  @override
  EdgeInsetsGeometry get dimensions {
    return new EdgeInsets.all(borderSide.width); // TBD: just the bottom
  }

  @override
  UnderlineInputBorder scale(double t) {
    return new UnderlineInputBorder(borderSide: borderSide.scale(t));
  }

  @override
  Path getInnerPath(Rect rect, { TextDirection textDirection }) {
    return new Path()
      ..addRect(rect.deflate(borderSide.width)); // TBD: just the bottom
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection textDirection }) {
    return new Path()
      ..addRect(rect); // TBD: just the bottom
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    if (a is UnderlineInputBorder) {
      return new UnderlineInputBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    if (b is UnderlineInputBorder) {
      return new UnderlineInputBorder(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
      );
    }
    return super.lerpTo(b, t);
  }

  /// Draw a horizontal line at the bottom of [rect].
  ///
  /// The [borderSide] defines the line's color and weight.
  @override
  void paint(Canvas canvas, Rect rect, { TextDirection textDirection }) {
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, borderSide.toPaint());
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (runtimeType != other.runtimeType)
      return false;
    final InputBorder typedOther = other;
    return typedOther.borderSide == borderSide;
  }

  @override
  int get hashCode => borderSide.hashCode;
}

/// Draws a rounded rectangle around an [InputDecorator]'s container.
///
/// When the input decorator's label is floating, for example because its
/// input child has the focus, the label appears in a gap in the border outline.
///
/// The input decorator's "container" is the optionally filled area above the
/// decorator's helper, error, and counter.
///
/// See also:
///
///  * [UnderlineInputBorder], the default [InputDecorator] border which
///    draws a horizontal line at the bottom of the input decorator's container.
///  * [InputDecoration], which is used to configure an [InputDecorator].
class OutlineInputBorder extends InputBorder {
  /// Creates a rounded rectangle outline border for an [InputDecorator].
  ///
  /// The [borderSide] parameter defaults to [BorderSide.none] (it must not be
  /// null). Applications typically do not specify a [borderSide] parameter
  /// because the input decorator substitutes its own, using [copyWith], based
  /// on the current theme and [InputDecorator.isFocused].
  ///
  /// If [borderRadius] is null (the default) then the border's corners
  /// are drawn with a radius of 4dps. The corner radii must be circular, i.e.
  /// their [Radius.x] and [Radius.y] values must be the same.
  const OutlineInputBorder({
    BorderSide borderSide: BorderSide.none,
    BorderRadius borderRadius,
    this.gapPad: 4.0,
  }) : assert(gapPad != null && gapPad >= 0.0),
       _borderRadius = borderRadius,
       super(borderSide: borderSide);

  /// Horizontal padding on either side of the border's
  /// [InputDecoration.labelText] width gap.
  ///
  /// This value is used by the [paint] method to compute the actual gap width.
  final double gapPad;

  /// The radii of the border's rounded rectangle corners.
  ///
  /// The corner radii must be circular, i.e. their [Radius.x] and [Radius.y]
  /// values must be the same.
  BorderRadius get borderRadius => _borderRadius ?? new BorderRadius.circular(4.0);
  final BorderRadius _borderRadius;

  @override
  OutlineInputBorder copyWith({ BorderSide borderSide }) {
    return new OutlineInputBorder(borderSide: borderSide ?? this.borderSide);
  }

  @override
  EdgeInsetsGeometry get dimensions {
    return new EdgeInsets.all(borderSide.width);
  }

  @override
  OutlineInputBorder scale(double t) {
    return new OutlineInputBorder(
      borderSide: borderSide.scale(t),
      borderRadius: borderRadius * t,
      gapPad: gapPad * t,
    );
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    if (a is OutlineInputBorder) {
      final OutlineInputBorder outline = a;
      return new OutlineInputBorder(
        borderRadius: BorderRadius.lerp(outline.borderRadius, borderRadius, t),
        borderSide: BorderSide.lerp(outline.borderSide, borderSide, t),
        gapPad: outline.gapPad,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    if (b is OutlineInputBorder) {
      final OutlineInputBorder outline = b;
      return new OutlineInputBorder(
        borderRadius: BorderRadius.lerp(borderRadius, outline.borderRadius, t),
        borderSide: BorderSide.lerp(borderSide, outline.borderSide, t),
        gapPad: outline.gapPad,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  Path getInnerPath(Rect rect, { TextDirection textDirection }) {
    return new Path()
      ..addRRect(borderRadius.resolve(textDirection).toRRect(rect).deflate(borderSide.width));
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection textDirection }) {
    return new Path()
      ..addRRect(borderRadius.resolve(textDirection).toRRect(rect));
  }

  Path _gapBorderPath(Canvas canvas, RRect center, double start, double extent) {
    final Rect tlCorner = new Rect.fromLTWH(
      center.left,
      center.top,
      center.tlRadiusX * 2.0,
      center.tlRadiusY * 2.0,
    );
    final Rect trCorner = new Rect.fromLTWH(
      center.right - center.trRadiusX * 2.0,
      center.top,
      center.trRadiusX * 2.0,
      center.trRadiusY * 2.0,
    );
    final Rect brCorner = new Rect.fromLTWH(
      center.right - center.brRadiusX * 2.0,
      center.bottom - center.brRadiusY * 2.0,
      center.brRadiusX * 2.0,
      center.brRadiusY * 2.0,
    );
    final Rect blCorner = new Rect.fromLTWH(
      center.left,
      center.bottom - center.brRadiusY * 2.0,
      center.blRadiusX * 2.0,
      center.blRadiusY * 2.0,
    );

    final double cornerArcSweep = math.PI / 2.0;
    final double tlCornerArcSweep = start < center.tlRadiusX
      ? math.asin(start / center.tlRadiusX)
      : math.PI / 2.0;

    final Path path = new Path()
      ..addArc(tlCorner, math.PI, tlCornerArcSweep)
      ..moveTo(center.left + center.tlRadiusX, center.top);

    if (start > center.tlRadiusX)
      path.lineTo(center.left + start, center.top);

    final double trCornerArcStart = (3 * math.PI) / 2.0;
    final double trCornerArcSweep = cornerArcSweep;
    if (start + extent < center.width - center.trRadiusX) {
      path
        ..relativeMoveTo(extent, 0.0)
        ..lineTo(center.right - center.trRadiusX, center.top)
        ..addArc(trCorner, trCornerArcStart, trCornerArcSweep);
    } else if (start + extent < center.width) {
      final double dx = center.width - (start + extent);
      final double sweep = math.acos(dx / center.trRadiusX);
      path.addArc(trCorner, trCornerArcStart + sweep, trCornerArcSweep - sweep);
    }

    return path
      ..moveTo(center.right, center.top + center.trRadiusY)
      ..lineTo(center.right, center.bottom - center.brRadiusY)
      ..addArc(brCorner, 0.0, cornerArcSweep)
      ..lineTo(center.left + center.blRadiusX, center.bottom)
      ..addArc(blCorner, math.PI / 2.0, cornerArcSweep)
      ..lineTo(center.left, center.top + center.trRadiusY);
  }

  /// Draw a rounded rectangle around [rect] using [borderRadius].
  ///
  /// The [borderSide] defines the line's color and weight.
  @override
  void paint(Canvas canvas, Rect rect, {
      double gapStart,
      double gapExtent: 0.0,
      double gapPercentage: 0.0,
      TextDirection textDirection
  }) {
    assert(gapExtent != null);
    assert(gapPercentage >= 0.0 && gapPercentage <= 1.0);

    final Paint paint = borderSide.toPaint();
    final RRect outer = borderRadius.toRRect(rect);
    final RRect center = outer.deflate(borderSide.width / 2.0);
    if (gapStart == null || gapExtent <= 0.0 || gapPercentage == 0.0) {
      canvas.drawRRect(center, paint);
    } else {
      final double extent = lerpDouble(0.0, gapExtent + gapPad * 2.0, gapPercentage);
      if (textDirection == TextDirection.rtl) {
        final Path path = _gapBorderPath(canvas, center, gapStart + gapPad - extent, extent);
        canvas.drawPath(path, paint);
      } else {
        final Path path = _gapBorderPath(canvas, center, gapStart - gapPad, extent);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (runtimeType != other.runtimeType)
      return false;
    final OutlineInputBorder typedOther = other;
    return typedOther.borderSide == borderSide
        && typedOther.borderRadius == borderRadius
        && typedOther.gapPad == gapPad;
  }

  @override
  int get hashCode => hashValues(borderSide, borderRadius);
}
