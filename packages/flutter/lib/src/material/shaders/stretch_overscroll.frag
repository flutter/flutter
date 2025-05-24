#version 320 es
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform sampler2D u_texture;

// multiplier to apply to scale effect.
uniform float u_max_stretch_intensity;

// Normalized overscroll amount in the horizontal direction
uniform float u_overscroll_x;

// Normalized overscroll amount in the vertical direction
uniform float u_overscroll_y;

// u_interpolation_strength is the intensity of the interpolation.
uniform float u_interpolation_strength;

float ease_in(float t, float d) {
  return t * d;
}

float compute_overscroll_start(
  float in_pos,
  float overscroll,
  float u_stretch_affected_dist,
  float u_inverse_stretch_affected_dist,
  float distance_stretched,
  float interpolation_strength
) {
  float offset_pos = u_stretch_affected_dist - in_pos;
  float pos_based_variation = mix(
    1.0,
    ease_in(offset_pos, u_inverse_stretch_affected_dist),
    interpolation_strength
  );
  float stretch_intensity = overscroll * pos_based_variation;
  return distance_stretched - (offset_pos / (1.0 + stretch_intensity));
}

float compute_overscroll_end(
  float in_pos,
  float overscroll,
  float reverse_stretch_dist,
  float u_stretch_affected_dist,
  float u_inverse_stretch_affected_dist,
  float distance_stretched,
  float interpolation_strength,
  float viewport_dimension
) {
  float offset_pos = in_pos - reverse_stretch_dist;
  float pos_based_variation = mix(
    1.0,
    ease_in(offset_pos, u_inverse_stretch_affected_dist),
    interpolation_strength
  );
  float stretch_intensity = (-overscroll) * pos_based_variation;
  return viewport_dimension - (distance_stretched - (offset_pos / (1.0 + stretch_intensity)));
}

float compute_overscroll(
  float in_pos,
  float overscroll,
  float u_stretch_affected_dist,
  float u_inverse_stretch_affected_dist,
  float distance_stretched,
  float distance_diff,
  float interpolation_strength,
  float viewport_dimension
) {
  if (overscroll > 0.0) {
    if (in_pos <= u_stretch_affected_dist) {
      return compute_overscroll_start(
        in_pos, overscroll, u_stretch_affected_dist,
        u_inverse_stretch_affected_dist, distance_stretched,
        interpolation_strength
      );
    } else {
      return distance_diff + in_pos;
    }
  } else if (overscroll < 0.0) {
    float stretch_affected_dist_calc = viewport_dimension - u_stretch_affected_dist;
    if (in_pos >= stretch_affected_dist_calc) {
      return compute_overscroll_end(
        in_pos,
        overscroll,
        stretch_affected_dist_calc,
        u_stretch_affected_dist,
        u_inverse_stretch_affected_dist,
        distance_stretched,
        interpolation_strength,
        viewport_dimension
      );
    } else {
      return -distance_diff + in_pos;
    }
  } else {
    return in_pos;
  }
}

out vec4 frag_color;

void main() {
  vec2 coord = FlutterFragCoord().xy / u_size;
  float in_u_norm = coord.x;
  float in_v_norm = coord.y;

  float out_u_norm;
  float out_v_norm;

  float norm_stretch_affected_dist_x = 1.0;
  float norm_stretch_affected_dist_y = 1.0;

  float norm_inverse_stretch_affected_dist_x = 1.0;
  float norm_inverse_stretch_affected_dist_y = 1.0;

  float norm_distance_stretched_x = 1.0 / (1.0 + abs(u_overscroll_x));
  float norm_distance_stretched_y = 1.0 / (1.0 + abs(u_overscroll_y));

  float norm_dist_diff_x = norm_distance_stretched_x - 1.0;
  float norm_dist_diff_y = norm_distance_stretched_y - 1.0;

  float norm_viewport_width = 1.0;
  float norm_viewport_height = 1.0;

  float current_u_scroll_x = 0.0;
  float current_u_scroll_y = 0.0;

  in_u_norm += current_u_scroll_x;
  in_v_norm += current_u_scroll_y;

  out_u_norm = compute_overscroll(
    in_u_norm,
    u_overscroll_x,
    norm_stretch_affected_dist_x,
    norm_inverse_stretch_affected_dist_x,
    norm_distance_stretched_x,
    norm_dist_diff_x,
    u_interpolation_strength,
    norm_viewport_width
  );

  out_v_norm = compute_overscroll(
    in_v_norm,
    u_overscroll_y,
    norm_stretch_affected_dist_y,
    norm_inverse_stretch_affected_dist_y,
    norm_distance_stretched_y,
    norm_dist_diff_y,
    u_interpolation_strength,
    norm_viewport_height
  );

  coord.x = out_u_norm;
  coord.y = out_v_norm;

  frag_color = texture(u_texture, coord);
}