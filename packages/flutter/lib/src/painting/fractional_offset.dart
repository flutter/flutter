// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show lerpDouble;

import 'package:flutter/foundation.dart';

import 'basic_types.dart';

/// Base class for [FractionalOffset] that allows for text-direction aware
/// resolution.
///
/// A property or argument of this type accepts classes created either with [new
/// FractionalOffset] and its variants, or [new FractionalOffsetDirectional].
///
/// To convert a [FractionalOffsetGeometry] object of indeterminate type into a
/// [FractionalOffset] object, call the [resolve] method.
abstract class FractionalOffsetGeometry {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const FractionalOffsetGeometry();

  /// The [FractionalOffset.dx] to which this object will [resolve] in [TextDirection.ltr].
  double get _dxForRTL;

  /// The [FractionalOffset.dx] to which this object will [resolve] in [TextDirection.ltr].
  double get _dxForLTR;

  double get _dy;

  /// Returns the difference between two [FractionalOffsetGeometry] objects.
  ///
  /// If you know you are applying this to two [FractionalOffset]s or two
  /// [FractionalOffsetDirectional] objects, consider using the binary infix `-`
  /// operator instead, which always returns an object of the same type as the
  /// operands, and is typed accordingly.
  ///
  /// If [subtract] is applied to two objects of the same type ([FractionalOffset] or
  /// [FractionalOffsetDirectional]), an object of that type will be returned (though
  /// this is not reflected in the type system). Otherwise, an object
  /// representing a combination of both is returned. That object can be turned
  /// into a concrete [FractionalOffset] using [resolve].
  ///
  /// This method returns the same result as [add] applied to the result of
  /// negating the argument (using the prefix unary `-` operator or multiplying
  /// the argument by -1.0 using the `*` operator).
  FractionalOffsetGeometry subtract(FractionalOffsetGeometry other) {
    return new _SchrodingersFractionalOffset(
      _dxForRTL - other._dxForRTL,
      _dxForLTR - other._dxForLTR,
      _dy - other._dy,
    );
  }

  /// Returns the sum of two [FractionalOffsetGeometry] objects.
  ///
  /// If you know you are adding two [FractionalOffset] or two [FractionalOffsetDirectional]
  /// objects, consider using the `+` operator instead, which always returns an
  /// object of the same type as the operands, and is typed accordingly.
  ///
  /// If [add] is applied to two objects of the same type ([FractionalOffset] or
  /// [FractionalOffsetDirectional]), an object of that type will be returned (though
  /// this is not reflected in the type system). Otherwise, an object
  /// representing a combination of both is returned. That object can be turned
  /// into a concrete [FractionalOffset] using [resolve].
  FractionalOffsetGeometry add(FractionalOffsetGeometry other) {
    return new _SchrodingersFractionalOffset(
      _dxForRTL + other._dxForRTL,
      _dxForLTR + other._dxForLTR,
      _dy + other._dy,
    );
  }

  /// Returns the negation of the given [FractionalOffsetGeometry] object.
  ///
  /// This is the same as multiplying the object by -1.0.
  ///
  /// This operator returns an object of the same type as the operand.
  FractionalOffsetGeometry operator -();

  /// Scales the [FractionalOffsetGeometry] object in each dimension by the given factor.
  ///
  /// This operator returns an object of the same type as the operand.
  FractionalOffsetGeometry operator *(double other);

  /// Divides the [FractionalOffsetGeometry] object in each dimension by the given factor.
  ///
  /// This operator returns an object of the same type as the operand.
  FractionalOffsetGeometry operator /(double other);

  /// Integer divides the [FractionalOffsetGeometry] object in each dimension by the given factor.
  ///
  /// This operator returns an object of the same type as the operand.
  FractionalOffsetGeometry operator ~/(double other);

  /// Computes the remainder in each dimension by the given factor.
  ///
  /// This operator returns an object of the same type as the operand.
  FractionalOffsetGeometry operator %(double other);

  /// Linearly interpolate between two [FractionalOffsetGeometry] objects.
  ///
  /// If either is null, this function interpolates from [FractionalOffset.center], and
  /// the result is an object of the same type as the non-null argument.
  ///
  /// If [lerp] is applied to two objects of the same type ([FractionalOffset] or
  /// [FractionalOffsetDirectional]), an object of that type will be returned (though
  /// this is not reflected in the type system). Otherwise, an object
  /// representing a combination of both is returned. That object can be turned
  /// into a concrete [FractionalOffset] using [resolve].
  static FractionalOffsetGeometry lerp(FractionalOffsetGeometry a, FractionalOffsetGeometry b, double t) {
    if (a == null && b == null)
      return null;
    if ((a == null || a is FractionalOffset) && (b == null || b is FractionalOffset))
      return FractionalOffset.lerp(a, b, t);
    if ((a == null || a is FractionalOffsetDirectional) && (b == null || b is FractionalOffsetDirectional))
      return FractionalOffsetDirectional.lerp(a, b, t);
    if (a == null) {
      return new _SchrodingersFractionalOffset(
        ui.lerpDouble(0.5, b._dxForRTL, t),
        ui.lerpDouble(0.5, b._dxForLTR, t),
        ui.lerpDouble(0.5, b._dy, t),
      );
    }
    if (b == null) {
      return new _SchrodingersFractionalOffset(
        ui.lerpDouble(a._dxForRTL, 0.5, t),
        ui.lerpDouble(a._dxForLTR, 0.5, t),
        ui.lerpDouble(a._dy, 0.5, t),
      );
    }
    return new _SchrodingersFractionalOffset(
      ui.lerpDouble(a._dxForRTL, b._dxForRTL, t),
      ui.lerpDouble(a._dxForLTR, b._dxForLTR, t),
      ui.lerpDouble(a._dy, b._dy, t),
    );
  }

  /// Convert this instance into a [FractionalOffset], which uses literal
  /// coordinates (the `x` coordinate being explicitly a distance from the
  /// left).
  ///
  /// See also:
  ///
  ///  * [FractionalOffset], for which this is a no-op (returns itself).
  ///  * [FractionalOffsetDirectional], which flips the horizontal direction
  ///    based on the `direction` argument.
  FractionalOffset resolve(TextDirection direction) {
    assert(direction != null);
    switch (direction) {
      case TextDirection.rtl:
        return new FractionalOffset(_dxForRTL, _dy);
      case TextDirection.ltr:
        return new FractionalOffset(_dxForLTR, _dy);
    }
    return null;
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! FractionalOffsetGeometry)
      return false;
    final FractionalOffsetGeometry typedOther = other;
    return _dxForRTL == typedOther._dxForRTL &&
           _dxForLTR == typedOther._dxForLTR &&
           _dy == typedOther._dy;
  }

  @override
  int get hashCode => hashValues(_dxForRTL, _dxForLTR, _dy);
}

/// An offset that's expressed as a fraction of a [Size].
///
/// `FractionalOffset(1.0, 0.0)` represents the top right of the [Size].
///
/// `FractionalOffset(0.0, 1.0)` represents the bottom left of the [Size].
///
/// `FractionalOffset(0.5, 2.0)` represents a point half way across the [Size],
/// below the bottom of the rectangle by the height of the [Size].
///
/// The [FractionalOffset] class specifies offsets in terms of a distance from
/// the top left, regardless of the [TextDirection]. To support both
/// left-to-right and right-to-left layouts, consider using
/// [FractionalOffsetDirectional], which is expressed in terms of an offset from
/// the leading edge, which is then resolved in terms of a [TextDirection]
/// (typically obtained from the ambient [Directionality]).
///
/// A variety of widgets use [FractionalOffset] in their configuration, most
/// notably:
///
///  * [Align] positions a child according to a [FractionalOffset].
///  * [FractionalTranslation] moves a child according to a [FractionalOffset].
///
/// See also:
///
///  * [FractionalOffsetDirectional], which (for properties and arguments that
///    accept the type [FractionalOffsetGeometry]) allows the horizontal
///    coordinate to be specified in a [TextDirection]-aware manner.
@immutable
class FractionalOffset extends FractionalOffsetGeometry {
  /// Creates a fractional offset.
  ///
  /// The [dx] and [dy] arguments must not be null.
  const FractionalOffset(this.dx, this.dy)
    : assert(dx != null),
      assert(dy != null);

  /// Creates a fractional offset from a specific offset and size.
  ///
  /// The returned [FractionalOffset] describes the position of the
  /// [Offset] in the [Size], as a fraction of the [Size].
  FractionalOffset.fromOffsetAndSize(Offset offset, Size size) :
    assert(size != null),
    assert(offset != null),
    dx = offset.dx / size.width,
    dy = offset.dy / size.height;

  /// Creates a fractional offset from a specific offset and rectangle.
  ///
  /// The offset is assumed to be relative to the same origin as the rectangle.
  ///
  /// If the offset is relative to the top left of the rectangle, use [new
  /// FractionalOffset.fromOffsetAndSize] instead, passing `rect.size`.
  ///
  /// The returned [FractionalOffset] describes the position of the
  /// [Offset] in the [Rect], as a fraction of the [Rect].
  factory FractionalOffset.fromOffsetAndRect(Offset offset, Rect rect) {
    return new FractionalOffset.fromOffsetAndSize(
      offset - rect.topLeft,
      rect.size,
    );
  }

  /// The distance fraction in the horizontal direction.
  ///
  /// A value of 0.0 corresponds to the leftmost edge. A value of 1.0
  /// corresponds to the rightmost edge. Values are not limited to that range;
  /// negative values represent positions to the left of the left edge, and
  /// values greater than 1.0 represent positions to the right of the right
  /// edge.
  final double dx;

  @override
  double get _dxForRTL => dx;

  @override
  double get _dxForLTR => dx;

  /// The distance fraction in the vertical direction.
  ///
  /// A value of 0.0 corresponds to the topmost edge. A value of 1.0 corresponds
  /// to the bottommost edge. Values are not limited to that range; negative
  /// values represent positions above the top, and values greater than 1.0
  /// represent positions below the bottom.
  final double dy;

  @override
  double get _dy => dy;

  /// The top left corner.
  static const FractionalOffset topLeft = const FractionalOffset(0.0, 0.0);

  /// The center point along the top edge.
  static const FractionalOffset topCenter = const FractionalOffset(0.5, 0.0);

  /// The top right corner.
  static const FractionalOffset topRight = const FractionalOffset(1.0, 0.0);

  /// The center point along the left edge.
  static const FractionalOffset centerLeft = const FractionalOffset(0.0, 0.5);

  /// The center point, both horizontally and vertically.
  static const FractionalOffset center = const FractionalOffset(0.5, 0.5);

  /// The center point along the right edge.
  static const FractionalOffset centerRight = const FractionalOffset(1.0, 0.5);

  /// The bottom left corner.
  static const FractionalOffset bottomLeft = const FractionalOffset(0.0, 1.0);

  /// The center point along the bottom edge.
  static const FractionalOffset bottomCenter = const FractionalOffset(0.5, 1.0);

  /// The bottom right corner.
  static const FractionalOffset bottomRight = const FractionalOffset(1.0, 1.0);

  @override
  FractionalOffsetGeometry subtract(FractionalOffsetGeometry other) {
    if (other is FractionalOffset)
      return this - other;
    return super.subtract(other);
  }

  @override
  FractionalOffsetGeometry add(FractionalOffsetGeometry other) {
    if (other is FractionalOffset)
      return this + other;
    return super.add(other);
  }

  /// Returns the difference between two [FractionalOffset]s.
  FractionalOffset operator -(FractionalOffset other) {
    return new FractionalOffset(dx - other.dx, dy - other.dy);
  }

  /// Returns the sum of two [FractionalOffset]s.
  FractionalOffset operator +(FractionalOffset other) {
    return new FractionalOffset(dx + other.dx, dy + other.dy);
  }

  /// Returns the negation of the given [FractionalOffset].
  @override
  FractionalOffset operator -() {
    return new FractionalOffset(-dx, -dy);
  }

  /// Scales the [FractionalOffset] in each dimension by the given factor.
  @override
  FractionalOffset operator *(double other) {
    return new FractionalOffset(dx * other, dy * other);
  }

  /// Divides the [FractionalOffset] in each dimension by the given factor.
  @override
  FractionalOffset operator /(double other) {
    return new FractionalOffset(dx / other, dy / other);
  }

  /// Integer divides the [FractionalOffset] in each dimension by the given factor.
  @override
  FractionalOffset operator ~/(double other) {
    return new FractionalOffset((dx ~/ other).toDouble(), (dy ~/ other).toDouble());
  }

  /// Computes the remainder in each dimension by the given factor.
  @override
  FractionalOffset operator %(double other) {
    return new FractionalOffset(dx % other, dy % other);
  }

  /// Returns the offset that is this fraction in the direction of the given offset.
  Offset alongOffset(Offset other) {
    return new Offset(dx * other.dx, dy * other.dy);
  }

  /// Returns the offset that is this fraction within the given size.
  Offset alongSize(Size other) {
    return new Offset(dx * other.width, dy * other.height);
  }

  /// Returns the point that is this fraction within the given rect.
  Offset withinRect(Rect rect) {
    return new Offset(rect.left + dx * rect.width, rect.top + dy * rect.height);
  }

  /// Returns a rect of the given size, centered at this fraction of the given rect.
  ///
  /// For example, a 100×100 size inscribed on a 200×200 rect using
  /// [FractionalOffset.topLeft] would be the 100×100 rect at the top left of
  /// the 200×200 rect.
  Rect inscribe(Size size, Rect rect) {
    return new Rect.fromLTWH(
      rect.left + (rect.width - size.width) * dx,
      rect.top + (rect.height - size.height) * dy,
      size.width,
      size.height,
    );
  }

  /// Linearly interpolate between two [FractionalOffset]s.
  ///
  /// If either is null, this function interpolates from [FractionalOffset.center].
  static FractionalOffset lerp(FractionalOffset a, FractionalOffset b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return new FractionalOffset(ui.lerpDouble(0.5, b.dx, t), ui.lerpDouble(0.5, b.dy, t));
    if (b == null)
      return new FractionalOffset(ui.lerpDouble(a.dx, 0.5, t), ui.lerpDouble(a.dy, 0.5, t));
    return new FractionalOffset(ui.lerpDouble(a.dx, b.dx, t), ui.lerpDouble(a.dy, b.dy, t));
  }

  @override
  FractionalOffset resolve(TextDirection direction) => this;

  static String _stringify(double dx, double dy) {
    if (dx == 0.0 && dy == 0.0)
      return 'FractionalOffset.topLeft';
    if (dx == 0.5 && dy == 0.0)
      return 'FractionalOffset.topCenter';
    if (dx == 1.0 && dy == 0.0)
      return 'FractionalOffset.topRight';
    if (dx == 0.0 && dy == 0.5)
      return 'FractionalOffset.centerLeft';
    if (dx == 0.5 && dy == 0.5)
      return 'FractionalOffset.center';
    if (dx == 1.0 && dy == 0.5)
      return 'FractionalOffset.centerRight';
    if (dx == 0.0 && dy == 1.0)
      return 'FractionalOffset.bottomLeft';
    if (dx == 0.5 && dy == 1.0)
      return 'FractionalOffset.bottomCenter';
    if (dx == 1.0 && dy == 1.0)
      return 'FractionalOffset.bottomRight';
    return 'FractionalOffset(${dx.toStringAsFixed(1)}, '
                            '${dy.toStringAsFixed(1)})';
  }

  @override
  String toString() => _stringify(dx, dy);
}

/// An offset that's expressed as a fraction of a [Size], but whose horizontal
/// component is dependent on the writing direction.
///
/// This can be used to indicate an offset from the left in [TextDirection.ltr]
/// text and an offset from the right in [TextDirection.rtl] text without having
/// to be aware of the current text direction.
///
/// See also:
///
///  * [FractionalOffset], a variant that is defined in physical terms (i.e.
///    whose horizontal component does not depend on the text direction).
class FractionalOffsetDirectional extends FractionalOffsetGeometry {
  /// Creates a directional fractional offset.
  ///
  /// The [start] and [dy] arguments must not be null.
  const FractionalOffsetDirectional(this.start, this.dy)
    : assert(start != null),
      assert(dy != null);

  /// The distance fraction in the horizontal direction.
  ///
  /// A value of 0.0 corresponds to the edge on the "start" side, which is the
  /// left side in [TextDirection.ltr] contexts and the right side in
  /// [TextDirection.rtl] contexts. A value of 1.0 corresponds to the opposite
  /// edge, the "end" side. Values are not limited to that range; negative
  /// values represent positions beyond the start edge, and values greater than
  /// 1.0 represent positions beyond the end edge.
  ///
  /// This value is normalized into a [FractionalOffset.dx] value by the
  /// [resolve] method.
  final double start;

  @override
  double get _dxForRTL => 1.0 - start;

  @override
  double get _dxForLTR => start;

  /// The distance fraction in the vertical direction.
  ///
  /// A value of 0.0 corresponds to the topmost edge. A value of 1.0 corresponds
  /// to the bottommost edge. Values are not limited to that range; negative
  /// values represent positions above the top, and values greater than 1.0
  /// represent positions below the bottom.
  ///
  /// This value is passed through to [FractionalOffset.dy] unmodified by the
  /// [resolve] method.
  final double dy;

  @override
  double get _dy => dy;

  /// The top corner on the "start" side.
  static const FractionalOffsetDirectional topStart = const FractionalOffsetDirectional(0.0, 0.0);

  /// The center point along the top edge.
  ///
  /// Consider using [FractionalOffset.topCenter] instead, as it does not need
  /// to be [resolve]d to be used.
  static const FractionalOffsetDirectional topCenter = const FractionalOffsetDirectional(0.5, 0.0);

  /// The top corner on the "end" side.
  static const FractionalOffsetDirectional topEnd = const FractionalOffsetDirectional(1.0, 0.0);

  /// The center point along the "start" edge.
  static const FractionalOffsetDirectional centerStart = const FractionalOffsetDirectional(0.0, 0.5);

  /// The center point, both horizontally and vertically.
  ///
  /// Consider using [FractionalOffset.center] instead, as it does not need to
  /// be [resolve]d to be used.
  static const FractionalOffsetDirectional center = const FractionalOffsetDirectional(0.5, 0.5);

  /// The center point along the "end" edge.
  static const FractionalOffsetDirectional centerEnd = const FractionalOffsetDirectional(1.0, 0.5);

  /// The bottom corner on the "start" side.
  static const FractionalOffsetDirectional bottomStart = const FractionalOffsetDirectional(0.0, 1.0);

  /// The center point along the bottom edge.
  ///
  /// Consider using [FractionalOffset.bottomCenter] instead, as it does not
  /// need to be [resolve]d to be used.
  static const FractionalOffsetDirectional bottomCenter = const FractionalOffsetDirectional(0.5, 1.0);

  /// The bottom corner on the "end" side.
  static const FractionalOffsetDirectional bottomEnd = const FractionalOffsetDirectional(1.0, 1.0);

  @override
  FractionalOffsetGeometry subtract(FractionalOffsetGeometry other) {
    if (other is FractionalOffsetDirectional)
      return this - other;
    return super.subtract(other);
  }

  @override
  FractionalOffsetGeometry add(FractionalOffsetGeometry other) {
    if (other is FractionalOffsetDirectional)
      return this + other;
    return super.add(other);
  }

  /// Returns the difference between two [FractionalOffsetDirectional]s.
  FractionalOffsetDirectional operator -(FractionalOffsetDirectional other) {
    return new FractionalOffsetDirectional(start - other.start, dy - other.dy);
  }

  /// Returns the sum of two [FractionalOffsetDirectional]s.
  FractionalOffsetDirectional operator +(FractionalOffsetDirectional other) {
    return new FractionalOffsetDirectional(start + other.start, dy + other.dy);
  }

  /// Returns the negation of the given [FractionalOffsetDirectional].
  @override
  FractionalOffsetDirectional operator -() {
    return new FractionalOffsetDirectional(-start, -dy);
  }

  /// Scales the [FractionalOffsetDirectional] in each dimension by the given factor.
  @override
  FractionalOffsetDirectional operator *(double other) {
    return new FractionalOffsetDirectional(start * other, dy * other);
  }

  /// Divides the [FractionalOffsetDirectional] in each dimension by the given factor.
  @override
  FractionalOffsetDirectional operator /(double other) {
    return new FractionalOffsetDirectional(start / other, dy / other);
  }

  /// Integer divides the [FractionalOffsetDirectional] in each dimension by the given factor.
  @override
  FractionalOffsetDirectional operator ~/(double other) {
    return new FractionalOffsetDirectional((start ~/ other).toDouble(), (dy ~/ other).toDouble());
  }

  /// Computes the remainder in each dimension by the given factor.
  @override
  FractionalOffsetDirectional operator %(double other) {
    return new FractionalOffsetDirectional(start % other, dy % other);
  }

  /// Linearly interpolate between two [FractionalOffsetDirectional]s.
  ///
  /// If either is null, this function interpolates from [FractionalOffset.center].
  static FractionalOffsetDirectional lerp(FractionalOffsetDirectional a, FractionalOffsetDirectional b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return new FractionalOffsetDirectional(ui.lerpDouble(0.5, b.start, t), ui.lerpDouble(0.5, b.dy, t));
    if (b == null)
      return new FractionalOffsetDirectional(ui.lerpDouble(a.start, 0.5, t), ui.lerpDouble(a.dy, 0.5, t));
    return new FractionalOffsetDirectional(ui.lerpDouble(a.start, b.start, t), ui.lerpDouble(a.dy, b.dy, t));
  }

  @override
  String toString() {
    assert(start != 0.5);
    if (start == 0.0 && dy == 0.0)
      return 'FractionalOffsetDirectional.topStart';
    if (start == 1.0 && dy == 0.0)
      return 'FractionalOffsetDirectional.topEnd';
    if (start == 0.0 && dy == 0.5)
      return 'FractionalOffsetDirectional.centerStart';
    if (start == 1.0 && dy == 0.5)
      return 'FractionalOffsetDirectional.centerEnd';
    if (start == 0.0 && dy == 1.0)
      return 'FractionalOffsetDirectional.bottomStart';
    if (start == 1.0 && dy == 1.0)
      return 'FractionalOffsetDirectional.bottomEnd';
    return 'FractionalOffsetDirectional(${start.toStringAsFixed(1)}, '
                                       '${dy.toStringAsFixed(1)})';
  }
}

class _SchrodingersFractionalOffset extends FractionalOffsetGeometry {
  const _SchrodingersFractionalOffset(this._dxForRTL, this._dxForLTR, this._dy);

  @override
  final double _dxForRTL;

  @override
  final double _dxForLTR;

  @override
  final double _dy;

  @override
  _SchrodingersFractionalOffset operator -() {
    return new _SchrodingersFractionalOffset(
      -_dxForRTL,
      -_dxForLTR,
      -_dy,
    );
  }

  @override
  _SchrodingersFractionalOffset operator *(double other) {
    return new _SchrodingersFractionalOffset(
      _dxForRTL * other,
      _dxForLTR * other,
      _dy * other,
    );
  }

  @override
  _SchrodingersFractionalOffset operator /(double other) {
    return new _SchrodingersFractionalOffset(
      _dxForRTL / other,
      _dxForLTR / other,
      _dy / other,
    );
  }

  @override
  _SchrodingersFractionalOffset operator ~/(double other) {
    return new _SchrodingersFractionalOffset(
      (_dxForRTL ~/ other).toDouble(),
      (_dxForLTR ~/ other).toDouble(),
      (_dy ~/ other).toDouble(),
    );
  }

  @override
  _SchrodingersFractionalOffset operator %(double other) {
    return new _SchrodingersFractionalOffset(
      _dxForRTL % other,
      _dxForLTR % other,
      _dy % other,
    );
  }

  @override
  String toString() {
    if (_dxForRTL == _dxForLTR)
      return FractionalOffset._stringify(_dxForRTL, _dy);

    return '${FractionalOffset._stringify(_dxForRTL, _dy)} in RTL'
           ' or '
           '${FractionalOffset._stringify(_dxForLTR, _dy)} in LTR';
  }
}
