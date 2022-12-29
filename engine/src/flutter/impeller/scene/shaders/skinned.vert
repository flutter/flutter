// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform VertInfo {
  mat4 mvp;
}
vert_info;

// This attribute layout is expected to be identical to `SkinnedVertex` within
// `impeller/scene/importer/scene.fbs`.
in vec3 position;
in vec3 normal;
in vec4 tangent;
in vec2 texture_coords;
in vec4 color;
// TODO(bdero): Use the joint indices to sample bone matrices from a texture.
in vec4 joints;
in vec4 weights;

out vec3 v_position;
out mat3 v_tangent_space;
out vec2 v_texture_coords;
out vec4 v_color;

void main() {
  // The following two lines are temporary placeholders to prevent the vertex
  // attributes from being removed from the shader.
  v_color = joints;
  v_color = weights;

  gl_Position = vert_info.mvp * vec4(position, 1.0);
  v_position = gl_Position.xyz;

  vec3 lh_tangent = tangent.xyz * tangent.w;
  v_tangent_space =
      mat3(vert_info.mvp) * mat3(lh_tangent, cross(normal, lh_tangent), normal);
  v_texture_coords = texture_coords;
  v_color = color;
}
