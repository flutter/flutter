// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';

num lerpNum(num a, num b, double t) {
  if (a == null && b == null)
    return null;
  if (a == null)
    a = 0.0;
  if (b == null)
    b = 0.0;
  return a + (b - a) * t;
}

Color _scaleAlpha(Color a, double factor) {
  return a.withAlpha((a.alpha * factor).round());
}

Color lerpColor(Color a, Color b, double t) {
  if (a == null && b == null)
    return null;
  if (a == null)
    return _scaleAlpha(b, t);
  if (b == null)
    return _scaleAlpha(b, 1.0 - t);
  return new Color.fromARGB(
      lerpNum(a.alpha, b.alpha, t).toInt(),
      lerpNum(a.red, b.red, t).toInt(),
      lerpNum(a.green, b.green, t).toInt(),
      lerpNum(a.blue, b.blue, t).toInt());
}

Offset lerpOffset(Offset a, Offset b, double t) {
  if (a == null && b == null)
    return null;
  if (a == null)
    return b * t;
  if (b == null)
    return a * (1.0 - t);
  return new Offset(lerpNum(a.dx, b.dx, t), lerpNum(a.dy, b.dy, t));
}
