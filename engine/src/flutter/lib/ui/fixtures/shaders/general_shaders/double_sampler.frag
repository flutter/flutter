#version 320 es

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision highp float;

out vec4 oColor;

uniform sampler2D tex_a;
uniform sampler2D tex_b;

void main() {
  vec2 coords = texture(tex_a, vec2(1, 0)).xy;
  oColor = texture(tex_b, coords);
}
