// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

precision mediump float;

#include <impeller/color.glsl>
#include <impeller/types.glsl>

uniform FragInfo {
  vec4 color;
  vec2 center;
  float radius;
  float stroke_width;
  float aa_pixels;
  float stroked;
}
frag_info;

out vec4 frag_color;

highp in vec2 v_position;

float distanceFromCircle(float dist_to_center, float radius) {
  return dist_to_center - radius;
}

float distanceFromStrokedCircle(float dist_to_center,
                                float radius,
                                float half_stroke_width) {
  float outer_radius = radius + half_stroke_width;
  float inner_radius = radius - half_stroke_width;

  float outer_distance = distanceFromCircle(dist_to_center, outer_radius);
  float inner_distance = distanceFromCircle(dist_to_center, inner_radius);

  return max(-inner_distance, outer_distance);
}

void main() {
  vec2 vec_to_center = v_position - frag_info.center;
  float dist_to_center = length(vec_to_center);
  vec2 unitvec_towards_center =
      dist_to_center > 0.0 ? vec_to_center / dist_to_center : vec2(1.0, 0.0);

  float local_dx = length(dFdx(v_position));
  float local_dy = length(dFdy(v_position));
  float local_dist_towards_center =
      dot(vec2(local_dx, local_dy), abs(unitvec_towards_center));

  float adjusted_stroke_width =
      max(frag_info.stroke_width, local_dist_towards_center);

  float dist_filled = distanceFromCircle(dist_to_center, frag_info.radius);
  float dist_stroked = distanceFromStrokedCircle(
      dist_to_center, frag_info.radius, adjusted_stroke_width * 0.5f);

  float sdf_distance = mix(dist_filled, dist_stroked, frag_info.stroked);

  float fade_size = local_dist_towards_center * frag_info.aa_pixels * 0.5;
  // The sdf_distance will be -pixel_derivative_sdf*N exactly at N pixels away
  // from the edge of the circle
  float alpha = 1.0 - smoothstep(-fade_size, fade_size, sdf_distance);

  frag_color = frag_info.color * alpha;
}
