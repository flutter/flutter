// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/constants.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>

// These values must correspond to the order of the items in the
// 'FilterContents::MorphType' enum class.
const float16_t kMorphTypeDilate = 0.0hf;
const float16_t kMorphTypeErode = 1.0hf;

uniform f16sampler2D texture_sampler;

uniform FragInfo {
  f16vec2 uv_offset;
  float16_t radius;
  float16_t morph_type;
}
frag_info;

in highp vec2 v_texture_coords;

out f16vec4 frag_color;

void main() {
  f16vec4 result =
      frag_info.morph_type == kMorphTypeDilate ? f16vec4(0.0) : f16vec4(1.0);
  for (float16_t i = -frag_info.radius; i <= frag_info.radius; i++) {
    vec2 texture_coords = v_texture_coords + frag_info.uv_offset * i;

// gles 2.0 is the only backend without native decal support.
#ifdef IMPELLER_TARGET_OPENGLES
    f16vec4 color = IPHalfSampleDecal(texture_sampler, texture_coords);
#else
    f16vec4 color = texture(texture_sampler, texture_coords);
#endif

    if (frag_info.morph_type == kMorphTypeDilate) {
      result = max(color, result);
    } else {
      result = min(color, result);
    }
  }

  frag_color = result;
}
