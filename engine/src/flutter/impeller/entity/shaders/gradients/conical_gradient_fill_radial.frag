// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision highp float;

#include <impeller/color.glsl>
#include <impeller/conical_gradient_fill.glsl>
#include <impeller/gradient.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>

highp in vec2 v_position;

out vec4 frag_color;

void main() {
  vec2 res =
      IPComputeConicalTRadial(frag_info.focus, frag_info.focus_radius,
                              frag_info.center, frag_info.radius, v_position);
  frag_color = DoConicalGradientTextureFill(res);
}
