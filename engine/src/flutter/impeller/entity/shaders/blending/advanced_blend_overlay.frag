// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "advanced_blend_utils.glsl"

vec3 Blend(vec3 dst, vec3 src) {
  // https://www.w3.org/TR/compositing-1/#blendinghardlight
  // HardLight, but with reversed parameters.
  return BlendHardLight(src, dst);
}

#include "advanced_blend.glsl"
