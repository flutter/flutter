#version 460 core

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision mediump float;

layout(location = 0) uniform mat2 uMat;
layout(location = 0) out vec4 frag_color;

void main() {
  float m00 = uMat[0][0];
  float m01 = uMat[0][1];
  float m10 = uMat[1][0];
  float m11 = uMat[1][1];

  if (abs(m00 - 4.0) < 0.01 && abs(m01 - 8.0) < 0.01 &&
      abs(m10 - 16.0) < 0.01 && abs(m11 - 32.0) < 0.01) {
    frag_color = vec4(0.0, 1.0, 0.0, 1.0);
  } else {
    frag_color = vec4(1.0, 0.0, 0.0, 1.0);
  }
}
