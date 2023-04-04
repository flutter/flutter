// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/blending.glsl>
#include <impeller/color.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>

uniform BlendInfo {
  float16_t dst_input_alpha;
  float16_t color_factor;
  f16vec4 color;  // This color input is expected to be unpremultiplied.
}
blend_info;

uniform f16sampler2D texture_sampler_dst;
uniform f16sampler2D texture_sampler_src;

in vec2 v_dst_texture_coords;
in vec2 v_src_texture_coords;

out f16vec4 frag_color;

f16vec4 Sample(f16sampler2D texture_sampler, vec2 texture_coords) {
// gles 2.0 is the only backend without native decal support.
#ifdef IMPELLER_TARGET_OPENGLES
  return IPSampleDecal(texture_sampler, texture_coords);
#else
  return texture(texture_sampler, texture_coords);
#endif
}

void main() {
  f16vec4 dst_sample = Sample(texture_sampler_dst,  // sampler
                              v_dst_texture_coords  // texture coordinates
                              ) *
                       blend_info.dst_input_alpha;

  f16vec4 dst = IPHalfUnpremultiply(dst_sample);
  f16vec4 src = blend_info.color_factor > 0.0hf
                    ? blend_info.color
                    : IPHalfUnpremultiply(Sample(
                          texture_sampler_src,  // sampler
                          v_src_texture_coords  // texture coordinates
                          ));

  f16vec4 blended = f16vec4(Blend(dst.rgb, src.rgb), 1.0hf) * dst.a;

  frag_color = mix(dst_sample, blended, src.a);
}
