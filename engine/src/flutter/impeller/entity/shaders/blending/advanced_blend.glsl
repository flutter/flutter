// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/blending.glsl>
#include <impeller/color.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>

uniform BlendInfo {
  float dst_input_alpha;
  float color_factor;
  vec4 color;  // This color input is expected to be unpremultiplied.
}
blend_info;

uniform sampler2D texture_sampler_dst;
uniform sampler2D texture_sampler_src;

in vec2 v_dst_texture_coords;
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
  vec4 dst_sample = Sample(texture_sampler_dst,  // sampler
                           v_dst_texture_coords  // texture coordinates
                           ) *
                    blend_info.dst_input_alpha;

  vec4 dst = IPUnpremultiply(dst_sample);
  vec4 src =
      blend_info.color_factor > 0
          ? blend_info.color
          : IPUnpremultiply(Sample(texture_sampler_src,  // sampler
                                   v_src_texture_coords  // texture coordinates
                                   ));

  vec4 blended = vec4(Blend(dst.rgb, src.rgb), 1) * dst.a;

  frag_color = mix(dst_sample, blended, src.a);
}
