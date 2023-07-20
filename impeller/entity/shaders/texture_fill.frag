// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision mediump float;

#include <impeller/constants.glsl>
#include <impeller/types.glsl>

uniform f16sampler2D texture_sampler;

in highp vec2 v_texture_coords;
IMPELLER_MAYBE_FLAT in float16_t v_alpha;

out f16vec4 frag_color;

void main() {
  f16vec4 sampled =
      texture(texture_sampler, v_texture_coords, kDefaultMipBiasHalf);
  frag_color = sampled * v_alpha;
}
