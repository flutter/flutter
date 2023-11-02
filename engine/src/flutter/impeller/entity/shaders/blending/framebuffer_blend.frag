#version 450

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/blending.glsl>
#include <impeller/color.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>
#include "blend_select.glsl"

layout(constant_id = 0) const int blend_type = 0;
layout(constant_id = 1) const int supports_decal = 1;

layout(set = 0,
       binding = 0,
       input_attachment_index = 0) uniform subpassInput uSub;

vec4 ReadDestination() {
  return subpassLoad(uSub);
}

uniform sampler2D texture_sampler_src;

uniform FragInfo {
  float16_t src_input_alpha;
}
frag_info;

in vec2 v_src_texture_coords;

out vec4 frag_color;

vec4 Sample(sampler2D texture_sampler, vec2 texture_coords) {
  if (supports_decal > 1) {
    return texture(texture_sampler, texture_coords);
  }
  return IPSampleDecal(texture_sampler, texture_coords);
}

AdvancedBlend(blend_type);

void main() {
  f16vec4 dst = f16vec4(ReadDestination());
  f16vec4 src = f16vec4(Sample(texture_sampler_src,  // sampler
                               v_src_texture_coords  // texture coordinates
                               )) *
                frag_info.src_input_alpha;

  f16vec3 blend_result = Blend(dst.rgb, src.rgb);
  f16vec4 blended = mix(src, f16vec4(blend_result, dst.a), dst.a);
  frag_color = vec4(mix(dst, blended, src.a));
}
