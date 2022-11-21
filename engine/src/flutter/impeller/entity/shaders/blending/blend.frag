// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/texture.glsl>

uniform sampler2D texture_sampler_src;

uniform FragInfo {
  float texture_sampler_y_coord_scale;
  float input_alpha;
}
frag_info;

in vec2 v_texture_coords;

out vec4 frag_color;

void main() {
  frag_color = IPSample(texture_sampler_src, v_texture_coords,
                        frag_info.texture_sampler_y_coord_scale) *
               frag_info.input_alpha;
}
