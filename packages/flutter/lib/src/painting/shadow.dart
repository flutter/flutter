// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' as ui show lerpDouble, TextShadow;

import 'package:flutter/foundation.dart';

import 'basic_types.dart';
import 'debug.dart';

/// A shadow.
///
/// See also:
///
///  * [Canvas.drawShadow], which is a more efficient way to draw shadows.
///  * [BoxShadow], an extension of Shadow that includes a spreadRadius and can cast
///    non-rectangular shadows.
@immutable
class Shadow {
  /// Creates a shadow.
  ///
  /// By default, the shadow is solid black with zero [offset], and [blurRadius]
  const Shadow({
    this.color = const Color(0xFF000000),
    this.offset = Offset.zero,
    this.blurRadius = 0.0,
  });

  /// The color of the shadow.
  final Color color;

  /// The displacement of the shadow from the casting element.
  final Offset offset;

  /// The standard deviation of the Gaussian to convolve with the shadow's shape.
  final double blurRadius;

  // Obtain a dart:ui equivalent of this shadow.
  ui.TextShadow convertToDartUiTextShadow() {
    return ui.TextShadow(color: color, offset: offset, blurRadius: blurRadius);
  }

  /// Converts a blur radius in pixels to sigmas.
  ///
  /// See the sigma argument to [MaskFilter.blur].
  //
  // See SkBlurMask::ConvertRadiusToSigma().
  // <https://github.com/google/skia/blob/bb5b77db51d2e149ee66db284903572a5aac09be/src/effects/SkBlurMask.cpp#L23>
  static double convertRadiusToSigma(double radius) {
    return radius * 0.57735 + 0.5;
  }

  /// The [blurRadius] in sigmas instead of logical pixels.
  ///
  /// See the sigma argument to [MaskFilter.blur].
  double get blurSigma => convertRadiusToSigma(blurRadius);

  /// Create the [Paint] object that corresponds to this shadow description.
  ///
  /// The [offset] is not represented in the [Paint] object.
  /// To honor this as well, the shape should be translated by [offset] before
  /// being filled using this [Paint].
  Paint toPaint() {
    final Paint result = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
    assert(() {
      if (debugDisableShadows)
        result.maskFilter = null;
      return true;
    }());
    return result;
  }

  /// Returns a new box shadow with its offset and blurRadius scaled by the given factor.
  Shadow scale(double factor) {
    return Shadow(
      color: color,
      offset: offset * factor,
      blurRadius: blurRadius * factor,
    );
  }

  /// Linearly interpolate between two shadows.
  ///
  /// If either shadow is null, this function linearly interpolates from a
  /// a shadow that matches the other shadow in color but has a zero
  /// offset and a zero blurRadius.
  ///
  /// {@macro flutter.material.themeData.lerp}
  static Shadow lerp(Shadow a, Shadow b, double t) {
    assert(t != null);
    if (a == null && b == null)
      return null;
    if (a == null)
      return b.scale(t);
    if (b == null)
      return a.scale(1.0 - t);
    return Shadow(
      color: Color.lerp(a.color, b.color, t),
      offset: Offset.lerp(a.offset, b.offset, t),
      blurRadius: ui.lerpDouble(a.blurRadius, b.blurRadius, t),
    );
  }

  /// Linearly interpolate between two lists of shadows.
  ///
  /// If the lists differ in length, excess items are lerped with null.
  ///
  /// {@macro flutter.material.themeData.lerp}
  static List<Shadow> lerpList(List<Shadow> a, List<Shadow> b, double t) {
    assert(t != null);
    if (a == null && b == null)
      return null;
    a ??= <Shadow>[];
    b ??= <Shadow>[];
    final List<Shadow> result = <Shadow>[];
    final int commonLength = math.min(a.length, b.length);
    for (int i = 0; i < commonLength; i += 1)
      result.add(Shadow.lerp(a[i], b[i], t));
    for (int i = commonLength; i < a.length; i += 1)
      result.add(a[i].scale(1.0 - t));
    for (int i = commonLength; i < b.length; i += 1)
      result.add(b[i].scale(t));
    return result;
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (runtimeType != other.runtimeType)
      return false;
    final Shadow typedOther = other;
    return color == typedOther.color &&
           offset == typedOther.offset &&
           blurRadius == typedOther.blurRadius;
  }

    // Compares the shadows to see if they are different.
  static bool shadowsListEquals(List<Shadow> b, List<Shadow> a) {
        // Compare _shadows
    if (a == null && b == null)
      return true;
    if (a != null && b == null ||
      a == null && b != null)
      return false;
    if (a.length != b.length)
      return false;
    for (int index = 0; index < a.length; ++index)
      if (a[index] != b[index])
        return false;
    return true;
  }

  @override
  int get hashCode => hashValues(color, offset, blurRadius);

  @override
  String toString() => 'Shadow($color, $offset, $blurRadius)';
}
