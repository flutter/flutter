// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

struct MyAwesomeStruct {
  float mvp0;
  mat4x2 mvp1;
  mat4 mvp2;
  mat4 mvp3;
};

uniform UniformBuffer1 {
  MyAwesomeStruct s1;
  MyAwesomeStruct s2;
  MyAwesomeStruct s3;
} uniforms1;

uniform UniformBuffer2 {
  MyAwesomeStruct s11;
  float hello12;
  MyAwesomeStruct s13;
} uniforms2;

in vec3 vertexPosition;
in vec3 vertexColor;
in dvec4 hello;
in dmat4x2 hello12;
in uvec4 hello2;

out vec3 color;

void main()
{
  gl_Position = uniforms1.s1.mvp2 * uniforms2.s13.mvp3 * vec4(vertexPosition, 1.0);
  color = vertexColor;
}
