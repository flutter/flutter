// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision mediump float;

#include <impeller/constants.glsl>
#include <impeller/types.glsl>

uniform f16sampler2D texture_sampler;

uniform FragInfo {
  float alpha;
  vec4 bounds_uv;
}
frag_info;

in highp vec2 v_texture_coords;

out f16vec4 frag_color;

vec4 Sample(vec2 uv, vec4 bounds_uv) {
// #ifdef SUPPORTS_DECAL
//   return texture(texture_sampler, uv, float16_t(kDefaultMipBias));
// #else
  if ((uv.x < bounds_uv.x || uv.y < bounds_uv.y || uv.x > bounds_uv.z || uv.y > bounds_uv.w)) {
    return vec4(0, 1., 0., 0.5);
  } else {
    return texture(texture_sampler, uv, float16_t(kDefaultMipBias));
  }
// #endif
}

void main() {
  // f16vec4 sampled = Sample(v_texture_coords, frag_info.bounds_uv);
  f16vec4 sampled =
      texture(texture_sampler, v_texture_coords, float16_t(kDefaultMipBias));
  frag_color = sampled * float16_t(frag_info.alpha);
}
