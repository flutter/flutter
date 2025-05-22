// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef RRECT_GLSL_
#define RRECT_GLSL_

const float kTwoOverSqrtPi = 2.0 / sqrt(3.1415926);

float maxXY(vec2 v) {
  return max(v.x, v.y);
}

// use crate::math::compute_erf7;
float computeErf7(float x) {
  x *= kTwoOverSqrtPi;
  float xx = x * x;
  x = x + (0.24295 + (0.03395 + 0.0104 * xx) * xx) * (x * xx);
  return x / sqrt(1.0 + x * x);
}

// The length formula, but with an exponent other than 2
float powerDistance(vec2 p) {
  float xp = POW(p.x, frag_info.exponent);
  float yp = POW(p.y, frag_info.exponent);
  return POW(xp + yp, frag_info.exponentInv);
}

float computeRRectDistance(vec2 position, vec2 adjust, float r1) {
  vec2 adjusted = position - frag_info.adjust;
  float dPos = powerDistance(max(adjusted, 0.0));
  float dNeg = min(maxXY(adjusted), 0.0);
  return dPos + dNeg - frag_info.r1;
}

float computeRRectFade(float d, float sInv, float minEdge, float scale) {
  return scale * (computeErf7(sInv * (minEdge + d)) -
                         computeErf7(sInv * d));
}

#endif  // RRECT_GLSL_
