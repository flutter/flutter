// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

// One for each base type, 40 for the arrays
float N_COLOR_VALUES = 44;

uniform float uFloat;

uniform vec2 uVec2;
uniform vec3 uVec3;
uniform vec4 uVec4;

const int ARRAY_SIZE = 10;

uniform float[ARRAY_SIZE] uFloatArray;
uniform vec2[ARRAY_SIZE] uVec2Array;
uniform vec3[ARRAY_SIZE] uVec3Array;
uniform vec4[ARRAY_SIZE] uVec4Array;

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

  for (int i = 0; i < ARRAY_SIZE; ++i) {
    if (u < offset) {
      fragColor = vec4(uFloatArray[i], 0, 0, 1);
      return;
    }
    offset += increment;
  }

  for (int i = 0; i < ARRAY_SIZE; ++i) {
    if (u < offset) {
      fragColor = vec4(uVec2Array[i], 0, 1);
      return;
    }
    offset += increment;
  }

  for (int i = 0; i < ARRAY_SIZE; ++i) {
    if (u < offset) {
      fragColor = vec4(uVec3Array[i], 1);
      return;
    }
    offset += increment;
  }

  for (int i = 0; i < ARRAY_SIZE; ++i) {
    if (u < offset) {
      fragColor = uVec4Array[i];
      return;
    }
    offset += increment;
  }
}