#version 320 es

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// If updating this file, also update
// engine/src/flutter/lib/web_ui/test/ui/fragment_shader_test.dart

#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;

precision highp float;

uniform vec4[2] color_array;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;

  if (uv.x < 0.5) {
    fragColor = color_array[0];
  } else {
    fragColor = color_array[1];
  }
}
