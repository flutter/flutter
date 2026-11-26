// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision mediump float;

#include <impeller/blending.glsl>
#include <impeller/color.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>

layout(constant_id = 0) const float supports_decal = 1.0;

uniform f16sampler2D texture_sampler_dst;

uniform FragInfo {
  // packed input, output alpha and x/y tilemodes.
  vec4 input_alpha_output_alpha_tmx_tmy;
  vec4 source_rect;
  // When value is non-zero, uses texture coordinates clamped by `source_rect`.
  float use_strict_source_rect;
  // The coefficients that select the blend mode. See `kPorterDuffCoefficients`
  // in blend_filter_contents.h for the values of each blend mode.
  float src_coeff;
  float src_coeff_dst_alpha;
  float dst_coeff;
  float dst_coeff_src_alpha;
  float dst_coeff_src_color;
}
frag_info;

float input_alpha = frag_info.input_alpha_output_alpha_tmx_tmy.x;
float output_alpha = frag_info.input_alpha_output_alpha_tmx_tmy.y;
float tile_mode_x = frag_info.input_alpha_output_alpha_tmx_tmy.z;
float tile_mode_y = frag_info.input_alpha_output_alpha_tmx_tmy.w;

in vec2 v_texture_coords;
in f16vec4 v_color;

out vec4 frag_color;

f16vec4 Sample(f16sampler2D texture_sampler, vec2 texture_coords) {
  if (supports_decal > 0.0) {
    return texture(texture_sampler, texture_coords);
  }
  return IPHalfSampleWithTileMode(texture_sampler, texture_coords, tile_mode_x,
                                  tile_mode_y);
}

void main() {
  vec2 texture_coords =
      mix(v_texture_coords,
          vec2(clamp(v_texture_coords.x, frag_info.source_rect.x,
                     frag_info.source_rect.z),
               clamp(v_texture_coords.y, frag_info.source_rect.y,
                     frag_info.source_rect.w)),
          frag_info.use_strict_source_rect);

  f16vec4 dst =
      Sample(texture_sampler_dst, texture_coords) * float16_t(input_alpha);
  f16vec4 src = v_color;
  frag_color = f16vec4(
      src * (frag_info.src_coeff + dst.a * frag_info.src_coeff_dst_alpha) +
      dst * (frag_info.dst_coeff + src.a * frag_info.dst_coeff_src_alpha +
             src * frag_info.dst_coeff_src_color));
  frag_color *= output_alpha;
}
