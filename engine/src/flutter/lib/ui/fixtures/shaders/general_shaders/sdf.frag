#version 320 es

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 uSize;
uniform sampler2D uTex;

void main() {
  vec2 p = FlutterFragCoord().xy / uSize;
  float d = texture(uTex, p).r;
  // d > 0 means outside the shape (positive distance), so black.
  // d <= 0 means inside the shape (negative distance), so white.
  vec3 col = d > 0.0 ? vec3(0.0) : vec3(1.0);
  fragColor = vec4(col, 1.0);
}
