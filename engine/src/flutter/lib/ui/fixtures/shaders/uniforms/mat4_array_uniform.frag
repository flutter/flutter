#version 320 es

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// If updating this file, also update
// engine/src/flutter/lib/web_ui/test/ui/fragment_shader_test.dart

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform mat4[] colors;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy;

  if (uv.x < 1) {
    fragColor = colors[0][0];
  } else if (uv.x < 2) {
    fragColor = colors[0][1];
  } else if (uv.x < 3) {
    fragColor = colors[0][2];
  } else if (uv.x < 4) {
    fragColor = colors[0][3];
  } else if (uv.x < 5) {
    fragColor = colors[1][0];
  } else if (uv.x < 6) {
    fragColor = colors[1][1];
  } else if (uv.x < 7) {
    fragColor = colors[1][2];
  } else if (uv.x < 8) {
    fragColor = colors[1][3];
  }
}
