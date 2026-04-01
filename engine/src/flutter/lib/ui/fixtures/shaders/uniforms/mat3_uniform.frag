#version 320 es

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// If updating this file, also update
// engine/src/flutter/lib/web_ui/test/ui/fragment_shader_test.dart

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform mat3 colors;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / 3.0;

  if (uv.x < 0.3) {
    fragColor = vec4(colors[0], 1);
  } else if (uv.x < 0.6) {
    fragColor = vec4(colors[1], 1);
  } else {
    fragColor = vec4(colors[2], 1);
  }
}
