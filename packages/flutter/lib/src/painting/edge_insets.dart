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
  /// Constructs insets from offsets from the left, top, right, and bottom.
  const EdgeInsets.fromLTRB(this.left, this.top, this.right, this.bottom);

  /// Constructs insets where all the offsets are value.
  const EdgeInsets.all(double value)
      : left = value, top = value, right = value, bottom = value;

  /// Constructs insets with only the given values non-zero.
  const EdgeInsets.only({
    this.left: 0.0,
    this.top: 0.0,
    this.right: 0.0,
    this.bottom: 0.0
  });

  /// Constructs insets with symmetrical vertical and horizontal offsets.
  const EdgeInsets.symmetric({ double vertical: 0.0,
                             double horizontal: 0.0 })
    : left = horizontal, top = vertical, right = horizontal, bottom = vertical;

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
