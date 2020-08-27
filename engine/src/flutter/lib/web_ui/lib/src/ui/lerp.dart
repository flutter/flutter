// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of ui;

double? lerpDouble(num? a, num? b, double t) {
  if (a == null && b == null) {
    return null;
  }
  a ??= 0.0;
  b ??= 0.0;
  return (a + (b - a) * t).toDouble();
}

double _lerpDouble(double a, double b, double t) {
  return a + (b - a) * t;
}

double _lerpInt(int a, int b, double t) {
  return a + (b - a) * t;
}
