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

float distanceFromCircle(float radius, vec2 center, vec2 point) {
  return distance(point, center) - radius;
}

float distanceFromStrokedCircle(float radius,
                                float stroke_width,
                                vec2 center,
                                vec2 point) {
  float half_stroke = stroke_width / 2.0;

  float inner_radius = radius - half_stroke;

  float outer_radius = radius + half_stroke;

  float outer_distance = distanceFromCircle(outer_radius, center, point);

  float inner_distance = -distanceFromCircle(inner_radius, center, point);

  return max(inner_distance, outer_distance);
}

void main() {
  float dist_filled =
      distanceFromCircle(frag_info.radius, frag_info.center, v_position);
  float dist_stroked = distanceFromStrokedCircle(
      frag_info.radius, frag_info.stroke_width, frag_info.center, v_position);
  float sdf_distance = mix(dist_filled, dist_stroked, frag_info.stroked);

  float pixel_derivative_sdf = fwidth(sdf_distance);

  // If the screen space derivative is less than the stroke width,
  // only one pixel can be covered and shouldn't be faded.
  if (frag_info.stroked > 0.0 &&
      pixel_derivative_sdf * 2.0 >= frag_info.stroke_width) {
    sdf_distance = -frag_info.radius;
  }

  float fade_width = pixel_derivative_sdf * frag_info.aa_pixels;
  // The sdf_distance will be -pixel_derivative_sdf*N exactly at N pixels away
  // from the edge of the circle
  float alpha = 1.0 - smoothstep(-fade_width, 0.0, sdf_distance);

  float finalAlpha = frag_info.color.w * alpha;

  frag_color = vec4(frag_info.color.xyz, finalAlpha);

  frag_color = IPPremultiply(frag_color);
}
