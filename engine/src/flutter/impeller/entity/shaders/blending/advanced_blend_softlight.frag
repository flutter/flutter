// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "advanced_blend_utils.glsl"

vec3 Blend(vec3 dst, vec3 src) {
  // https://www.w3.org/TR/compositing-1/#blendingsoftlight

  vec3 D = IPVec3ChooseCutoff(((16 * dst - 12) * dst + 4) * dst,  //
                              sqrt(dst),                          //
                              dst,                                //
                              0.25);

  return IPVec3Choose(dst - (1 - 2 * src) * dst * (1 - dst),  //
                      dst + (2 * src - 1) * (D - dst),        //
                      src);
}

#include "advanced_blend.glsl"
