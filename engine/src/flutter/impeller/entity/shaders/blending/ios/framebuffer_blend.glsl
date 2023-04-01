#version 450

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/blending.glsl>
#include <impeller/color.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>

#ifdef IMPELLER_TARGET_METAL
layout(set = 0,
       binding = 0,
       input_attachment_index = 0) uniform subpassInput uSub;

vec4 ReadDestination() {
  return subpassLoad(uSub);
}
#else

vec4 ReadDestination() {
  return vec4(0);
}
#endif

uniform sampler2D texture_sampler_src;

in vec2 v_src_texture_coords;

out vec4 frag_color;

void main() {
  vec4 dst_sample = ReadDestination();
  vec4 dst = IPUnpremultiply(dst_sample);
  vec4 src =
      IPUnpremultiply(texture(texture_sampler_src,  // sampler
                              v_src_texture_coords  // texture coordinates
                              ));

  vec4 blended = vec4(Blend(dst.rgb, src.rgb), 1) * dst.a;

  frag_color = mix(dst_sample, blended, src.a);
}
