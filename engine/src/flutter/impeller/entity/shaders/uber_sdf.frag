// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "uber_sdf_common.glsl"

uniform sampler2D color_source_sampler;

// Provides the `getGradientColor()` implementation used by the shared UberSDF
// body in `uber_sdf_common.glsl`.
vec4 getGradientColor(highp float t) {
  // UberSDF always uses a transparent decal border.
  if (frag_info.tile_mode == kTileModeDecal && (t < 0.0 || t > 1.0)) {
    return vec4(0.0);
  }
  // Tile while `t` is still highp. Far from the gradient origin `t` is large,
  // and mediump would have no fractional bits left for repeat or mirror. Once
  // tiled, `t` is in [0, 1], where mediump is enough for the ramp lookup.
  float tiled_t = IPFloatTile(t, frag_info.tile_mode);
  return IPSampleLinear(color_source_sampler, vec2(tiled_t, 0.5),
                        vec2(frag_info.half_texel, 0.5));
}
