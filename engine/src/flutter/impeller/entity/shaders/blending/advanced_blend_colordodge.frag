// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "advanced_blend_utils.glsl"

vec3 Blend(vec3 dst, vec3 src) {
  // https://www.w3.org/TR/compositing-1/#blendingcolordodge
  vec3 color = min(vec3(1), dst / (1 - src));
  if (dst.r < kEhCloseEnough) {
    color.r = 0;
  }
  if (dst.g < kEhCloseEnough) {
    color.g = 0;
  }
  if (dst.b < kEhCloseEnough) {
    color.b = 0;
  }
  if (1 - src.r < kEhCloseEnough) {
    color.r = 1;
  }
  if (1 - src.g < kEhCloseEnough) {
    color.g = 1;
  }
  if (1 - src.b < kEhCloseEnough) {
    color.b = 1;
  }
  return color;
}

#include "advanced_blend.glsl"
