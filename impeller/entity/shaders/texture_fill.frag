// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/types.glsl>

uniform sampler2D texture_sampler;

uniform FragInfo {
  float alpha;
}
frag_info;

in vec2 v_texture_coords;

out vec4 frag_color;

void main() {
  vec4 sampled = texture(texture_sampler, v_texture_coords);
  frag_color = sampled * frag_info.alpha;
}
