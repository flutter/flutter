// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// A pair of unpositioned uniform of each type to demonstrate behavior
// of having unpositioned uniforms before positioned uniforms.
uniform float uFloatNotPositioned1;
uniform sampler2D uSamplerNotPositioned1;

layout(location = 6) uniform float uFloat;
layout(location = 5) uniform vec2 uVec2;
layout(location = 3) uniform vec3 uVec3;
layout(location = 2) uniform vec4 uVec4;
layout(location = 1) uniform mat4 uMat4;

layout(location = 0) uniform sampler2D uSampler;

// Another pair of unpositioned uniform of each type to demonstrate behavior
// of having unpositioned uniforms before positioned uniforms.
uniform float uFloatNotPositioned2;
uniform sampler2D uSamplerNotPositioned2;

out vec4 frag_color;

void main() {
  frag_color = vec4(1.0);
}
