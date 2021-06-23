// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform UniformBuffer {
  mat4 mvp;
  vec3 color;
} uniforms;

in vec3 vertexPosition;
out vec3 color;

void main() {
  gl_Position = vec4(vertexPosition, 1.0);
  color = uniforms.color;
}
