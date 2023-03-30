// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GAUSSIAN_GLSL_
#define GAUSSIAN_GLSL_

#include <impeller/constants.glsl>

/// Gaussian distribution function.
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

/// Vec2 variation for the Abramowitz and Stegun erf approximation.
vec2 IPVec2Erf(vec2 x) {
  vec2 a = abs(x);
  // 0.278393*x + 0.230389*x^2 + 0.078108*x^4 + 1
  vec2 b = (0.278393 + (0.230389 + 0.078108 * a * a) * a) * a + 1.0;
  return sign(x) * (1 - 1 / (b * b * b * b));
}

/// The indefinite integral of the Gaussian function.
/// Uses a very close approximation of Erf.
float IPGaussianIntegral(float x, float sigma) {
  // ( 1 + erf( x * (sqrt(2) / (2 * sigma) ) ) / 2
  return (1 + IPErf(x * (kHalfSqrtTwo / sigma))) * 0.5;
}

/// Vec2 variation for the indefinite integral of the Gaussian function.
/// Uses a very close approximation of Erf.
vec2 IPVec2GaussianIntegral(vec2 x, float sigma) {
  // ( 1 + erf( x * (sqrt(2) / (2 * sigma) ) ) / 2
  return (1 + IPVec2Erf(x * (kHalfSqrtTwo / sigma))) * 0.5;
}

/// Simpler (but less accurate) approximation of the Gaussian integral.
vec2 IPVec2FastGaussianIntegral(vec2 x, float sigma) {
  return 1 / (1 + exp(-kSqrtThree / sigma * x));
}

/// Simple logistic sigmoid with a domain of [-1, 1] and range of [0, 1].
float IPSigmoid(float x) {
  return 1.03731472073 / (1 + exp(-4 * x)) - 0.0186573603638;
}

#endif
