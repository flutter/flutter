// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/texture.glsl>
#include <impeller/types.glsl>

uniform sampler2D texture_sampler;

uniform FragInfo {
  float texture_sampler_y_coord_scale;
  float has_vertex_color;
  float alpha;
}
frag_info;

in vec2 v_texture_coords;
in vec4 v_color;

out vec4 frag_color;

void main() {
  vec4 sampled = IPSample(texture_sampler, v_texture_coords,
                          frag_info.texture_sampler_y_coord_scale);
  if (frag_info.has_vertex_color == 1.0) {
    frag_color = sampled.aaaa * v_color * frag_info.alpha;
  } else {
    frag_color = sampled * frag_info.alpha;
  }
}
