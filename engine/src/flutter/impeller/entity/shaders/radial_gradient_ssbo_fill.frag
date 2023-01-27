// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/gradient.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>

struct ColorPoint {
  vec4 color;
  float stop;
};

layout(std140) readonly buffer ColorData {
  ColorPoint colors[];
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

  vec4 result_color = vec4(0);
  for (int i = 1; i < gradient_info.colors_length; i++) {
    ColorPoint prev_point = color_data.colors[i - 1];
    ColorPoint current_point = color_data.colors[i];
    if (t >= prev_point.stop && t <= current_point.stop) {
      float delta = (current_point.stop - prev_point.stop);
      if (delta < 0.001) {
        result_color = current_point.color;
      } else {
        float ratio = (t - prev_point.stop) / delta;
        result_color = mix(prev_point.color, current_point.color, ratio);
      }
      break;
    }
  }
  frag_color = vec4(result_color.xyz * result_color.a, result_color.a) *
               gradient_info.alpha;
}
