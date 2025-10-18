// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <impeller/constants.glsl>
#include <impeller/gaussian.glsl>
#include <impeller/texture.glsl>
#include <impeller/types.glsl>

uniform f16sampler2D texture_sampler;

layout(constant_id = 0) const float supports_decal = 1.0;
layout(constant_id = 1) const float bounded_blur = 0.0;

uniform KernelSamples {
  float sample_count;

  // X, Y are uv offset and Z is Coefficient. W is padding.
  vec4 sample_data[50];
}
kernel_samples;

uniform FragInfo {
  vec4 bounds_uv;
}
frag_info;

f16vec4 Sample(f16sampler2D tex, vec2 coords) {
  if (bounded_blur == 1.0) {
    return IPHalfSampleDecalBounded(tex, coords, frag_info.bounds_uv);
  }
  if (supports_decal == 1.0) {
    return texture(tex, coords);
  }
  return IPHalfSampleDecal(tex, coords);
}

in vec2 v_texture_coords;

out f16vec4 frag_color;

void main() {
  f16vec4 total_color = f16vec4(0.0hf);

  for (int i = 0; i < int(kernel_samples.sample_count); i++) {
    float16_t coefficient = float16_t(kernel_samples.sample_data[i].z);
    total_color += coefficient *
                   Sample(texture_sampler,
                          v_texture_coords + kernel_samples.sample_data[i].xy);
  }

  if (bounded_blur == 1.0) {
    frag_color =
        (total_color.w != 0.0) ? (total_color / total_color.w) : total_color;
  } else {
    frag_color = total_color;
  }
}
