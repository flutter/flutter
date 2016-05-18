// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show lerpDouble, WindowPadding;

import 'basic_types.dart';

/// An immutable set of offsets in each of the four cardinal directions.
///
/// Typically used for an offset from each of the four sides of a box. For
/// example, the padding inside a box can be represented using this class.
class EdgeInsets {
  /// Creates insets from offsets from the left, top, right, and bottom.
  const EdgeInsets.fromLTRB(this.left, this.top, this.right, this.bottom);

  /// Creates insets where all the offsets are value.
  const EdgeInsets.all(double value)
      : left = value, top = value, right = value, bottom = value;

  /// Creates insets with only the given values non-zero.
  const EdgeInsets.only({
    this.left: 0.0,
    this.top: 0.0,
    this.right: 0.0,
    this.bottom: 0.0
  });

  /// Creates insets with symmetrical vertical and horizontal offsets.
  const EdgeInsets.symmetric({ double vertical: 0.0,
                             double horizontal: 0.0 })
    : left = horizontal, top = vertical, right = horizontal, bottom = vertical;

  /// Creates insets that match the given window padding.
  EdgeInsets.fromWindowPadding(ui.WindowPadding padding)
    : left = padding.left, top = padding.top, right = padding.right, bottom = padding.bottom;

  /// The offset from the left.
  final double left;

  /// The offset from the top.
  final double top;

  /// The offset from the right.
  final double right;

  /// The offset from the bottom.
  final double bottom;

  /// Whether every dimension is non-negative.
  bool get isNonNegative => left >= 0.0 && top >= 0.0 && right >= 0.0 && bottom >= 0.0;

  /// The total offset in the vertical direction.
  double get horizontal => left + right;

  /// The total offset in the horizontal direction.
  double get vertical => top + bottom;

  /// The size that this EdgeInsets would occupy with an empty interior.
  Size get collapsedSize => new Size(horizontal, vertical);

  /// An EdgeInsets with top and bottom as well as left and right flipped.
  EdgeInsets get flipped => new EdgeInsets.fromLTRB(left, top, right, bottom);

  /// Returns a new rect that is bigger than the given rect in each direction by
  /// the amount of inset in each direction. Specifically, the left edge of the
  /// rect is moved left by [left], the top edge of the rect is moved up by
  /// [top], the right edge of the rect is moved right by [right], and the
  /// bottom edge of the rect is moved down by [bottom].
  Rect inflateRect(Rect rect) {
    return new Rect.fromLTRB(rect.left - left, rect.top - top, rect.right + right, rect.bottom + bottom);
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
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! EdgeInsets)
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
  String toString() => "EdgeInsets($left, $top, $right, $bottom)";
}
