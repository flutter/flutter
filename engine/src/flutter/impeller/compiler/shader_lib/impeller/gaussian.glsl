// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GAUSSIAN_GLSL_
#define GAUSSIAN_GLSL_

#include <impeller/constants.glsl>

float IPGaussian(float x, float sigma) {
  float variance = sigma * sigma;
  return exp(-0.5 * x * x / variance) / (kSqrtTwoPi * sigma);
}

/// Abramowitz and Stegun erf approximation.
float IPErf(float x) {
  float a = abs(x);
  // 0.278393*x + 0.230389*x^2 + 0.078108*x^4 + 1
  float b = (0.278393 + (0.230389 + 0.078108 * a * a) * a) * a + 1.0;
  return sign(x) * (1 - 1 / (b * b * b * b));
}

vec2 IPVec2Erf(vec2 x) {
  return vec2(IPErf(x.x), IPErf(x.y));
}

/// Indefinite integral of the Gaussian function (with constant range 0->1).
float IPGaussianIntegral(float x, float sigma) {
  // ( 1 + erf( x * (sqrt(2) / (2 * sigma) ) ) / 2
  // Because this sigmoid is always > 1, we remap it (n * 1.07 - 0.07)
  // so that it always fades to zero before it reaches the blur radius.
  return 0.535 * IPErf(x * (kHalfSqrtTwo / sigma)) + 0.465;
}

#endif
