// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

// One for each base type, 40 for the arrays
float N_COLOR_VALUES = 143;

uniform float uFloat;

uniform vec2 uVec2;
uniform vec3 uVec3;
uniform vec4 uVec4;

uniform mat2 uMat2;
uniform mat3 uMat3;
uniform mat4 uMat4;

const int ARRAY_SIZE = 10;

uniform float[ARRAY_SIZE] uFloatArray;
uniform vec2[ARRAY_SIZE] uVec2Array;
uniform vec3[ARRAY_SIZE] uVec3Array;
uniform vec4[ARRAY_SIZE] uVec4Array;

uniform mat2[ARRAY_SIZE] uMat2Array;
uniform mat3[ARRAY_SIZE] uMat3Array;
uniform mat4[ARRAY_SIZE] uMat4Array;

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

  for (int i = 0; i < 2; ++i) {
    if (u < offset) {
      fragColor = vec4(uMat2[i], 0, 1);
      return;
    }
    offset += increment;
  }

  for (int i = 0; i < 3; ++i) {
    if (u < offset) {
      fragColor = vec4(uMat3[i], 1);
      return;
    }
    offset += increment;
  }

  for (int i = 0; i < 4; ++i) {
    if (u < offset) {
      fragColor = uMat4[i];
      return;
    }
    offset += increment;
  }

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

  for (int i = 0; i < ARRAY_SIZE; ++i) {
    for (int j = 0; j < 2; ++j) {
      if (u < offset) {
        fragColor = vec4(uMat2Array[i][j], 0, 1);
        return;
      }
      offset += increment;
    }
  }

  for (int i = 0; i < ARRAY_SIZE; ++i) {
    for (int j = 0; j < 3; ++j) {
      if (u < offset) {
        fragColor = vec4(uMat3Array[i][j], 1);
        return;
      }
      offset += increment;
    }
  }

  for (int i = 0; i < ARRAY_SIZE; ++i) {
    for (int j = 0; j < 4; ++j) {
      if (u < offset) {
        fragColor = uMat4Array[i][j];
        return;
      }
      offset += increment;
    }
  }
}