// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GRADIENT_GLSL_
#define GRADIENT_GLSL_

#include <impeller/texture.glsl>

/// Compute the t value for a conical gradient at point `p` between the 2
/// circles defined by (c0, r0) and (c1, r1).
///
/// This assumes that c0 != c1.
float IPComputeConicalT(vec2 c0, float r0, vec2 c1, float r1, vec2 p) {
  float w = 1.0;
  float result = 0.0;
  vec2 ab = c1 - c0;
  float dr = r1 - r0;
  // Set sample rate to a minimum for the case where c0 and c1 are close.
  float delta = 1.0 / max(length(ab), 100.0);
  while (w >= 0.0) {
    vec2 cw = w * ab + c0;
    float rw = w * dr + r0;
    if (length(p - cw) <= rw) {
      result = w;
      break;
    }
    w -= delta;
  }
  return 1.0 - result;
}

/// Compute the indexes and mix coefficient used to mix colors for an
/// arbitrarily sized color gradient.
///
/// The returned values are the lower index, upper index, and mix
/// coefficient.
vec3 IPComputeFixedGradientValues(float t, float colors_length) {
  float rough_index = (colors_length - 1) * t;
  float lower_index = floor(rough_index);
  float upper_index = ceil(rough_index);
  float scale = rough_index - lower_index;

  return vec3(lower_index, upper_index, scale);
}

#endif
