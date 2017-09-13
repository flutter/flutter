// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic_types.dart';

/// An immutable set of radii for each corner of a rectangle.
///
/// Used by [BoxDecoration] when the shape is a [BoxShape.rectangle].
@immutable
class BorderRadius {
  /// Creates a border radius where all radii are [radius].
  const BorderRadius.all(Radius radius) : this.only(
    topLeft: radius,
    topRight: radius,
    bottomRight: radius,
    bottomLeft: radius
  );

  /// Creates a border radius where all radii are [Radius.circular(radius)].
  BorderRadius.circular(double radius) : this.all(
    new Radius.circular(radius)
  );

  /// Creates a vertically symmetric border radius where the top and bottom
  /// sides of the rectangle have the same radii.
  const BorderRadius.vertical({
    Radius top: Radius.zero,
    Radius bottom: Radius.zero
  }) : this.only(
    topLeft: top,
    topRight: top,
    bottomRight: bottom,
    bottomLeft: bottom
  );

  /// Creates a horizontally symmetrical border radius where the left and right
  /// sides of the rectangle have the same radii.
  const BorderRadius.horizontal({
    Radius left: Radius.zero,
    Radius right: Radius.zero
  }) : this.only(
    topLeft: left,
    topRight: right,
    bottomRight: right,
    bottomLeft: left
  );

  /// Creates a border radius with only the given non-zero values. The other
  /// corners will be right angles.
  const BorderRadius.only({
    this.topLeft: Radius.zero,
    this.topRight: Radius.zero,
    this.bottomRight: Radius.zero,
    this.bottomLeft: Radius.zero
  });

  /// A border radius with all zero radii.
  static const BorderRadius zero = const BorderRadius.all(Radius.zero);

  /// The top-left [Radius].
  final Radius topLeft;
  /// The top-right [Radius].
  final Radius topRight;
  /// The bottom-right [Radius].
  final Radius bottomRight;
  /// The bottom-left [Radius].
  final Radius bottomLeft;

  /// Linearly interpolates between two [BorderRadius] objects.
  ///
  /// If either is null, this function interpolates from [BorderRadius.zero].
  static BorderRadius lerp(BorderRadius a, BorderRadius b, double t) {
    if (a == null && b == null)
      return null;
    return new BorderRadius.only(
      topLeft: Radius.lerp(a.topLeft, b.topLeft, t),
      topRight: Radius.lerp(a.topRight, b.topRight, t),
      bottomRight: Radius.lerp(a.bottomRight, b.bottomRight, t),
      bottomLeft: Radius.lerp(a.bottomLeft, b.bottomLeft, t)
    );
  }

  /// Creates a [RRect] from the current border radius and a [Rect].
  RRect toRRect(Rect rect) {
    return new RRect.fromRectAndCorners(
      rect,
      topLeft: topLeft,
      topRight: topRight,
      bottomRight: bottomRight,
      bottomLeft: bottomLeft
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (runtimeType != other.runtimeType)
      return false;
    final BorderRadius typedOther = other;
    return topLeft == typedOther.topLeft &&
           topRight == typedOther.topRight &&
           bottomRight == typedOther.bottomRight &&
           bottomLeft == typedOther.bottomLeft;
  }

  @override
  int get hashCode => hashValues(topLeft, topRight, bottomRight, bottomLeft);

  @override
  String toString() {
    if (topLeft == topRight &&
        topRight == bottomRight &&
        bottomRight == bottomLeft) {
      if (topLeft == Radius.zero)
        return 'BorderRadius.zero';
      if (topLeft.x == topLeft.y)
        return 'BorderRadius.circular(${topLeft.x.toStringAsFixed(1)})';
      return 'BorderRadius.all($topLeft)';
    }
    if (topLeft == Radius.zero ||
        topRight == Radius.zero ||
        bottomLeft == Radius.zero ||
        bottomRight == Radius.zero) {
      final StringBuffer result = new StringBuffer();
      result.write('BorderRadius.only(');
      bool comma = false;
      if (topLeft != Radius.zero) {
        result.write('topLeft: $topLeft');
        comma = true;
      }
      if (topRight != Radius.zero) {
        if (comma)
          result.write(', ');
        result.write('topRight: $topRight');
        comma = true;
      }
      if (bottomLeft != Radius.zero) {
        if (comma)
          result.write(', ');
        result.write('bottomLeft: $bottomLeft');
        comma = true;
      }
      if (bottomRight != Radius.zero) {
        if (comma)
          result.write(', ');
        result.write('bottomRight: $bottomRight');
      }
      result.write(')');
      return result.toString();
    }
    return 'BorderRadius($topLeft, $topRight, $bottomRight, $bottomLeft)';
  }
}
