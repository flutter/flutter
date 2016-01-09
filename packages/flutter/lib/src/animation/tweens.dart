// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Color, Size, Rect;

import 'curves.dart';
import 'performance.dart';

class ColorTween extends Tween<Color> {
  ColorTween({ Color begin,  Color end, Curve curve, Curve reverseCurve })
    : super(begin: begin, end: end, curve: curve, reverseCurve: reverseCurve);

  Color lerp(double t) => Color.lerp(begin, end, t);
}

class SizeTween extends Tween<Size> {
  SizeTween({ Size begin,  Size end, Curve curve, Curve reverseCurve })
    : super(begin: begin, end: end, curve: curve, reverseCurve: reverseCurve);

  Size lerp(double t) => Size.lerp(begin, end, t);
}

class RectTween extends Tween<Rect> {
  RectTween({ Rect begin,  Rect end, Curve curve, Curve reverseCurve })
    : super(begin: begin, end: end, curve: curve, reverseCurve: reverseCurve);

  Rect lerp(double t) => Rect.lerp(begin, end, t);
}

class IntTween extends Tween<int> {
  IntTween({ int begin,  int end, Curve curve, Curve reverseCurve })
  : super(begin: begin, end: end, curve: curve, reverseCurve: reverseCurve);

  // The inherited lerp() function doesn't work with ints because it multiplies
  // the begin and end types by a double, and int * double returns a double.
  int lerp(double t) => (begin + (end - begin) * t).round();
}
