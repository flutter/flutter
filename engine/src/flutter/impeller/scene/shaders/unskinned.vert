// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform FrameInfo {
  mat4 mvp;
}
frame_info;

// This attribute layout is expected to be identical to that within
// `impeller/scene/importer/scene.fbs`.
in vec3 position;
in vec3 normal;
in vec4 tangent;
in vec2 texture_coords;
in vec4 color;

out vec3 v_position;
out mat3 v_tangent_space;
out vec2 v_texture_coords;
out vec4 v_color;

void main() {
  gl_Position = frame_info.mvp * vec4(position, 1.0);
  v_position = gl_Position.xyz;

  vec3 lh_tangent = tangent.xyz * tangent.w;
  v_tangent_space = mat3(frame_info.mvp) *
                    mat3(lh_tangent, cross(normal, lh_tangent), normal);
  v_texture_coords = texture_coords;
  v_color = color;
}
