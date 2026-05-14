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

  // If a point lies inside of the hole of the stroked circle, the
  // inner_distance will be negative. -inner_distance is then a value that's
  // positive inside of the hole, zero at the inner boundary, and negative
  // elsewhere. outer_distance is a value that's negative inside the the outer
  // radius of the circle, zero at the outer boundary, and positive elsewhere.
  // If a point lies:
  //  - inside the hole -> max(-inner_distance, outer_distance) > 0
  //  - outside the outer radius -> max(-inner_distance, outer_distance) > 0
  //  - on the stroke boundary -> max(-inner_distance, outer_distance) = 0
  //  - inside of the stroke -> max(-inner_distance, outer_distance) < 0. With
  //  the value minimal at the radius, and approaching zero at the boundaries
  return max(-inner_distance, outer_distance);
}

void main() {
  // We need to make sure that for stroked circles we have a cross section
  // that is at least as wide as a pixel. The cross section is measured towards
  // the center of the circle which is the same direction in both local and
  // screen coordinates for uniformly scaled transforms and only slightly off
  // for skewed transforms.
  vec2 vec_to_center = v_position - frag_info.center;
  float dist_to_center = length(vec_to_center);
  vec2 unitvec_towards_center =
      dist_to_center > 0.0 ? vec_to_center / dist_to_center : vec2(1.0, 0.0);

  // Get the width and height of a pixel in v_position units.
  // This gives us a basis in local space coordinates to work in for calculating
  // the SDF.
  float local_dx = length(dFdx(v_position));
  float local_dy = length(dFdy(v_position));

  // Get the length of the vector towards the center of the circle measured in
  // local coordinates.
  float local_dist_towards_center =
      dot(vec2(local_dx, local_dy), abs(unitvec_towards_center));

  float adjusted_stroke_width =
      max(frag_info.stroke_width, local_dist_towards_center);

  float dist_filled = distanceFromCircle(dist_to_center, frag_info.radius);
  float dist_stroked = distanceFromStrokedCircle(
      dist_to_center, frag_info.radius, adjusted_stroke_width * 0.5f);

  float sdf_distance = mix(dist_filled, dist_stroked, frag_info.stroked);

  // Calculate the size of the anti-aliasing fade region in SDF units.
  // This should correspond to roughly half a pixel's width on screen, scaled by
  // the aa_pixels factor.
  float fade_size = local_dist_towards_center * frag_info.aa_pixels * 0.5;

  float alpha = 1.0 - smoothstep(-fade_size, fade_size, sdf_distance);

  float finalAlpha = frag_info.color.a * alpha;

  frag_color = vec4(frag_info.color.rgb, finalAlpha);

  frag_color = IPPremultiply(frag_color);
}
