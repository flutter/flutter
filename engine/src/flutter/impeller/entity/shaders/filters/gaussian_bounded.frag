// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/color.glsl>
#include <impeller/constants.glsl>
#include <impeller/gaussian.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>

uniform f16sampler2D texture_sampler;

layout(constant_id = 0) const float supports_decal = 1.0;

uniform KernelSamples {
  float sample_count;

  // X, Y are uv offset and Z is Coefficient. W is padding.
  vec4 sample_data[50];
}
kernel_samples;

uniform FragInfo {
  mat4 quad_line_params;
}
frag_info;

bool OutOfBounds(vec2 coords) {
  vec4 signed_distances = frag_info.quad_line_params * vec4(coords, 1.0, 0.0);
  return any(lessThan(signed_distances, vec4(0.0)));
}

f16vec4 Sample(f16sampler2D tex, vec2 coords) {
  if (supports_decal == 1.0) {
    return texture(tex, coords);
  }
  return IPHalfSampleDecal(tex, coords);
}

f16vec4 BoundedSample(f16sampler2D tex, vec2 coords) {
  f16vec4 color = Sample(tex, coords);
  float16_t min_alpha = 1.0hf / 255.0hf;
  if (OutOfBounds(coords)) {
    color.a = min(color.a, min_alpha);
  }
  return color;
}

in vec2 v_texture_coords;

out f16vec4 frag_color;

void main() {
  f16vec4 total_color = f16vec4(0.0hf);
  int sample_count = int(kernel_samples.sample_count);

  int i = 0;
  for (; i < (sample_count - 1) &&
         OutOfBounds(v_texture_coords + kernel_samples.sample_data[i].xy);
       i++) {
  }

  // Starting edge compensation
  if (i > 0) {
    vec2 offset = (kernel_samples.sample_data[i].xy +
                   kernel_samples.sample_data[i - 1].xy) /
                  2.0;
    float16_t coefficient = kernel_samples.sample_data[i].z / 2.0;
    total_color +=
        coefficient * IPHalfPremultiply(BoundedSample(
                          texture_sampler, v_texture_coords + offset));
  }

  for (; i < sample_count &&
         !OutOfBounds(v_texture_coords + kernel_samples.sample_data[i].xy);
       i++) {
    float16_t coefficient = float16_t(kernel_samples.sample_data[i].z);
    total_color +=
        coefficient * IPHalfPremultiply(BoundedSample(
                          texture_sampler,
                          v_texture_coords + kernel_samples.sample_data[i].xy));
  }

  // Ending edge compensation
  if (i < sample_count) {
    vec2 offset = (kernel_samples.sample_data[i].xy +
                   kernel_samples.sample_data[i - 1].xy) /
                  2.0;
    float16_t coefficient = kernel_samples.sample_data[i].z / 2.0;
    total_color +=
        coefficient * IPHalfPremultiply(BoundedSample(
                          texture_sampler, v_texture_coords + offset));
  }

  frag_color = IPHalfUnpremultiplyOpaque(total_color);
}
