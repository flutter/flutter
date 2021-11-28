// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform sampler2D texture_sampler;

in vec2 v_texture_coords;
in float v_alpha;

out vec4 frag_color;

void main() {
  vec4 sampled = texture(texture_sampler, v_texture_coords);
  sampled.w *= v_alpha;
  frag_color = sampled;
}
