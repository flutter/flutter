// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vertices_uber.glsl"

// A shader that implements the required src/dst blending for drawVertices and
// drawAtlas advanced blends without requiring an offscreen render pass. This is
// done in a single shader to reduce the permutations of PSO needed at runtime
// for rarely used features.
void main() {
  f16vec4 dst = IPHalfUnpremultiply(v_color);
  f16vec4 src = IPHalfUnpremultiply(
      Sample(texture_sampler, v_texture_coords, frag_info.tmx, frag_info.tmy));
  f16vec3 blend_result =
      AdvancedBlendHalf1(dst.rgb, src.rgb, int(frag_info.blend_mode - 14.0));
  frag_color = IPApplyBlendedColor(dst, src, blend_result);
  frag_color *= frag_info.alpha;
}
