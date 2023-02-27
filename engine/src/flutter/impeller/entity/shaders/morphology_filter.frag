// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/constants.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>

// These values must correspond to the order of the items in the
// 'FilterContents::MorphType' enum class.
const float kMorphTypeDilate = 0;
const float kMorphTypeErode = 1;

uniform sampler2D texture_sampler;

uniform FragInfo {
  vec2 texture_size;
  vec2 direction;
  float radius;
  float morph_type;
}
frag_info;

in vec2 v_texture_coords;
out vec4 frag_color;

void main() {
  vec4 result = frag_info.morph_type == kMorphTypeDilate ? vec4(0) : vec4(1);
  vec2 uv_offset = frag_info.direction / frag_info.texture_size;
  for (float i = -frag_info.radius; i <= frag_info.radius; i++) {
    vec2 texture_coords = v_texture_coords + uv_offset * i;
    vec4 color;
    color = IPSampleDecal(texture_sampler, texture_coords);
    if (frag_info.morph_type == kMorphTypeDilate) {
      result = max(color, result);
    } else {
      result = min(color, result);
    }
  }

  frag_color = result;
}
