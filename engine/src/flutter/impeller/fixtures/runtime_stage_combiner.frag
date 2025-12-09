// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform sampler2D u_input0;
uniform sampler2D u_input1;

out vec4 frag_color;

void main() {
  vec4 val0 = texture(u_input0, FlutterGetInputTextureCoordinates(0));

  // Use alpha channel as displacement (arbitrary scalar).
  vec2 offset = vec2(val0.a * 0.1, 0.0);
  frag_color = texture(u_input1, FlutterGetInputTextureCoordinates(1) + offset);
}
