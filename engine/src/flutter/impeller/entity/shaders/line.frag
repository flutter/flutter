// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision mediump float;

#include <impeller/color.glsl>
#include <impeller/types.glsl>

uniform FragInfo {
  vec4 color;
}
frag_info;

uniform sampler2D curve;

highp in vec2 v_position;
// These should be `flat` but that doesn't work in our glsl compiler. It
// shouldn't make any visual difference.
highp in vec3 v_e0;
highp in vec3 v_e1;
highp in vec3 v_e2;
highp in vec3 v_e3;

out vec4 frag_color;

float lookup(float x) {
  return texture(curve, vec2(x, 0)).r;
}

float CalculateLine() {
  vec3 pos = vec3(v_position.xy, 1.0);
  vec4 d = vec4(dot(pos, v_e0), dot(pos, v_e1), dot(pos, v_e2), dot(pos, v_e3));

  if (any(lessThan(d, vec4(0.0)))) {
    return 0.0;
  }

  return lookup(min(d.x, d.z)) * lookup(min(d.y, d.w));
}

void main() {
  float line = CalculateLine();
  frag_color = vec4(frag_info.color.xyz, line);
  //////////////////////////////////////////////////////////////////////////////
  // This is a nice way to visually debug this shader:
  // frag_color =
  //   vec4(mix(vec3(1, 0,0), frag_info.color.xyz, line), 1.0);
  //////////////////////////////////////////////////////////////////////////////
  frag_color = IPPremultiply(frag_color);
}
