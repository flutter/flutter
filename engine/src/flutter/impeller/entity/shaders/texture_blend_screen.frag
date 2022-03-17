// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

uniform sampler2D texture_sampler_dst;
uniform sampler2D texture_sampler_src;

in vec2 v_texture_coords;

out vec4 frag_color;

void main() {
  vec4 dst = texture(texture_sampler_dst, v_texture_coords);
  vec4 src = texture(texture_sampler_src, v_texture_coords);
  frag_color = src + dst - src * dst;
}
