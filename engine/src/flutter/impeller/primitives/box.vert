// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform UniformBuffer {
  mat4 mvp;
} uniforms;

in vec3 vertex_position;
in vec4 vertex_color;

out vec4 color;

void main() {
  gl_Position = uniforms.mvp * vec4(vertex_position, 1.0);
  color = vertex_color;
}
