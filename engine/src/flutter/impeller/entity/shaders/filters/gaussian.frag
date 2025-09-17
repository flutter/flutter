// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  float bounded;
  vec4 bounds_uv;
}
frag_info;

f16vec4 Sample(f16sampler2D tex, vec2 coords) {
  if (frag_info.bounded == 1.0) {
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
  vec4 bounds = frag_info.bounds_uv;

  for (int i = 0; i < int(kernel_samples.sample_count); i++) {
    vec2 coord = v_texture_coords + kernel_samples.sample_data[i].xy;
    float16_t coefficient = float16_t(kernel_samples.sample_data[i].z);

    total_color += Sample(texture_sampler, coord) * coefficient;
  }

  frag_color = (frag_info.bounded == 1.0 && total_color.w != 0)
                   ? (total_color / total_color.w)
                   : total_color;
}
