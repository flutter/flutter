// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

out vec4 fragColor;

uniform float uFloat;

uniform vec2 uVec2;
uniform vec3 uVec3;
uniform vec4 uVec4;

uniform mat2 uMat2;
uniform mat3 uMat3;
uniform mat4 uMat4;

const int ARRAY_SIZE = 2;
uniform float uFloatArray[ARRAY_SIZE];

uniform vec2 uVec2Array[ARRAY_SIZE];
uniform vec3 uVec3Array[ARRAY_SIZE];
uniform vec4 uVec4Array[ARRAY_SIZE];

uniform mat2 uMat2Array[ARRAY_SIZE];
uniform mat3 uMat3Array[ARRAY_SIZE];
uniform mat4 uMat4Array[ARRAY_SIZE];

bool checkAllNonZero() {
  if (uFloat == 0.0)
    return false;

  if (uVec2.x == 0.0 || uVec2.y == 0.0)
    return false;
  if (uVec3.x == 0.0 || uVec3.y == 0.0 || uVec3.z == 0.0)
    return false;
  if (uVec4.x == 0.0 || uVec4.y == 0.0 || uVec4.z == 0.0 || uVec4.w == 0.0)
    return false;

  if (uMat2[0].x == 0.0 || uMat2[0].y == 0.0 || uMat2[1].x == 0.0 ||
      uMat2[1].y == 0.0)
    return false;
  if (uMat3[0].x == 0.0 || uMat3[0].y == 0.0 || uMat3[0].z == 0.0 ||
      uMat3[1].x == 0.0 || uMat3[1].y == 0.0 || uMat3[1].z == 0.0 ||
      uMat3[2].x == 0.0 || uMat3[2].y == 0.0 || uMat3[2].z == 0.0)
    return false;
  if (uMat4[0].x == 0.0 || uMat4[0].y == 0.0 || uMat4[0].z == 0.0 ||
      uMat4[0].w == 0.0 || uMat4[1].x == 0.0 || uMat4[1].y == 0.0 ||
      uMat4[1].z == 0.0 || uMat4[1].w == 0.0 || uMat4[2].x == 0.0 ||
      uMat4[2].y == 0.0 || uMat4[2].z == 0.0 || uMat4[2].w == 0.0 ||
      uMat4[3].x == 0.0 || uMat4[3].y == 0.0 || uMat4[3].z == 0.0 ||
      uMat4[3].w == 0.0)
    return false;

  for (int i = 0; i < ARRAY_SIZE; ++i) {
    if (uFloatArray[i] == 0.0)
      return false;

    if (uVec2Array[i].x == 0.0 || uVec2Array[i].y == 0.0)
      return false;
    if (uVec3Array[i].x == 0.0 || uVec3Array[i].y == 0.0 ||
        uVec3Array[i].z == 0.0)
      return false;
    if (uVec4Array[i].x == 0.0 || uVec4Array[i].y == 0.0 ||
        uVec4Array[i].z == 0.0 || uVec4Array[i].w == 0.0)
      return false;

    if (uMat2Array[i][0].x == 0.0 || uMat2Array[i][0].y == 0.0 ||
        uMat2Array[i][1].x == 0.0 || uMat2Array[i][1].y == 0.0)
      return false;
    if (uMat3Array[i][0].x == 0.0 || uMat3Array[i][0].y == 0.0 ||
        uMat3Array[i][0].z == 0.0 || uMat3Array[i][1].x == 0.0 ||
        uMat3Array[i][1].y == 0.0 || uMat3Array[i][1].z == 0.0 ||
        uMat3Array[i][2].x == 0.0 || uMat3Array[i][2].y == 0.0 ||
        uMat3Array[i][2].z == 0.0)
      return false;
    if (uMat4Array[i][0].x == 0.0 || uMat4Array[i][0].y == 0.0 ||
        uMat4Array[i][0].z == 0.0 || uMat4Array[i][0].w == 0.0 ||
        uMat4Array[i][1].x == 0.0 || uMat4Array[i][1].y == 0.0 ||
        uMat4Array[i][1].z == 0.0 || uMat4Array[i][1].w == 0.0 ||
        uMat4Array[i][2].x == 0.0 || uMat4Array[i][2].y == 0.0 ||
        uMat4Array[i][2].z == 0.0 || uMat4Array[i][2].w == 0.0 ||
        uMat4Array[i][3].x == 0.0 || uMat4Array[i][3].y == 0.0 ||
        uMat4Array[i][3].z == 0.0 || uMat4Array[i][3].w == 0.0)
      return false;
  }

  return true;
}

void main() {
  if (checkAllNonZero()) {
    fragColor = vec4(0.0, 1.0, 0.0, 1.0);
  } else {
    fragColor = vec4(1.0, 0.0, 0.0, 1.0);
  }
}
