// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// 1D (directional) gaussian blur.
//
// Paths for future optimization:
//   * Remove the uv bounds multiplier in SampleColor by adding optional
//     support for SamplerAddressMode::ClampToBorder in the texture sampler.
//   * Render both blur passes into a smaller texture than the source image
//     (~1/radius size).
//   * If doing the small texture render optimization, cache misses can be
//     reduced in the first pass by sampling the source textures with a mip
//     level of log2(min_radius).

#include <impeller/constants.glsl>
#include <impeller/gaussian.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>

uniform f16sampler2D texture_sampler;

uniform BlurInfo {
  f16vec2 blur_uv_offset;

  // The blur sigma and radius have a linear relationship which is defined
  // host-side, but both are useful controls here. Sigma (pixels per standard
  // deviation) is used to define the gaussian function itself, whereas the
  // radius is used to limit how much of the function is integrated.
  float blur_sigma;
  float16_t blur_radius;
}
blur_info;

f16vec4 Sample(f16sampler2D tex, vec2 coords) {
#if ENABLE_DECAL_SPECIALIZATION
  return IPHalfSampleDecal(tex, coords);
#else
  return texture(tex, coords);
#endif
}

in vec2 v_texture_coords;

out f16vec4 frag_color;

void main() {
  f16vec4 total_color = f16vec4(0.0hf);
  float16_t gaussian_integral = 0.0hf;

  // Step by 2.0 as a performance optimization, relying on bilinear filtering in
  // the sampler to blend the texels. Typically the space between pixels is
  // calculated so their blended amounts match the gaussian coefficients. This
  // just uses 0.5 as an optimization until the gaussian coefficients are
  // calculated and passed in from the cpu.
  for (float16_t i = -blur_info.blur_radius; i <= blur_info.blur_radius;
       i += 2.0hf) {
    // Use the 32 bit Gaussian function because the 16 bit variation results in
    // quality loss/visible banding. Also, 16 bit variation internally breaks
    // down at a moderately high (but still reasonable) blur sigma of >255 when
    // computing sigma^2 due to the exponent only having 5 bits.
    float16_t gaussian = float16_t(IPGaussian(float(i), blur_info.blur_sigma));
    gaussian_integral += gaussian;
    total_color +=
        gaussian * Sample(texture_sampler,  // sampler
                          v_texture_coords + blur_info.blur_uv_offset *
                                                 i  // texture coordinates
                   );
  }

  frag_color = total_color / gaussian_integral;
}
