// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision mediump float;

#include <impeller/constants.glsl>
#include <impeller/types.glsl>

layout(constant_id = 0) const float supports_decal = 1.0;

uniform f16sampler2D texture_sampler;

uniform FragInfo {
  float edge;
  float ratio;
  float use_decal;
  vec2 pixel_size;
}
frag_info;

in highp vec2 v_texture_coords;

out vec4 frag_color;

vec4 Sample(vec2 uv) {
  if (supports_decal == 1.0) {
    return texture(texture_sampler, uv, float16_t(kDefaultMipBias));
  } else {
    if (frag_info.use_decal == 1.0 &&
        (uv.x < 0 || uv.y < 0 || uv.x > 1 || uv.y > 1)) {
      return vec4(0);
    } else {
      return texture(texture_sampler, uv, float16_t(kDefaultMipBias));
    }
  }
}

void main() {
  vec4 total = vec4(0.0);
  for (float i = -frag_info.edge; i <= frag_info.edge; i += 2) {
    for (float j = -frag_info.edge; j <= frag_info.edge; j += 2) {
      total += (Sample(v_texture_coords + frag_info.pixel_size * vec2(i, j)) *
                frag_info.ratio);
    }
  }
  frag_color = total;
}
