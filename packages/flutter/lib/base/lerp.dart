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
    return _scaleAlpha(a, 1.0 - t);
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

Rect lerpRect(Rect a, Rect b, double t) {
  if (a == null && b == null)
    return null;
  if (a == null)
    return new Rect.fromLTRB(b.left * t, b.top * t, b.right * t, b.bottom * t);
  if (b == null) {
    double k = 1.0 - t;
    return new Rect.fromLTRB(b.left * k, b.top * k, b.right * k, b.bottom * k);
  }
  return new Rect.fromLTRB(
    lerpNum(a.left, b.left, t),
    lerpNum(a.top, b.top, t),
    lerpNum(a.right, b.right, t),
    lerpNum(a.bottom, b.bottom, t));
}
