// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/constants.glsl>
#include <impeller/texture.glsl>

uniform GradientInfo {
  vec2 center;
  float bias;
  float scale;
  vec4 start_color;
  vec4 end_color;
  float tile_mode;
} gradient_info;

in vec2 interpolated_vertices;

out vec4 frag_color;

void main() {
  vec2 coord = interpolated_vertices - gradient_info.center;
  float angle = atan(-coord.y, -coord.x);

  float t = (angle * k1Over2Pi + 0.5 + gradient_info.bias) * gradient_info.scale;
  if ((t < 0.0 || t > 1.0) && gradient_info.tile_mode == kTileModeDecal) {
    frag_color = vec4(0);
    return;
  }

  t = IPFloatTile(t, gradient_info.tile_mode);
  frag_color = mix(gradient_info.start_color, gradient_info.end_color, t);
}
