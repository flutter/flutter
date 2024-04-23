// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/blending.glsl>
#include <impeller/types.glsl>
#include "blend_select.glsl"

uniform FragInfo {
  float16_t alpha;
  float16_t blend_mode;
}
frag_info;

uniform f16sampler2D texture_sampler;

in highp vec2 v_texture_coords;
in mediump f16vec4 v_color;

out f16vec4 frag_color;

// A shader that implements the required src/dst blending for drawVertices and
// drawAtlas advanced blends without requiring an offscreen render pass. This is
// done in a single shader to reduce the permutations of PSO needed at runtime
// for rarely used features.
void main() {
  f16vec4 dst = IPHalfUnpremultiply(v_color);
  f16vec4 src = IPHalfUnpremultiply(texture(texture_sampler, v_texture_coords));
  f16vec3 blend_result =
      AdvancedBlend(dst.rgb, src.rgb, int(frag_info.blend_mode - 14.0));
  frag_color = IPApplyBlendedColor(dst, src, blend_result);
  frag_color *= frag_info.alpha;
}
