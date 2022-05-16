// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "blending.glsl"

uniform sampler2D texture_sampler_dst;
uniform sampler2D texture_sampler_src;

in vec2 v_dst_texture_coords;
in vec2 v_src_texture_coords;

out vec4 frag_color;

vec3 ComponentIsValue(vec3 n, float value) {
  return vec3(n.r == value, n.g == value, n.b == value);
}

void main() {
  const vec4 dst = Unpremultiply(
      SampleWithBorder(texture_sampler_dst, v_dst_texture_coords));
  const vec4 src = Unpremultiply(
      SampleWithBorder(texture_sampler_src, v_src_texture_coords));

  vec3 color = 1 - min(vec3(1), (1 - dst.rgb) / src.rgb);
  color = mix(color, vec3(1), ComponentIsValue(dst.rgb, 1.0));
  color = mix(color, vec3(0), ComponentIsValue(src.rgb, 0.0));

  frag_color = vec4(color * src.a, src.a);
}
