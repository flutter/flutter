#version 320 es

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Note: Don't update this file without updating `uniforms_reordered.frag`.
// Note: Don't update this file without updating `uniforms_inserted.frag`.

precision highp float;

layout(location = 0) out vec4 oColor;

layout(location = 0) uniform float iFloatUniform;
layout(location = 1) uniform vec2 iVec2Uniform;
layout(location = 2) uniform mat2 iMat2Uniform;
layout(location = 3) uniform vec3 iVec3Uniform;
layout(location = 4) uniform vec4 iVec4Uniform;
layout(location = 5) uniform float[10] iFloatArrayUniform;
layout(location = 15) uniform vec2[3] iVec2ArrayUniform;
layout(location = 21) uniform vec3[3] iVec3ArrayUniform;
layout(location = 30) uniform vec4[3] iVec4ArrayUniform;

void main() {
  oColor = vec4(iFloatUniform, iVec2Uniform, iMat2Uniform[1][1]);
}
