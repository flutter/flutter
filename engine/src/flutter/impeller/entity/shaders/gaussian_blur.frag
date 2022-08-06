// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// 1D (directional) gaussian blur.
//
// Paths for future optimization:
//   * Remove the uv bounds multiplier in SampleColor by adding optional
//     support for SamplerAddressMode::ClampToBorder in the texture sampler.
//   * Sample from higher mipmap levels when the blur radius is high enough.

#include <impeller/texture.glsl>

uniform sampler2D texture_sampler;
uniform sampler2D alpha_mask_sampler;

uniform FragInfo {
  vec2 texture_size;
  vec2 blur_direction;

  float blur_sigma;
  float blur_radius;
  float src_factor;
  float inner_blur_factor;
  float outer_blur_factor;
} frag_info;

in vec2 v_texture_coords;
in vec2 v_src_texture_coords;

out vec4 frag_color;

const float kSqrtTwoPi = 2.50662827463;

float Gaussian(float x) {
  float variance = frag_info.blur_sigma * frag_info.blur_sigma;
  return exp(-0.5 * x * x / variance) / (kSqrtTwoPi * frag_info.blur_sigma);
}

void main() {
  vec4 total_color = vec4(0);
  float gaussian_integral = 0;
  vec2 blur_uv_offset = frag_info.blur_direction / frag_info.texture_size;

  for (float i = -frag_info.blur_radius; i <= frag_info.blur_radius; i++) {
    float gaussian = Gaussian(i);
    gaussian_integral += gaussian;
    total_color +=
        gaussian * IPSampleClampToBorder(texture_sampler,
                                         v_texture_coords + blur_uv_offset * i);
  }

  vec4 blur_color = total_color / gaussian_integral;

  vec4 src_color =
      IPSampleClampToBorder(alpha_mask_sampler, v_src_texture_coords);
  float blur_factor = frag_info.inner_blur_factor * float(src_color.a > 0) +
                      frag_info.outer_blur_factor * float(src_color.a == 0);

  frag_color = blur_color * blur_factor + src_color * frag_info.src_factor;
}
