// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/texture.glsl>

uniform GradientInfo {
  vec2 center;
  float radius;
  vec4 center_color;
  vec4 edge_color;
  float tile_mode;
} gradient_info;

in vec2 interpolated_vertices;

out vec4 frag_color;

void main() {
  float len = length(interpolated_vertices - gradient_info.center);
  float t = len / gradient_info.radius;
  if ((t < 0.0 || t > 1.0) && gradient_info.tile_mode == kTileModeDecal) {
    frag_color = vec4(0);
    return;
  }

  t = IPFloatTile(t, gradient_info.tile_mode);
  frag_color = mix(gradient_info.center_color, gradient_info.edge_color, t);
}
