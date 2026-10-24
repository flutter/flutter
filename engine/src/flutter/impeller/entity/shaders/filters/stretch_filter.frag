// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision highp float;

#include <impeller/types.glsl>

uniform f16sampler2D input_texture;

uniform FragInfo {
  vec4 container_uv;
  vec2 overscroll;
  vec2 u_d;
  vec2 u_s;
  float interpolation_strength;
  float input_alpha;
}
frag_info;

in highp vec2 v_texture_coords;
out f16vec4 frag_color;

float ComputeStretchedEffect(float in_pos,
                             float overscroll,
                             float interpolation_strength,
                             float u_d,
                             float u_s) {
  if (overscroll > 0.0) {
    float e = 1.0 - in_pos;
    float p = overscroll;
    float c = e / (u_s + (p * e) * interpolation_strength);
    return u_d - c;
  }
  if (overscroll < 0.0) {
    float e = in_pos;
    float p = abs(overscroll);
    float c = e / (u_s + (p * e) * interpolation_strength);
    return 1.0 - u_d + c;
  }
  return in_pos;
}

void main() {
  vec2 container_origin = frag_info.container_uv.xy;
  vec2 container_size = max(frag_info.container_uv.zw, vec2(0.0001));
  vec2 rel = (v_texture_coords - container_origin) / container_size;
  float src_rel_x =
      (rel.x >= 0.0 && rel.x <= 1.0)
          ? ComputeStretchedEffect(rel.x, frag_info.overscroll.x,
                                   frag_info.interpolation_strength,
                                   frag_info.u_d.x, frag_info.u_s.x)
          : rel.x;
  float src_rel_y =
      (rel.y >= 0.0 && rel.y <= 1.0)
          ? ComputeStretchedEffect(rel.y, frag_info.overscroll.y,
                                   frag_info.interpolation_strength,
                                   frag_info.u_d.y, frag_info.u_s.y)
          : rel.y;
  vec2 uv = container_origin + vec2(src_rel_x, src_rel_y) * container_size;
  uv = clamp(uv, 0.0, 1.0);
  frag_color = texture(input_texture, uv) * float16_t(frag_info.input_alpha);
}
