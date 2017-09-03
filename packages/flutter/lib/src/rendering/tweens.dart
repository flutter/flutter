// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// An interpolation between two fractional offsets.
///
/// This class specializes the interpolation of Tween<FractionalOffset> to be
/// appropriate for rectangles.
///
/// See [Tween] for a discussion on how to use interpolation objects.
///
/// See also:
///
///  * [FractionalOffsetGeometryTween], which interpolates between two
///    [FractionalOffsetGeometry] objects.
class FractionalOffsetTween extends Tween<FractionalOffset> {
  /// Creates a fractional offset tween.
  ///
  /// The [begin] and [end] properties may be null; the null value
  /// is treated as meaning the center.
  FractionalOffsetTween({ FractionalOffset begin, FractionalOffset end })
    : super(begin: begin, end: end);

  /// Returns the value this variable has at the given animation clock value.
  @override
  FractionalOffset lerp(double t) => FractionalOffset.lerp(begin, end, t);
}

/// An interpolation between two [FractionalOffsetGeometry].
///
/// This class specializes the interpolation of [Tween<FractionalOffsetGeometry>]
/// to be appropriate for rectangles.
///
/// See [Tween] for a discussion on how to use interpolation objects.
///
/// See also:
///
///  * [FractionalOffsetTween], which interpolates between two
///    [FractionalOffset] objects.
class FractionalOffsetGeometryTween extends Tween<FractionalOffsetGeometry> {
  /// Creates a fractional offset geometry tween.
  ///
  /// The [begin] and [end] properties may be null; the null value
  /// is treated as meaning the center.
  FractionalOffsetGeometryTween({
    FractionalOffsetGeometry begin,
    FractionalOffsetGeometry end,
  }) : super(begin: begin, end: end);

  /// Returns the value this variable has at the given animation clock value.
  @override
  FractionalOffsetGeometry lerp(double t) => FractionalOffsetGeometry.lerp(begin, end, t);
}
