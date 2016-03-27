// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

bool nearEqual(double a, double b, double epsilon) {
  assert(epsilon >= 0.0);
  return (a > (b - epsilon)) && (a < (b + epsilon));
}

bool nearZero(double a, double epsilon) => nearEqual(a, 0.0, epsilon);
