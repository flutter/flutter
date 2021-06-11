// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:ui' as ui show lerpDouble;

import 'package:flutter/foundation.dart';

import 'basic_types.dart';
import 'border_radius.dart';
import 'borders.dart';
import 'circle_border.dart';
import 'edge_insets.dart';
import 'rounded_rectangle_border.dart';

/// A border that fits a stadium-shaped border (a box with semicircles on the ends)
/// within the rectangle of the widget it is applied to.
///
/// Typically used with [ShapeDecoration] to draw a stadium border.
///
/// If the rectangle is taller than it is wide, then the semicircles will be on the
/// top and bottom, and on the left and right otherwise.
///
/// See also:
///
///  * [BorderSide], which is used to describe the border of the stadium.
class StadiumBorder extends OutlinedBorder {
  /// Create a stadium border.
  ///
  /// The [side] argument must not be null.
  const StadiumBorder({ BorderSide side = BorderSide.none }) : assert(side != null), super(side: side);

  @override
  EdgeInsetsGeometry get dimensions {
    return EdgeInsets.all(side.width);
  }

  @override
  ShapeBorder scale(double t) => StadiumBorder(side: side.scale(t));

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    assert(t != null);
    if (a is StadiumBorder)
      return StadiumBorder(side: BorderSide.lerp(a.side, side, t));
    if (a is CircleBorder) {
      return _StadiumToCircleBorder(
        side: BorderSide.lerp(a.side, side, t),
        circleness: 1.0 - t,
      );
    }
    if (a is RoundedRectangleBorder) {
      return _StadiumToRoundedRectangleBorder(
        side: BorderSide.lerp(a.side, side, t),
        borderRadius: a.borderRadius as BorderRadius,
        rectness: 1.0 - t,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    assert(t != null);
    if (b is StadiumBorder)
      return StadiumBorder(side: BorderSide.lerp(side, b.side, t));
    if (b is CircleBorder) {
      return _StadiumToCircleBorder(
        side: BorderSide.lerp(side, b.side, t),
        circleness: t,
      );
    }
    if (b is RoundedRectangleBorder) {
      return _StadiumToRoundedRectangleBorder(
        side: BorderSide.lerp(side, b.side, t),
        borderRadius: b.borderRadius as BorderRadius,
        rectness: t,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  StadiumBorder copyWith({ BorderSide? side }) {
    return StadiumBorder(side: side ?? this.side);
  }

  @override
  Path getInnerPath(Rect rect, { TextDirection? textDirection }) {
    final Radius radius = Radius.circular(rect.shortestSide / 2.0);
    return Path()
      ..addRRect(RRect.fromRectAndRadius(rect, radius).deflate(side.width));
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection? textDirection }) {
    final Radius radius = Radius.circular(rect.shortestSide / 2.0);
    return Path()
      ..addRRect(RRect.fromRectAndRadius(rect, radius));
  }

  @override
  void paint(Canvas canvas, Rect rect, { TextDirection? textDirection }) {
    switch (side.style) {
      case BorderStyle.none:
        break;
      case BorderStyle.solid:
        final Radius radius = Radius.circular(rect.shortestSide / 2.0);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, radius).deflate(side.width / 2.0),
          side.toPaint(),
        );
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is StadiumBorder
        && other.side == side;
  }

  @override
  int get hashCode => side.hashCode;

  @override
  String toString() {
    return '${objectRuntimeType(this, 'StadiumBorder')}($side)';
  }
}

// Class to help with transitioning to/from a CircleBorder.
class _StadiumToCircleBorder extends OutlinedBorder {
  const _StadiumToCircleBorder({
    BorderSide side = BorderSide.none,
    this.circleness = 0.0,
  }) : assert(side != null),
       assert(circleness != null),
       super(side: side);

  final double circleness;

  @override
  EdgeInsetsGeometry get dimensions {
    return EdgeInsets.all(side.width);
  }

  @override
  ShapeBorder scale(double t) {
    return _StadiumToCircleBorder(
      side: side.scale(t),
      circleness: t,
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    assert(t != null);
    if (a is StadiumBorder) {
      return _StadiumToCircleBorder(
        side: BorderSide.lerp(a.side, side, t),
        circleness: circleness * t,
      );
    }
    if (a is CircleBorder) {
      return _StadiumToCircleBorder(
        side: BorderSide.lerp(a.side, side, t),
        circleness: circleness + (1.0 - circleness) * (1.0 - t),
      );
    }
    if (a is _StadiumToCircleBorder) {
      return _StadiumToCircleBorder(
        side: BorderSide.lerp(a.side, side, t),
        circleness: ui.lerpDouble(a.circleness, circleness, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    assert(t != null);
    if (b is StadiumBorder) {
      return _StadiumToCircleBorder(
        side: BorderSide.lerp(side, b.side, t),
        circleness: circleness * (1.0 - t),
      );
    }
    if (b is CircleBorder) {
      return _StadiumToCircleBorder(
        side: BorderSide.lerp(side, b.side, t),
        circleness: circleness + (1.0 - circleness) * t,
      );
    }
    if (b is _StadiumToCircleBorder) {
      return _StadiumToCircleBorder(
        side: BorderSide.lerp(side, b.side, t),
        circleness: ui.lerpDouble(circleness, b.circleness, t)!,
      );
    }
    return super.lerpTo(b, t);
  }

  Rect _adjustRect(Rect rect) {
    if (circleness == 0.0 || rect.width == rect.height)
      return rect;
    if (rect.width < rect.height) {
      final double delta = circleness * (rect.height - rect.width) / 2.0;
      return Rect.fromLTRB(
        rect.left,
        rect.top + delta,
        rect.right,
        rect.bottom - delta,
      );
    } else {
      final double delta = circleness * (rect.width - rect.height) / 2.0;
      return Rect.fromLTRB(
        rect.left + delta,
        rect.top,
        rect.right - delta,
        rect.bottom,
      );
    }
  }

  BorderRadius _adjustBorderRadius(Rect rect) {
    return BorderRadius.circular(rect.shortestSide / 2.0);
  }

  @override
  Path getInnerPath(Rect rect, { TextDirection? textDirection }) {
    return Path()
      ..addRRect(_adjustBorderRadius(rect).toRRect(_adjustRect(rect)).deflate(side.width));
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection? textDirection }) {
    return Path()
      ..addRRect(_adjustBorderRadius(rect).toRRect(_adjustRect(rect)));
  }

  @override
  _StadiumToCircleBorder copyWith({ BorderSide? side, double? circleness }) {
    return _StadiumToCircleBorder(
      side: side ?? this.side,
      circleness: circleness ?? this.circleness,
    );
  }

  @override
  void paint(Canvas canvas, Rect rect, { TextDirection? textDirection }) {
    switch (side.style) {
      case BorderStyle.none:
        break;
      case BorderStyle.solid:
        final double width = side.width;
        if (width == 0.0) {
          canvas.drawRRect(_adjustBorderRadius(rect).toRRect(_adjustRect(rect)), side.toPaint());
        } else {
          final RRect outer = _adjustBorderRadius(rect).toRRect(_adjustRect(rect));
          final RRect inner = outer.deflate(width);
          final Paint paint = Paint()
            ..color = side.color;
          canvas.drawDRRect(outer, inner, paint);
        }
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is _StadiumToCircleBorder
        && other.side == side
        && other.circleness == circleness;
  }

  @override
  int get hashCode => hashValues(side, circleness);

  @override
  String toString() {
    return 'StadiumBorder($side, ${(circleness * 100).toStringAsFixed(1)}% '
           'of the way to being a CircleBorder)';
  }
}

// Class to help with transitioning to/from a RoundedRectBorder.
class _StadiumToRoundedRectangleBorder extends OutlinedBorder {
  const _StadiumToRoundedRectangleBorder({
    BorderSide side = BorderSide.none,
    this.borderRadius = BorderRadius.zero,
    this.rectness = 0.0,
  }) : assert(side != null),
       assert(borderRadius != null),
       assert(rectness != null),
       super(side: side);

  final BorderRadius borderRadius;

  final double rectness;

  @override
  EdgeInsetsGeometry get dimensions {
    return EdgeInsets.all(side.width);
  }

  @override
  ShapeBorder scale(double t) {
    return _StadiumToRoundedRectangleBorder(
      side: side.scale(t),
      borderRadius: borderRadius * t,
      rectness: t,
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    assert(t != null);
    if (a is StadiumBorder) {
      return _StadiumToRoundedRectangleBorder(
        side: BorderSide.lerp(a.side, side, t),
        borderRadius: borderRadius,
        rectness: rectness * t,
      );
    }
    if (a is RoundedRectangleBorder) {
      return _StadiumToRoundedRectangleBorder(
        side: BorderSide.lerp(a.side, side, t),
        borderRadius: borderRadius,
        rectness: rectness + (1.0 - rectness) * (1.0 - t),
      );
    }
    if (a is _StadiumToRoundedRectangleBorder) {
      return _StadiumToRoundedRectangleBorder(
        side: BorderSide.lerp(a.side, side, t),
        borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t)!,
        rectness: ui.lerpDouble(a.rectness, rectness, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    assert(t != null);
    if (b is StadiumBorder) {
      return _StadiumToRoundedRectangleBorder(
        side: BorderSide.lerp(side, b.side, t),
        borderRadius: borderRadius,
        rectness: rectness * (1.0 - t),
      );
    }
    if (b is RoundedRectangleBorder) {
      return _StadiumToRoundedRectangleBorder(
        side: BorderSide.lerp(side, b.side, t),
        borderRadius: borderRadius,
        rectness: rectness + (1.0 - rectness) * t,
      );
    }
    if (b is _StadiumToRoundedRectangleBorder) {
      return _StadiumToRoundedRectangleBorder(
        side: BorderSide.lerp(side, b.side, t),
        borderRadius: BorderRadius.lerp(borderRadius, b.borderRadius, t)!,
        rectness: ui.lerpDouble(rectness, b.rectness, t)!,
      );
    }
    return super.lerpTo(b, t);
  }

  BorderRadius _adjustBorderRadius(Rect rect) {
    return BorderRadius.lerp(
      borderRadius,
      BorderRadius.all(Radius.circular(rect.shortestSide / 2.0)),
      1.0 - rectness,
    )!;
  }

  @override
  Path getInnerPath(Rect rect, { TextDirection? textDirection }) {
    return Path()
      ..addRRect(_adjustBorderRadius(rect).toRRect(rect).deflate(side.width));
  }

  @override
  Path getOuterPath(Rect rect, { TextDirection? textDirection }) {
    return Path()
      ..addRRect(_adjustBorderRadius(rect).toRRect(rect));
  }

  @override
  _StadiumToRoundedRectangleBorder copyWith({ BorderSide? side, BorderRadius? borderRadius, double? rectness }) {
    return _StadiumToRoundedRectangleBorder(
      side: side ?? this.side,
      borderRadius: borderRadius ?? this.borderRadius,
      rectness: rectness ?? this.rectness,
    );
  }

  @override
  void paint(Canvas canvas, Rect rect, { TextDirection? textDirection }) {
    switch (side.style) {
      case BorderStyle.none:
        break;
      case BorderStyle.solid:
        final double width = side.width;
        if (width == 0.0) {
          canvas.drawRRect(_adjustBorderRadius(rect).toRRect(rect), side.toPaint());
        } else {
          final RRect outer = _adjustBorderRadius(rect).toRRect(rect);
          final RRect inner = outer.deflate(width);
          final Paint paint = Paint()
            ..color = side.color;
          canvas.drawDRRect(outer, inner, paint);
        }
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is _StadiumToRoundedRectangleBorder
        && other.side == side
        && other.borderRadius == borderRadius
        && other.rectness == rectness;
  }

  @override
  int get hashCode => hashValues(side, borderRadius, rectness);

  @override
  String toString() {
    return 'StadiumBorder($side, $borderRadius, '
           '${(rectness * 100).toStringAsFixed(1)}% of the way to being a '
           'RoundedRectangleBorder)';
  }
}
