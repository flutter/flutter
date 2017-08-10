// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show lerpDouble, WindowPadding;

import 'package:flutter/foundation.dart';

import 'basic_types.dart';

/// Base class for [EdgeInsets] that allows for text-direction aware
/// resolution.
///
/// A property or argument of this type accepts classes created either with [new
/// EdgeInsets.fromLTRB] and its variants, or [new EdgeInsetsDirectional].
///
/// To convert a [EdgeInsetsGeometry] object of indeterminate type into a
/// [EdgeInsets] object, call the [resolve] method.
///
/// See also:
///
///  * [Padding], a widget that describes margins using [EdgeInsetsGeometry].
abstract class EdgeInsetsGeometry {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const EdgeInsetsGeometry();

  /// Whether every dimension is non-negative.
  bool get isNonNegative;

  /// Convert this instance into a [EdgeInsets], which uses literal coordinates
  /// (i.e. the `left` coordinate being explicitly a distance from the left, and
  /// the `right` coordinate being explicitly a distance from the right).
  ///
  /// See also:
  ///
  ///  * [EdgeInsets], for which this is a no-op (returns itself).
  ///  * [EdgeInsetsDirectional], which flips the horizontal direction
  ///    based on the `direction` argument.
  EdgeInsets resolve(TextDirection direction);
}

/// An immutable set of offsets in each of the four cardinal directions.
///
/// Typically used for an offset from each of the four sides of a box. For
/// example, the padding inside a box can be represented using this class.
///
/// ## Sample code
///
/// Here are some examples of how to create [EdgeInsets] instances:
///
/// Typical eight-pixel margin on all sides:
///
/// ```dart
/// const EdgeInsets.all(8.0)
/// ```
///
/// Eight pixel margin above and below, no horizontal margins:
///
/// ```dart
/// const EdgeInsets.symmetric(vertical: 8.0)
/// ```
///
/// Left margin indent of 40 pixels:
///
/// ```dart
/// const EdgeInsets.only(left: 40.0)
/// ```
///
/// See also:
///
///  * [Padding], a widget that accepts [EdgeInsets] to describe its margins.
///  * [EdgeInsetsDirectional], which (for properties and arguments that accept
///    the type [EdgeInsetsGeometry]) allows the horizontal insets to be
///    specified in a [TextDirection]-aware manner.
@immutable
class EdgeInsets extends EdgeInsetsGeometry {
  /// Creates insets from offsets from the left, top, right, and bottom.
  const EdgeInsets.fromLTRB(this.left, this.top, this.right, this.bottom);

  /// Creates insets where all the offsets are `value`.
  ///
  /// ## Sample code
  ///
  /// Typical eight-pixel margin on all sides:
  ///
  /// ```dart
  /// const EdgeInsets.all(8.0)
  /// ```
  const EdgeInsets.all(double value)
      : left = value, top = value, right = value, bottom = value;

  /// Creates insets with only the given values non-zero.
  ///
  /// ## Sample code
  ///
  /// Left margin indent of 40 pixels:
  ///
  /// ```dart
  /// const EdgeInsets.only(left: 40.0)
  /// ```
  const EdgeInsets.only({
    this.left: 0.0,
    this.top: 0.0,
    this.right: 0.0,
    this.bottom: 0.0
  });

  /// Creates insets with symmetrical vertical and horizontal offsets.
  ///
  /// ## Sample code
  ///
  /// Eight pixel margin above and below, no horizontal margins:
  ///
  /// ```dart
  /// const EdgeInsets.symmetric(vertical: 8.0)
  /// ```
  const EdgeInsets.symmetric({ double vertical: 0.0,
                             double horizontal: 0.0 })
    : left = horizontal, top = vertical, right = horizontal, bottom = vertical;

  /// Creates insets that match the given window padding.
  ///
  /// If you need the current system padding in the context of a widget,
  /// consider using [MediaQuery.of] to obtain the current padding rather than
  /// using the value from [dart:ui.window], so that you get notified when it
  /// changes.
  EdgeInsets.fromWindowPadding(ui.WindowPadding padding, double devicePixelRatio)
    : left = padding.left / devicePixelRatio,
      top = padding.top / devicePixelRatio,
      right = padding.right / devicePixelRatio,
      bottom = padding.bottom / devicePixelRatio;

  /// The offset from the left.
  final double left;

  /// The offset from the top.
  final double top;

  /// The offset from the right.
  final double right;

  /// The offset from the bottom.
  final double bottom;

  /// An Offset describing the vector from the top left of a rectangle to the
  /// top left of that rectangle inset by this object.
  Offset get topLeft => new Offset(left, top);

  /// An Offset describing the vector from the top right of a rectangle to the
  /// top right of that rectangle inset by this object.
  Offset get topRight => new Offset(-right, top);

  /// An Offset describing the vector from the bottom left of a rectangle to the
  /// bottom left of that rectangle inset by this object.
  Offset get bottomLeft => new Offset(left, -bottom);

  /// An Offset describing the vector from the bottom right of a rectangle to the
  /// bottom right of that rectangle inset by this object.
  Offset get bottomRight => new Offset(-right, -bottom);

  @override
  bool get isNonNegative => left >= 0.0 && top >= 0.0 && right >= 0.0 && bottom >= 0.0;

  /// The total offset in the vertical direction.
  double get horizontal => left + right;

  /// The total offset in the horizontal direction.
  double get vertical => top + bottom;

  /// The total offset in the given direction.
  double along(Axis axis) {
    assert(axis != null);
    switch (axis) {
      case Axis.horizontal:
        return horizontal;
      case Axis.vertical:
        return vertical;
    }
    return null;
  }

  /// The size that this EdgeInsets would occupy with an empty interior.
  Size get collapsedSize => new Size(horizontal, vertical);

  /// An EdgeInsets with top and bottom as well as left and right flipped.
  EdgeInsets get flipped => new EdgeInsets.fromLTRB(right, bottom, left, top);

  /// Returns a new rect that is bigger than the given rect in each direction by
  /// the amount of inset in each direction. Specifically, the left edge of the
  /// rect is moved left by [left], the top edge of the rect is moved up by
  /// [top], the right edge of the rect is moved right by [right], and the
  /// bottom edge of the rect is moved down by [bottom].
  ///
  /// See also:
  ///
  ///  * [inflateSize], to inflate a [Size] rather than a [Rect].
  ///  * [deflateRect], to deflate a [Rect] rather than inflating it.
  Rect inflateRect(Rect rect) {
    return new Rect.fromLTRB(rect.left - left, rect.top - top, rect.right + right, rect.bottom + bottom);
  }

  /// Returns a new rect that is smaller than the given rect in each direction by
  /// the amount of inset in each direction. Specifically, the left edge of the
  /// rect is moved right by [left], the top edge of the rect is moved down by
  /// [top], the right edge of the rect is moved left by [right], and the
  /// bottom edge of the rect is moved up by [bottom].
  ///
  /// If the argument's [Rect.size] is smaller than [collapsedSize], then the
  /// resulting rectangle will have negative dimensions.
  ///
  /// See also:
  ///
  ///  * [deflateSize], to deflate a [Size] rather than a [Rect].
  ///  * [inflateRect], to inflate a [Rect] rather than deflating it.
  Rect deflateRect(Rect rect) {
    return new Rect.fromLTRB(rect.left + left, rect.top + top, rect.right - right, rect.bottom - bottom);
  }

  /// Returns a new size that is bigger than the given size by the amount of
  /// inset in the horizontal and vertical directions.
  ///
  /// See also:
  ///
  ///  * [inflateRect], to inflate a [Rect] rather than a [Size].
  ///  * [deflateSize], to deflate a [Size] rather than inflating it.
  Size inflateSize(Size size) {
    return new Size(size.width + horizontal, size.height + vertical);
  }

  /// Returns a new size that is smaller than the given size by the amount of
  /// inset in the horizontal and vertical directions.
  ///
  /// If the argument is smaller than [collapsedSize], then the resulting size
  /// will have negative dimensions.
  ///
  /// See also:
  ///
  ///  * [deflateRect], to deflate a [Rect] rather than a [Size].
  ///  * [inflateSize], to inflate a [Size] rather than deflating it.
  Size deflateSize(Size size) {
    return new Size(size.width - horizontal, size.height - vertical);
  }

  /// Returns the difference between two EdgeInsets.
  EdgeInsets operator -(EdgeInsets other) {
    return new EdgeInsets.fromLTRB(
      left - other.left,
      top - other.top,
      right - other.right,
      bottom - other.bottom
    );
  }

  /// Returns the sum of two EdgeInsets.
  EdgeInsets operator +(EdgeInsets other) {
    return new EdgeInsets.fromLTRB(
      left + other.left,
      top + other.top,
      right + other.right,
      bottom + other.bottom
    );
  }

  /// Scales the EdgeInsets in each dimension by the given factor.
  EdgeInsets operator *(double other) {
    return new EdgeInsets.fromLTRB(
      left * other,
      top * other,
      right * other,
      bottom * other
    );
  }

  /// Divides the EdgeInsets in each dimension by the given factor.
  EdgeInsets operator /(double other) {
    return new EdgeInsets.fromLTRB(
      left / other,
      top / other,
      right / other,
      bottom / other
    );
  }

  /// Integer divides the EdgeInsets in each dimension by the given factor.
  EdgeInsets operator ~/(double other) {
    return new EdgeInsets.fromLTRB(
      (left ~/ other).toDouble(),
      (top ~/ other).toDouble(),
      (right ~/ other).toDouble(),
      (bottom ~/ other).toDouble()
    );
  }

  /// Computes the remainder in each dimension by the given factor.
  EdgeInsets operator %(double other) {
    return new EdgeInsets.fromLTRB(
      left % other,
      top % other,
      right % other,
      bottom % other
    );
  }

  /// Linearly interpolate between two EdgeInsets.
  ///
  /// If either is null, this function interpolates from [EdgeInsets.zero].
  static EdgeInsets lerp(EdgeInsets a, EdgeInsets b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return b * t;
    if (b == null)
      return a * (1.0 - t);
    return new EdgeInsets.fromLTRB(
      ui.lerpDouble(a.left, b.left, t),
      ui.lerpDouble(a.top, b.top, t),
      ui.lerpDouble(a.right, b.right, t),
      ui.lerpDouble(a.bottom, b.bottom, t)
    );
  }

  /// An EdgeInsets with zero offsets in each direction.
  static const EdgeInsets zero = const EdgeInsets.all(0.0);

  @override
  EdgeInsets resolve(TextDirection direction) => this;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other.runtimeType != runtimeType)
      return false;
    final EdgeInsets typedOther = other;
    return left == typedOther.left &&
           top == typedOther.top &&
           right == typedOther.right &&
           bottom == typedOther.bottom;
  }

  @override
  int get hashCode => hashValues(left, top, right, bottom);

  @override
  String toString() => '$runtimeType($left, $top, $right, $bottom)';
}

/// An immutable set of offsets in each of the four cardinal directions, but
/// whose horizontal components are dependent on the writing direction.
///
/// This can be used to indicate padding from the left in [TextDirection.ltr]
/// text and padding from the right in [TextDirection.rtl] text without having
/// to be aware of the current text direction.
class EdgeInsetsDirectional extends EdgeInsetsGeometry {
  /// Creates insets from offsets from the start, top, end, and bottom.
  const EdgeInsetsDirectional.fromSTEB(this.start, this.top, this.end, this.bottom);

  /// Creates insets with only the given values non-zero.
  ///
  /// ## Sample code
  ///
  /// A margin indent of 40 pixels on the leading side:
  ///
  /// ```dart
  /// const EdgeInsetsDirectional.only(start: 40.0)
  /// ```
  const EdgeInsetsDirectional.only({
    this.start: 0.0,
    this.top: 0.0,
    this.end: 0.0,
    this.bottom: 0.0
  });

  /// The offset from the start side, the side from which the user will start
  /// reading text.
  ///
  /// This value is normalized into an [EdgeInsets.left] or [EdgeInsets.right]
  /// value by the [resolve] method.
  final double start;

  /// The offset from the top.
  ///
  /// This value is passed through to [EdgeInsets.top] unmodified by the
  /// [resolve] method.
  final double top;

  /// The offset from the end side, the side on which the user ends reading
  /// text.
  ///
  /// This value is normalized into an [EdgeInsets.left] or [EdgeInsets.right]
  /// value by the [resolve] method.
  final double end;

  /// The offset from the bottom.
  ///
  /// This value is passed through to [EdgeInsets.bottom] unmodified by the
  /// [resolve] method.
  final double bottom;

  @override
  bool get isNonNegative => start >= 0.0 && top >= 0.0 && end >= 0.0 && bottom >= 0.0;

  @override
  EdgeInsets resolve(TextDirection direction) {
    assert(direction != null);
    switch (direction) {
      case TextDirection.ltr:
        return new EdgeInsets.fromLTRB(start, top, end, bottom);
      case TextDirection.rtl:
        return new EdgeInsets.fromLTRB(end, top, start, bottom);
    }
    return null;
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final EdgeInsetsDirectional typedOther = other;
    return start == typedOther.start &&
           top == typedOther.top &&
           end == typedOther.end &&
           bottom == typedOther.bottom;
  }

  @override
  int get hashCode => hashValues(start, top, end, bottom);

  @override
  String toString() => '$runtimeType($start, $top, $end, $bottom)';
}
