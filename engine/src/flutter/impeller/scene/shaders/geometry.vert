// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform VertInfo {
  mat4 mvp;
}
vert_info;

in vec3 position;
in vec3 normal;
in vec3 tangent;
in vec2 texture_coords;

out vec3 v_position;
out mat3 v_tangent_space;
out vec2 v_texture_coords;

void main() {
  gl_Position = vert_info.mvp * vec4(position, 1.0);
  v_position = gl_Position.xyz;

  v_tangent_space =
      mat3(vert_info.mvp) * mat3(tangent, cross(normal, tangent), normal);
  v_texture_coords = texture_coords;
}
