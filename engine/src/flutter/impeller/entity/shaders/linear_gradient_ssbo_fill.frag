// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

uniform FragInfo {
  highp vec2 start_point;
  highp vec2 end_point;
  float alpha;
  float tile_mode;
  int colors_length;
}
frag_info;

highp in vec2 v_position;

out vec4 frag_color;

void main() {
  highp vec2 start_to_end = frag_info.end_point - frag_info.start_point;
  highp vec2 start_to_position = v_position - frag_info.start_point;
  highp float t =
      dot(start_to_position, start_to_end) / dot(start_to_end, start_to_end);

  if ((t < 0.0 || t > 1.0) && frag_info.tile_mode == kTileModeDecal) {
    frag_color = vec4(0);
    return;
  }
  t = IPFloatTile(t, frag_info.tile_mode);

  for (int i = 1; i < frag_info.colors_length; i++) {
    ColorPoint prev_point = color_data.colors[i - 1];
    ColorPoint current_point = color_data.colors[i];
    if (t >= prev_point.stop && t <= current_point.stop) {
      float delta = (current_point.stop - prev_point.stop);
      if (delta < 0.001) {
        frag_color = current_point.color;
      } else {
        float ratio = (t - prev_point.stop) / delta;
        frag_color = mix(prev_point.color, current_point.color, ratio);
      }
      break;
    }
  }
  frag_color =
      vec4(frag_color.xyz * frag_color.a, frag_color.a) * frag_info.alpha;
}
