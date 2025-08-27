// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/blending.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>
#include "blend_select.glsl"

layout(constant_id = 0) const float supports_decal = 1.0;

uniform FragInfo {
  float16_t alpha;
  float16_t blend_mode;
  float tmx;
  float tmy;
}
frag_info;

uniform f16sampler2D texture_sampler;

in mediump vec2 v_texture_coords;
in mediump f16vec4 v_color;

out f16vec4 frag_color;

f16vec4 Sample(f16sampler2D texture_sampler,
               vec2 texture_coords,
               float tmx,
               float tmy) {
  if (supports_decal > 0.0) {
    return texture(texture_sampler, texture_coords);
  }
  return IPHalfSampleWithTileMode(texture_sampler, texture_coords, tmx, tmy);
}
