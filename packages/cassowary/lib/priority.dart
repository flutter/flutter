// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class Priority {
  static final double required = create(1e3, 1e3, 1e3);
  static final double strong = create(1.0, 0.0, 0.0);
  static final double medium = create(0.0, 1.0, 0.0);
  static final double weak = create(0.0, 0.0, 1.0);

  static double create(double a, double b, double c) {
    double result = 0.0;
    result += max(0.0, min(1e3, a)) * 1e6;
    result += max(0.0, min(1e3, b)) * 1e3;
    result += max(0.0, min(1e3, c));
    return result;
  }

  static double clamp(double value) {
    return max(0.0, min(required, value));
  }
}
