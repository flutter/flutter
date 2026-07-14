// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision mediump float;

#include <impeller/color.glsl>
#include "sdf_utils.glsl"

in vec2 v_device_pos;

uniform FragInfo {
  vec4 color;
  float aa_pixels;
  float half_stroke_width;
  float num_segments;
  vec4 seg_points[64];
}
frag_info;

out vec4 frag_color;

float sdSegment(vec2 p, vec2 a, vec2 b) {
  vec2 pa = p - a;
  vec2 ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - ba * h);
}

float pixelSize(float sdf) {
  vec2 gradient = vec2(dFdx(sdf), dFdy(sdf));
  return length(gradient);
}

void main() {
  vec2 p = v_device_pos;
  float min_dist = 999999.0;
  int count = int(frag_info.num_segments);
  for (int i = 0; i < count; ++i) {
    vec2 a = frag_info.seg_points[i].xy;
    vec2 b = frag_info.seg_points[i].zw;
    float dist = sdSegment(p, a, b);
    min_dist = min(min_dist, dist);
  }
  float dist_to_edge = min_dist - frag_info.half_stroke_width;

  float pixel_size = pixelSize(dist_to_edge);
  float alpha = SDFAlpha(dist_to_edge, pixel_size, frag_info.aa_pixels);

  vec4 final_color = vec4(frag_info.color.rgb, frag_info.color.a * alpha);
  frag_color = IPPremultiply(final_color);
}
