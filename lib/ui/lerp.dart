// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

/// Linearly interpolate between two numbers.
num lerpDouble(num a, num b, double t) {
  if (a == null && b == null)
    return null;
  if (a == null)
    a = 0.0;
  if (b == null)
    b = 0.0;
  return a + (b - a) * t;
}
