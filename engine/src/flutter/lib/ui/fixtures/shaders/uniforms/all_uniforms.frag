// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

// One for each base type
float N_COLOR_VALUES = 4;

uniform float uFloat;

uniform vec2 uVec2;
uniform vec3 uVec3;
uniform vec4 uVec4;

void main() {
  float u = FlutterFragCoord().x / N_COLOR_VALUES;

  float increment = 1.0 / N_COLOR_VALUES;

  float offset = increment;

  if (u < offset) {
    fragColor = vec4(uFloat, 0, 0, 1);
    return;
  }
  offset += increment;
  if (u < offset) {
    fragColor = vec4(uVec2, 0, 1);
    return;
  }
  offset += increment;
  if (u < offset) {
    fragColor = vec4(uVec3, 1);
    return;
  }
  offset += increment;
  if (u < offset) {
    fragColor = uVec4;
    return;
  }
  offset += increment;
}