// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

bool _nearZero(double value) {
  const double epsilon = 1.0e-8;
  return value < 0.0 ? -value < epsilon : value < epsilon;
}

class _Pair<X, Y> {
  X first;
  Y second;
  _Pair(this.first, this.second);
}
