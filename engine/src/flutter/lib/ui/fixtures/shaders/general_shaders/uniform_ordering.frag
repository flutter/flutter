#version 300 es

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform float a;
uniform sampler2D u_texture;
uniform float b;
uniform float c;

out vec4 frag_color;

void main() {
  if (a == 1.0 && b == 2.0 && c == 3.0) {
    frag_color = vec4(0, 1, 0, 1);
  } else {
    frag_color = vec4(1, 0, 0, 1);
  }
}