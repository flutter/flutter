// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/constants.glsl>
#include <impeller/branching.glsl>

vec3 BlendScreen(vec3 dst, vec3 src) {
  return dst + src - (dst * src);
}

vec3 BlendHardLight(vec3 dst, vec3 src) {
  return IPVec3Choose(dst * (2 * src), BlendScreen(dst, 2 * src - 1), src);
}

//------------------------------------------------------------------------------
// HSV utilities.
//

float Luminosity(vec3 color) {
  return color.r * 0.3 + color.g * 0.59 + color.b * 0.11;
}

/// Scales the color's luma by the amount necessary to place the color
/// components in a 1-0 range.
vec3 ClipColor(vec3 color) {
  float lum = Luminosity(color);
  float mn = min(min(color.r, color.g), color.b);
  float mx = max(max(color.r, color.g), color.b);
  // `lum - mn` and `mx - lum` will always be >= 0 in the following conditions,
  // so adding a tiny value is enough to make these divisions safe.
  if (mn < 0) {
    color = lum + (((color - lum) * lum) / (lum - mn + kEhCloseEnough));
  }
  if (mx > 1) {
    color = lum + (((color - lum) * (1 - lum)) / (mx - lum + kEhCloseEnough));
  }
  return color;
}

vec3 SetLuminosity(vec3 color, float luminosity) {
  float relative_lum = luminosity - Luminosity(color);
  return ClipColor(color + relative_lum);
}

float Saturation(vec3 color) {
  return max(max(color.r, color.g), color.b) -
         min(min(color.r, color.g), color.b);
}

vec3 SetSaturation(vec3 color, float saturation) {
  float mn = min(min(color.r, color.g), color.b);
  float mx = max(max(color.r, color.g), color.b);
  return (mn < mx) ? ((color - mn) * saturation) / (mx - mn) : vec3(0);
}
