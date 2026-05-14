// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The math for this shader was based on the work done in Raph Levien's blog
// post "Blurred rounded rectangles":
// https://web.archive.org/web/20231103044404/https://raphlinus.github.io/graphics/2020/04/21/blurred-rounded-rects.html

// NOTICE: Changes made to this file should be mirrored to
// rsuperellipse_blur.frag, which is based on this algorithm.

precision highp float;

#include <impeller/gaussian.glsl>
#include <impeller/math.glsl>
#include <impeller/rrect.glsl>
#include <impeller/types.glsl>

uniform FragInfo {
  vec4 color;
  vec4 center_adjust;
  vec3 r1_exponent_exponentInv;
  vec3 sInv_minEdge_scale;
}
frag_info;

in vec2 v_position;

out vec4 frag_color;

void main() {
  vec2 center = frag_info.center_adjust.xy;
  vec2 adjust = frag_info.center_adjust.zw;

  vec2 centered = abs(v_position - center);
  float d =
      computeRRectDistance(centered, adjust, frag_info.r1_exponent_exponentInv);
  float z = computeRRectFade(d, frag_info.sInv_minEdge_scale);

  frag_color = frag_info.color * float16_t(z);
}
