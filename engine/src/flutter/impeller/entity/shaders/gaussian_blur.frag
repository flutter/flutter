// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// 1D (directional) gaussian blur.
//
// Paths for future optimization:
//   * Remove the uv bounds multiplier in SampleColor by adding optional
//     support for SamplerAddressMode::ClampToBorder in the texture sampler.
//   * Sample from higher mipmap levels when the blur radius is high enough.

uniform sampler2D texture_sampler;
uniform sampler2D alpha_mask_sampler;

in vec2 v_texture_coords;
in vec2 v_src_texture_coords;
in vec2 v_texture_size;
in vec2 v_blur_direction;
in float v_blur_radius;
in float v_src_factor;
in float v_inner_blur_factor;
in float v_outer_blur_factor;

out vec4 frag_color;

const float kTwoPi = 6.283185307179586;

float Gaussian(float x) {
  float stddev = v_blur_radius * 0.5;
  float xnorm = x / stddev;
  return exp(-0.5 * xnorm * xnorm) / (kTwoPi * stddev * stddev);
}

// Emulate SamplerAddressMode::ClampToBorder.
vec4 SampleWithBorder(sampler2D tex, vec2 uv) {
  float within_bounds = float(uv.x >= 0 && uv.y >= 0 && uv.x < 1 && uv.y < 1);
  return texture(tex, uv) * within_bounds;
}

void main() {
  vec4 total = vec4(0);
  float total_gaussian = 0;
  vec2 blur_uv_offset = v_blur_direction / v_texture_size;
  for (float i = -v_blur_radius; i <= v_blur_radius; i++) {
    float gaussian = Gaussian(i);
    total_gaussian += gaussian;
    total += gaussian * SampleWithBorder(texture_sampler,
                                         v_texture_coords + blur_uv_offset * i);
  }

  vec4 blur_color = total / total_gaussian;

  vec4 src_color = SampleWithBorder(alpha_mask_sampler, v_src_texture_coords);
  float blur_factor = v_inner_blur_factor * float(src_color.a > 0) +
                      v_outer_blur_factor * float(src_color.a == 0);

  frag_color = blur_color * blur_factor + src_color * v_src_factor;
}
