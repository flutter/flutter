// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform sampler2D u_texture;

out vec4 frag_color;

void main() {
  // swap color channels.
  frag_color = texture(u_texture, FlutterFragCoord().xy / u_size).bgra;
}
