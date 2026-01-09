// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Start with a uniform of each type to demonstrate behavior when
// mixing declarations of uniform types.
uniform float uFirstFloat;
uniform sampler2D uFirstSampler;

uniform float uFloat;
uniform vec2 uVec2;
uniform vec3 uVec3;
uniform vec4 uVec4;
uniform mat4 uMat4;

uniform sampler2D uSampler;

out vec4 frag_color;

void main() {
  frag_color = vec4(1.0);
}
