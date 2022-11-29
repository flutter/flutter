// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform FragInfo {
  vec4 color;
}
frag_info;

uniform sampler2D base_color_texture;

in vec3 v_position;
in mat3 v_tangent_space;
in vec2 v_texture_coords;

out vec4 frag_color;

void main() {
  frag_color = texture(base_color_texture, v_texture_coords) * frag_info.color;
}
