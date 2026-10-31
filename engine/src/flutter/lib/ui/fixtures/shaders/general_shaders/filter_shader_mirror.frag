// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform sampler2D u_texture;

out vec4 frag_color;

// Mirrors the input horizontally.
void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  frag_color = texture(u_texture, vec2(1.0 - uv.x, uv.y));
}
