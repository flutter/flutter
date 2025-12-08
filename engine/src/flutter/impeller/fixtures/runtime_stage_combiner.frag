// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform sampler2D u_input0;
uniform sampler2D u_input1;

out vec4 frag_color;

void main() {
  vec2 coords = FlutterFragCoord().xy / u_size;
  vec4 val0 = texture(u_input0, coords);
  // Treat red channel of input0 as displacement x
  vec2 offset = vec2(val0.r * 20.0 / u_size.x, 0.0);
  frag_color = texture(u_input1, coords + offset);
}
