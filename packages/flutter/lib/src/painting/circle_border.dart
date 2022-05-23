// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui show lerpDouble;

import 'package:flutter/foundation.dart';

import 'basic_types.dart';
import 'borders.dart';
import 'edge_insets.dart';

/// A border that fits a circle within the available space.
///
/// Typically used with [ShapeDecoration] to draw a circle.
///
/// The [dimensions] assume that the border is being used in a square space.
/// When applied to a rectangular space, the border paints in the center of the
/// rectangle.
///
/// The [ovalness] parameter allows the circle to be painted touching all
/// the edges of a rectangle, becoming an oval. When applied to a
/// squared space, [ovalness] is ignored.
///
/// See also:
///
///  * [OvalBorder], which draws a Circle touching all the edges of the box.
///  * [BorderSide], which is used to describe each side of the box.
///  * [Border], which, when used with [BoxDecoration], can also describe a circle.
class CircleBorder extends OutlinedBorder {
  /// Create a circle border.
  ///
  /// The [side] argument must not be null.
  const CircleBorder({ super.side, this.ovalness = 0.0 })
      : assert(side != null && ovalness != null && ovalness >= 0.0 && ovalness <= 1.0);

  /// Defines the ratio (0.0-1.0) from which the border will be drawn
  /// to the longest side of a rectangular box, touching all the sides.
  /// When 0.0, it draws a circle. When 1.0, it draws an oval.
  /// This property is ignored when applied to a squared box.
  final double ovalness;

  @override
  EdgeInsetsGeometry get dimensions {
    switch (side.strokeAlign) {
      case StrokeAlign.inside:
        return EdgeInsets.all(side.width);
      case StrokeAlign.center:
        return EdgeInsets.all(side.width / 2);
      case StrokeAlign.outside:
        return EdgeInsets.zero;
    }
  }

  @override
  ShapeBorder scale(double t) => CircleBorder(side: side.scale(t), ovalness: ovalness);

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is CircleBorder) {
      return CircleBorder(
        side: BorderSide.lerp(a.side, side, t),
        ovalness: ui.lerpDouble(a.ovalness, ovalness, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is CircleBorder) {
      return CircleBorder(
        side: BorderSide.lerp(side, b.side, t),
        ovalness: ui.lerpDouble(ovalness, b.ovalness, t)!,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  Path getInnerPath(Rect rect, { TextDirection? textDirection }) {
    final double radius = rect.shortestSide / 2.0;
    final double adjustedRadius;
    switch (side.strokeAlign) {
      case StrokeAlign.inside:
        adjustedRadius = radius - side.width;
        break;
      case StrokeAlign.center:
        adjustedRadius = radius - side.width / 2.0;
        break;
      case StrokeAlign.outside:
        adjustedRadius = radius;
        break;
    }
    return Path()
      ..addOval(Rect.fromCircle(
        center: rect.center,
        radius: math.max(0.0, adjustedRadius),
      ));
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection? textDirection }) {
    if (ovalness != 0) {
      return Path()..addOval(_adjustRect(rect));
    }

    return Path()
      ..addOval(Rect.fromCircle(
        center: rect.center,
        radius: rect.shortestSide / 2.0,
      ));
  }

  @override
  CircleBorder copyWith({ BorderSide? side, double? ovalness }) {
    return CircleBorder(side: side ?? this.side, ovalness: ovalness ?? this.ovalness);
  }

  @override
  void paint(Canvas canvas, Rect rect, { TextDirection? textDirection }) {
    switch (side.style) {
      case BorderStyle.none:
        break;
      case BorderStyle.solid:
        if (ovalness != 0.0) {
          final Rect borderRect = _adjustRect(rect);
          final Rect adjustedRect;
          switch (side.strokeAlign) {
            case StrokeAlign.inside:
              adjustedRect = borderRect.deflate(side.width / 2);
              break;
            case StrokeAlign.center:
              adjustedRect = borderRect;
              break;
            case StrokeAlign.outside:
              adjustedRect = borderRect.inflate(side.width / 2);
              break;
          }
          canvas.drawOval(adjustedRect, side.toPaint());
        } else {
          final double radius;
          switch (side.strokeAlign) {
            case StrokeAlign.inside:
              radius = (rect.shortestSide - side.width) / 2.0;
              break;
            case StrokeAlign.center:
              radius = rect.shortestSide / 2.0;
              break;
            case StrokeAlign.outside:
              radius = (rect.shortestSide + side.width) / 2.0;
              break;
          }
          canvas.drawCircle(rect.center, radius, side.toPaint());
        }
    }
  }

  Rect _adjustRect(Rect rect) {
    if (ovalness == 0.0 || rect.width == rect.height)
      return rect;
    if (rect.width < rect.height) {
      final double delta = (1 - ovalness) * (rect.height - rect.width) / 2.0;
      return Rect.fromLTRB(
        rect.left,
        rect.top + delta,
        rect.right,
        rect.bottom - delta,
      );
    } else {
      final double delta = (1 - ovalness) * (rect.width - rect.height) / 2.0;
      return Rect.fromLTRB(
        rect.left + delta,
        rect.top,
        rect.right - delta,
        rect.bottom,
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CircleBorder
        && other.side == side
        && other.ovalness == ovalness;
  }

  @override
  int get hashCode => side.hashCode;

  @override
  String toString() {
    if (ovalness != 0.0) {
      return '${objectRuntimeType(this, 'CircleBorder')}($side, ovalness: $ovalness)';
    }
    return '${objectRuntimeType(this, 'CircleBorder')}($side)';
  }
}
