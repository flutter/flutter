// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show lerpDouble;

import 'basic_types.dart';

/// An immutable set of offsets in each of the four cardinal directions.
///
/// Typically used for an offset from each of the four sides of a box. For
/// example, the padding inside a box can be represented using this class.
class EdgeInsets {
  /// Constructs insets from offsets from the top, right, bottom and left.
  ///
  /// We'll be removing this function sometime soon. Please use
  /// [EdgeInsets.fromLTRB] instead.
  @Deprecated('soon. Use fromLTRB instead.')
  const EdgeInsets.TRBL(this.top, this.right, this.bottom, this.left);

  /// Constructs insets from offsets from the left, top, right, and bottom.
  const EdgeInsets.fromLTRB(this.left, this.top, this.right, this.bottom);

  /// Constructs insets where all the offsets are value.
  const EdgeInsets.all(double value)
      : top = value, right = value, bottom = value, left = value;

  /// Constructs insets with only the given values non-zero.
  const EdgeInsets.only({
    this.top: 0.0,
    this.right: 0.0,
    this.bottom: 0.0,
    this.left: 0.0
  });

  /// Constructs insets with symmetrical vertical and horizontal offsets.
  const EdgeInsets.symmetric({ double vertical: 0.0,
                             double horizontal: 0.0 })
    : top = vertical, left = horizontal, bottom = vertical, right = horizontal;

  /// The offset from the top.
  final double top;

  /// The offset from the right.
  final double right;

  /// The offset from the bottom.
  final double bottom;

  /// The offset from the left.
  final double left;

  /// Whether every dimension is non-negative.
  bool get isNonNegative => top >= 0.0 && right >= 0.0 && bottom >= 0.0 && left >= 0.0;

  /// The total offset in the vertical direction.
  double get horizontal => left + right;

  /// The total offset in the horizontal direction.
  double get vertical => top + bottom;

  /// The size that this EdgeInsets would occupy with an empty interior.
  Size get collapsedSize => new Size(horizontal, vertical);

  /// An EdgeInsets with top and bottom as well as left and right flipped.
  EdgeInsets get flipped => new EdgeInsets.fromLTRB(left, top, right, bottom);

  Rect inflateRect(Rect rect) {
    return new Rect.fromLTRB(rect.left - left, rect.top - top, rect.right + right, rect.bottom + bottom);
  }

  EdgeInsets operator -(EdgeInsets other) {
    return new EdgeInsets.fromLTRB(
      left - other.left,
      top - other.top,
      right - other.right,
      bottom - other.bottom
    );
  }

  EdgeInsets operator +(EdgeInsets other) {
    return new EdgeInsets.fromLTRB(
      left + other.left,
      top + other.top,
      right + other.right,
      bottom + other.bottom
    );
  }

  EdgeInsets operator *(double other) {
    return new EdgeInsets.fromLTRB(
      left * other,
      top * other,
      right * other,
      bottom * other
    );
  }

  EdgeInsets operator /(double other) {
    return new EdgeInsets.fromLTRB(
      left / other,
      top / other,
      right / other,
      bottom / other
    );
  }

  EdgeInsets operator ~/(double other) {
    return new EdgeInsets.fromLTRB(
      (left ~/ other).toDouble(),
      (top ~/ other).toDouble(),
      (right ~/ other).toDouble(),
      (bottom ~/ other).toDouble()
    );
  }

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
    return top == typedOther.top &&
           right == typedOther.right &&
           bottom == typedOther.bottom &&
           left == typedOther.left;
  }

  @override
  int get hashCode => hashValues(top, left, bottom, right);

  @override
  String toString() => "EdgeInsets($top, $right, $bottom, $left)";
}
