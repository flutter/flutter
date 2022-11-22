// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/gradient.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>

readonly buffer ColorData {
  vec4 colors[];
}
color_data;

uniform GradientInfo {
  vec2 center;
  float radius;
  float tile_mode;
  float alpha;
  float colors_length;
}
gradient_info;

in vec2 v_position;

out vec4 frag_color;

void main() {
  float len = length(v_position - gradient_info.center);
  float t = len / gradient_info.radius;

  if ((t < 0.0 || t > 1.0) && gradient_info.tile_mode == kTileModeDecal) {
    frag_color = vec4(0);
    return;
  }
  t = IPFloatTile(t, gradient_info.tile_mode);
  vec3 values = IPComputeFixedGradientValues(t, gradient_info.colors_length);

  frag_color = mix(color_data.colors[int(values.x)],
                   color_data.colors[int(values.y)], values.z);
  frag_color =
      vec4(frag_color.xyz * frag_color.a, frag_color.a) * gradient_info.alpha;
}
