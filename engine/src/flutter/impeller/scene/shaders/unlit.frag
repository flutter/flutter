// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform FragInfo {
  vec4 color;
  float vertex_color_weight;
}
frag_info;

uniform sampler2D base_color_texture;

in vec3 v_position;
in mat3 v_tangent_space;
in vec2 v_texture_coords;
in vec4 v_color;

out vec4 frag_color;

float consume_unused() {
  return (v_position.x + v_tangent_space[0][0]) * 0.001;
}

void main() {
  vec4 vertex_color = mix(vec4(1), v_color, frag_info.vertex_color_weight);
  frag_color = texture(base_color_texture, v_texture_coords) * vertex_color *
                   frag_info.color +
               consume_unused();
}
