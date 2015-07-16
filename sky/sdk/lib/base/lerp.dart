// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky';

num lerpNum(num a, num b, double t) => a + (b - a) * t;

Color lerpColor(Color a, Color b, double t) {
  return new Color.fromARGB(
      lerpNum(a.alpha, b.alpha, t).toInt(),
      lerpNum(a.red, b.red, t).toInt(),
      lerpNum(a.green, b.green, t).toInt(),
      lerpNum(a.blue, b.blue, t).toInt());
}

Offset lerpOffset(Offset a, Offset b, double t) {
  return new Offset(lerpNum(a.dx, b.dx, t), lerpNum(a.dy, b.dy, t));
}
