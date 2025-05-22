// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef RRECT_GLSL_
#define RRECT_GLSL_

#include <impeller/math.glsl>

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
float powerDistance(vec2 p, float exponent, float exponentInv) {
  float xp = POW(p.x, exponent);
  float yp = POW(p.y, exponent);
  return POW(xp + yp, exponentInv);
}

float computeRRectDistance(vec2 position,
                           vec2 adjust,
                           vec3 r1_exponent_exponentInv) {
  float r1 = r1_exponent_exponentInv[0];
  float exponent = r1_exponent_exponentInv[1];
  float exponentInv = r1_exponent_exponentInv[2];

  vec2 adjusted = position - adjust;
  float dPos = powerDistance(max(adjusted, 0.0), exponent, exponentInv);
  float dNeg = min(maxXY(adjusted), 0.0);
  return dPos + dNeg - r1;
}

float computeRRectFade(float d, vec3 sInv_minEdge_scale) {
  float sInv = sInv_minEdge_scale[0];
  float minEdge = sInv_minEdge_scale[1];
  float scale = sInv_minEdge_scale[2];
  return scale * (computeErf7(sInv * (minEdge + d)) - computeErf7(sInv * d));
}

#endif  // RRECT_GLSL_
