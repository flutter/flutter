// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform UniformBuffer {
  mat4 mvp;
} uniforms;

uniform UniformBuffer2 {
  uniform mat4 longGOP;
} uniforms2;

struct Position {
  vec3 position;
  vec3 color;
};

in vec3 vertexPosition;
in vec3 vertexColor;
in dvec4 hello;
in uvec4 hello2;

out vec3 color;

void main()
{
  gl_Position = uniforms2.longGOP * uniforms.mvp * vec4(vertexPosition, 1.0);
  color = vertexColor;
}
