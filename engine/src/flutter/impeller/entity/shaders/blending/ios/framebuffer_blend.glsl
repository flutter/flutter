#version 450

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/blending.glsl>
#include <impeller/color.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>

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
// gles 2.0 is the only backend without native decal support.
#ifdef IMPELLER_TARGET_OPENGLES
  return IPSampleDecal(texture_sampler, texture_coords);
#else
  return texture(texture_sampler, texture_coords);
#endif
}

void main() {
  f16vec4 dst = f16vec4(ReadDestination());
  f16vec4 src = f16vec4(Sample(texture_sampler_src,  // sampler
                               v_src_texture_coords  // texture coordinates
                               )) *
                frag_info.src_input_alpha;

  f16vec4 blended = mix(src, f16vec4(Blend(dst.rgb, src.rgb), dst.a), dst.a);
  frag_color = vec4(mix(dst, blended, src.a));
}
