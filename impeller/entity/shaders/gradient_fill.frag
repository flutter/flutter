// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/texture.glsl>

uniform GradientInfo {
  vec2 start_point;
  vec2 end_point;
  vec4 start_color;
  vec4 end_color;
  float tile_mode;
} gradient_info;

in vec2 interpolated_vertices;

out vec4 frag_color;

void main() {
  float len = length(gradient_info.end_point - gradient_info.start_point);
  float dot = dot(
    interpolated_vertices - gradient_info.start_point,
    gradient_info.end_point - gradient_info.start_point
  );
  float t = dot / (len * len);
  if ((t < 0.0 || t > 1.0) && gradient_info.tile_mode == kTileModeDecal) {
    frag_color = vec4(0);
    return;
  }

  t = IPFloatTile(t, gradient_info.tile_mode);
  frag_color = mix(gradient_info.start_color, gradient_info.end_color, t);
}
