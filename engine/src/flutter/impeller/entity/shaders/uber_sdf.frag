// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision mediump float;

#include <impeller/color.glsl>
#include <impeller/types.glsl>

uniform FragInfo {
  vec4 color;
  vec2 center;
  vec2 size;
  float stroke_width;
  float aa_pixels;
  float stroked;
  float type;
}
frag_info;

out vec4 frag_color;

highp in vec2 v_position;

float distanceFromCircle(vec2 p, float radius) {
  return length(p) - radius;
}

float distanceFromRect(vec2 p, vec2 b) {
  // TODO(gaaclarke): This is may need to be improved for corners. This is just
  // the simplest thing while we get the plumbing in place.
  vec2 d = abs(p) - b;
  return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

void main() {
  vec2 p = v_position - frag_info.center;

  float dist;
  if (frag_info.type < 0.5) {
    dist = distanceFromCircle(p, frag_info.size.x);
  } else {
    dist = distanceFromRect(p, frag_info.size);
  }

  float half_stroke = max(frag_info.stroke_width, 0.0) * 0.5;
  float sdf_distance = mix(dist, abs(dist) - half_stroke, frag_info.stroked);

  // Anti-aliasing
  // fwidth(sdf_distance) gives the change in SDF per pixel.
  float fade_size = fwidth(sdf_distance) * frag_info.aa_pixels * 0.5;

  float alpha = 1.0 - smoothstep(-fade_size, fade_size, sdf_distance);

  frag_color = vec4(frag_info.color.rgb, frag_info.color.a * alpha);
  frag_color = IPPremultiply(frag_color);
}
