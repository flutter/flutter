// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'dart:ui' show hashValues;

/// An immutable set of offsets in each of the four cardinal directions.
///
/// Typically used for an offset from each of the four sides of a box. For
/// example, the padding inside a box can be represented using this class.
class EdgeDims {
  /// Constructs an EdgeDims from offsets from the top, right, bottom and left.
  const EdgeDims.TRBL(this.top, this.right, this.bottom, this.left);

  /// Constructs an EdgeDims where all the offsets are value.
  const EdgeDims.all(double value)
      : top = value, right = value, bottom = value, left = value;

  /// Constructs an EdgeDims with only the given values non-zero.
  const EdgeDims.only({ this.top: 0.0,
                        this.right: 0.0,
                        this.bottom: 0.0,
                        this.left: 0.0 });

  /// Constructs an EdgeDims with symmetrical vertical and horizontal offsets.
  const EdgeDims.symmetric({ double vertical: 0.0,
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

  /// The size that this edge dims would occupy with an empty interior.
  ui.Size get collapsedSize => new ui.Size(left + right, top + bottom);

  ui.Rect inflateRect(ui.Rect rect) {
    return new ui.Rect.fromLTRB(rect.left - left, rect.top - top, rect.right + right, rect.bottom + bottom);
  }

  EdgeDims operator -(EdgeDims other) {
    return new EdgeDims.TRBL(
      top - other.top,
      right - other.right,
      bottom - other.bottom,
      left - other.left
    );
  }

  EdgeDims operator +(EdgeDims other) {
    return new EdgeDims.TRBL(
      top + other.top,
      right + other.right,
      bottom + other.bottom,
      left + other.left
    );
  }

  EdgeDims operator *(double other) {
    return new EdgeDims.TRBL(
      top * other,
      right * other,
      bottom * other,
      left * other
    );
  }

  EdgeDims operator /(double other) {
    return new EdgeDims.TRBL(
      top / other,
      right / other,
      bottom / other,
      left / other
    );
  }

  EdgeDims operator ~/(double other) {
    return new EdgeDims.TRBL(
      (top ~/ other).toDouble(),
      (right ~/ other).toDouble(),
      (bottom ~/ other).toDouble(),
      (left ~/ other).toDouble()
    );
  }

  EdgeDims operator %(double other) {
    return new EdgeDims.TRBL(
      top % other,
      right % other,
      bottom % other,
      left % other
    );
  }

  /// Linearly interpolate between two EdgeDims.
  ///
  /// If either is null, this function interpolates from [EdgeDims.zero].
  static EdgeDims lerp(EdgeDims a, EdgeDims b, double t) {
    if (a == null && b == null)
      return null;
    if (a == null)
      return b * t;
    if (b == null)
      return a * (1.0 - t);
    return new EdgeDims.TRBL(
      ui.lerpDouble(a.top, b.top, t),
      ui.lerpDouble(a.right, b.right, t),
      ui.lerpDouble(a.bottom, b.bottom, t),
      ui.lerpDouble(a.left, b.left, t)
    );
  }

  /// An EdgeDims with zero offsets in each direction.
  static const EdgeDims zero = const EdgeDims.TRBL(0.0, 0.0, 0.0, 0.0);

  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! EdgeDims)
      return false;
    final EdgeDims typedOther = other;
    return top == typedOther.top &&
           right == typedOther.right &&
           bottom == typedOther.bottom &&
           left == typedOther.left;
  }

  int get hashCode => hashValues(top, left, bottom, right);

  String toString() => "EdgeDims($top, $right, $bottom, $left)";
}
