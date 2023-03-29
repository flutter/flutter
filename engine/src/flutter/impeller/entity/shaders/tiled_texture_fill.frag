// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/texture.glsl>
#include <impeller/types.glsl>

uniform f16sampler2D texture_sampler;

uniform FragInfo {
  float16_t x_tile_mode;
  float16_t y_tile_mode;
  float16_t alpha;
}
frag_info;

in f16vec2 v_texture_coords;

out f16vec4 frag_color;

void main() {
  frag_color =
      IPHalfSampleWithTileMode(texture_sampler,        // sampler
                               v_texture_coords,       // texture coordinates
                               frag_info.x_tile_mode,  // x tile mode
                               frag_info.y_tile_mode   // y tile mode
                               ) *
      frag_info.alpha;
}
