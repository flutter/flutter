#version 320 es

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform mat2[2] colors;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy;

  if (uv.x < 1) {
    fragColor = vec4(colors[0][0], colors[0][1]);
  } else {
    fragColor = vec4(colors[1][0], colors[1][1]);
  }
}
