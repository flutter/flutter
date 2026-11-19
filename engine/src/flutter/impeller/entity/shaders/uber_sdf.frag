// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "uber_sdf_common.glsl"

uniform sampler2D color_source_sampler;

// Provides the `getGradientColor()` implementation used by the shared UberSDF
// body in `uber_sdf_common.glsl`.
vec4 getGradientColor(float t) {
  return IPSampleLinearWithTileMode(color_source_sampler, vec2(t, 0.5),
                                    vec2(frag_info.half_texel, 0.5),
                                    frag_info.tile_mode, vec4(0.0));
}
