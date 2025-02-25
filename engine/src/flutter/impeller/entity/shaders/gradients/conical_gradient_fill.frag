// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision highp float;

#include <impeller/color.glsl>
#include <impeller/conical_gradient.glsl>
#include <impeller/gradient.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>

layout(constant_id = 0) const float kind = 3.0;

uniform sampler2D texture_sampler;

highp in vec2 v_position;

out vec4 frag_color;

void main() {
  vec2 res = IPComputeConicalT(kind, frag_info.focus, frag_info.focus_radius,
                               frag_info.center, frag_info.radius, v_position);
  frag_color = TextureConical(res, texture_sampler);
}
