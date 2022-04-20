// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform UniformBuffer {
  mat4 mvp;
}
uniforms;

in vec2 vertex_position;
in vec2 texture_coordinates;
in int vertex_color;

out vec2 frag_texture_coordinates;
out vec4 frag_vertex_color;

vec4 ImVertexColorToVec4(int color) {
  const float kScale = 1.0f / 255.0f;
  return vec4(
    ((color >> 0) & 0xFF)  * kScale,
    ((color >> 8) & 0xFF)  * kScale,
    ((color >> 16) & 0xFF) * kScale,
    ((color >> 24) & 0xFF) * kScale
  );
}

void main() {
  gl_Position = uniforms.mvp * vec4(vertex_position.xy, 0.0, 1.0);
  frag_texture_coordinates = texture_coordinates;
  frag_vertex_color = ImVertexColorToVec4(vertex_color);
}
