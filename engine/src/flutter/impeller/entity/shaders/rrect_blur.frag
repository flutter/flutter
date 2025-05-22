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
  vec2 center;
  vec2 adjust;
  float minEdge;
  float r1;
  float exponent;
  float sInv;
  float exponentInv;
  float scale;
}
frag_info;

in vec2 v_position;

out vec4 frag_color;

void main() {
  vec2 centered = abs(v_position - frag_info.center);
  float d = computeRRectDistance(centered, frag_info.adjust, frag_info.r1,
                                 frag_info.exponent, frag_info.exponentInv);
  float z =
      computeRRectFade(d, frag_info.sInv, frag_info.minEdge, frag_info.scale);

  frag_color = frag_info.color * float16_t(z);
}
